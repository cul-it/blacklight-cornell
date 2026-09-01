# frozen_string_literal: true

# The URL an AI assistant connects to. Read-only.
#
# Everything happens on one POST: the AI sends a request, we answer it.
# That's all the tools here need, since each one just reads and replies.
#
# It inherits from ActionController::API, not ApplicationController, on purpose:
# no session, no CSRF token, no bookbag, no views. There's nothing here for a
# request to change.
class McpController < ActionController::API
  # Rails normally copies JSON parameters under the controller's name, which
  # logs every request twice. This controller reads the raw body and never uses
  # params, so that copy is only noise.
  wrap_parameters false

  # Plenty for a normal request, small enough that nobody can push huge bodies
  # at the app.
  MAX_BODY_BYTES = 256 * 1024

  # Limits on the log summary, so one enormous argument can't flood the log.
  MAX_LOGGED_ARGUMENTS = 400
  MAX_LOGGED_LINES = 40
  MAX_LOGGED_LINE_LENGTH = 200

  # Indent for argument lines in the development log.
  ARGUMENT_INDENT = '  '

  PARSE_ERROR = -32_700
  INVALID_REQUEST = -32_600
  METHOD_NOT_FOUND = -32_601

  # POST /mcp
  def handle
    body = request.body.read.to_s

    return render_error(INVALID_REQUEST, "Request body exceeds #{MAX_BODY_BYTES} bytes") if body.bytesize > MAX_BODY_BYTES
    return render_error(PARSE_ERROR, 'Invalid JSON') if body.blank?

    begin
      payload = JSON.parse(body)
    rescue JSON::ParserError
      return render_error(PARSE_ERROR, 'Invalid JSON')
    end

    log_summary(payload)

    rejected = rejected_methods(payload)
    if rejected.any?
      return render_error(METHOD_NOT_FOUND,
                          "This server is read-only and does not support: #{rejected.uniq.join(', ')}",
                          id: request_id(payload))
    end

    response_json = BlacklightMcp::Server.build(base_url: request.base_url).handle_json(body)

    # A notification has no id and gets no reply.
    return head :accepted if response_json.nil?

    render json: response_json
  end

  # GET /mcp, when a client asks for the live update stream.
  #
  # Assistants open this once per connection, to listen for messages we might
  # push them. We never push any -- every tool answers on the POST instead -- so
  # we decline with 405. That is what the client expects, and what makes it fall
  # back to POST. Anything else, like a 200 with some JSON, looks to it like the
  # stream opened; it then fails on the reply and reconnects over and over,
  # hitting the app several times a second.
  #
  # A few of these when an assistant starts up are normal.
  def event_stream
    response.headers['Allow'] = 'POST'
    render json: {
      jsonrpc: '2.0',
      id: nil,
      error: { code: INVALID_REQUEST,
               message: 'Method not allowed: this server does not offer a server-to-client ' \
                        'event stream. Send requests as JSON-RPC over POST.' }
    }, status: :method_not_allowed
  end

  # GET /mcp, from a browser or a misconfigured client. A short description of
  # the endpoint instead of an error page.
  def info
    render json: {
      name: BlacklightMcp::Server::NAME,
      version: BlacklightMcp::VERSION,
      transport: 'JSON-RPC 2.0 over HTTP POST to this URL',
      read_only: true,
      tools: BlacklightMcp::Server.tools.map(&:name_value),
      methods: BlacklightMcp::Server::ALLOWED_METHODS
    }
  end

  private

  # A readable summary of each request, so you can see a tool call at a glance
  # instead of picking it out of the raw `Parameters:` line Rails logs.
  # DevelopmentLogFormatter marks anything starting with [MCP] and hides that raw
  # line in favor of this one.
  #
  # In development the arguments go one per line and line up. Everywhere else
  # they stay on one line, which is what log tools expect.
  def log_summary(payload)
    each_request_object(payload) do |request_object|
      Rails.logger.info("[MCP] #{summarize(request_object).join("\n")}")
    end
  end

  # @return [Array<String>] one entry per line
  def summarize(request_object)
    method = request_object['method'].to_s.presence || '(no method)'
    params = request_object['params'].is_a?(Hash) ? request_object['params'] : {}
    id = request_object['id']

    header = +''
    header << "##{id} " if id
    header << method
    arguments = nil

    case method
    when 'tools/call'
      header << " #{params['name']}"
      arguments = params['arguments'] if params['arguments'].is_a?(Hash)
    when 'initialize'
      client = params['clientInfo'].is_a?(Hash) ? params['clientInfo'] : {}
      header << " <- #{client['name']} #{client['version']}".rstrip
    end

    return [header] if arguments.blank?
    return ["#{header} #{compact_arguments(arguments)}"] unless expanded_logging?

    truncate([header, *argument_lines(arguments)])
  end

  # Multi-line summaries are a development nicety. Elsewhere, one request stays
  # one log line.
  def expanded_logging?
    Rails.env.development?
  end

  def compact_arguments(arguments)
    json = arguments.to_json
    json.length > MAX_LOGGED_ARGUMENTS ? "#{json[0, MAX_LOGGED_ARGUMENTS]}…" : json
  end

  # Writes arguments as lined-up `label: value` rows. It knows nothing about any
  # particular tool, so it can't fall out of step when a tool changes.
  def argument_lines(arguments)
    width = arguments.keys.map { |key| key.to_s.length }.max.to_i + 1

    arguments.flat_map do |key, value|
      first, *rest = render_value(value)
      label = "#{key}:".ljust(width)
      continuation = ' ' * width

      ["#{ARGUMENT_INDENT}#{label} #{first}",
       *rest.map { |line| "#{ARGUMENT_INDENT}#{continuation} #{line}" }]
    end
  end

  # @return [Array<String>] one entry per line the value needs
  def render_value(value)
    case value
    when Array
      # A list of items with their own fields (advanced search rows) reads much
      # better one per line. A plain list (formats, languages) fits on one.
      if value.any? && value.all? { |element| element.is_a?(Hash) }
        value.each_with_index.map { |element, index| "[#{index + 1}] #{inline_hash(element)}" }
      else
        [value.map { |element| element.to_s }.join(', ')]
      end
    when Hash
      [inline_hash(value)]
    else
      [value.to_s]
    end
  end

  def inline_hash(hash)
    hash.map { |key, value| "#{key}=#{quoted(value)}" }.join('  ')
  end

  # Add quotes only where the value would otherwise be hard to read.
  def quoted(value)
    text = value.to_s
    text.empty? || text.match?(/\s/) ? text.inspect : text
  end

  def truncate(lines)
    lines = lines.map { |line| line.length > MAX_LOGGED_LINE_LENGTH ? "#{line[0, MAX_LOGGED_LINE_LENGTH]}…" : line }
    return lines if lines.length <= MAX_LOGGED_LINES

    lines.first(MAX_LOGGED_LINES) << "#{ARGUMENT_INDENT}… #{lines.length - MAX_LOGGED_LINES} more line(s)"
  end

  # A request can be a single item or a list of them.
  def each_request_object(payload, &block)
    Array.wrap(payload.is_a?(Array) ? payload : [payload]).each do |request_object|
      block.call(request_object) if request_object.is_a?(Hash)
    end
  end

  def rejected_methods(payload)
    [].tap do |rejected|
      each_request_object(payload) do |request_object|
        name = request_object['method']
        rejected << name.to_s if name.present? && !BlacklightMcp::Server.allowed_method?(name)
      end
    end
  end

  def request_id(payload)
    payload.is_a?(Hash) ? payload['id'] : nil
  end

  def render_error(code, message, id: nil)
    render json: { jsonrpc: '2.0', id: id, error: { code: code, message: message } }
  end
end
