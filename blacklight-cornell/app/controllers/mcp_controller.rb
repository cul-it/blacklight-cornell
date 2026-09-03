# frozen_string_literal: true

# The URL an AI assistant connects to. Read-only.
#
# Modern clients send self-contained POSTs. Clients such as Claude that still
# speak MCP 2025-11-25 use the initialize workflow on the same URL. That path is
# stateless too: it negotiates the protocol but does not create a server session.
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

  # JSON-RPC keeps -32000 to -32099 for a server's own errors.
  RATE_LIMITED = -32_000

  PARSE_ERROR = -32_700
  INVALID_REQUEST = -32_600
  METHOD_NOT_FOUND = -32_601

  # Anyone who finds this URL can search without logging in, so cap how fast one
  # caller can go. Counts GET as well as POST, since connecting uses both.
  # See BlacklightMcp::RateLimit to tune it or turn it off.
  rate_limit to: BlacklightMcp::RateLimit.requests,
             within: BlacklightMcp::RateLimit.period,
             store: BlacklightMcp::RateLimit.store,
             with: -> { too_many_requests },
             if: -> { BlacklightMcp::RateLimit.enabled? }

  # GET or POST /mcp
  def handle
    # A legacy client may probe for the optional server-to-client SSE stream.
    # The stateless SDK transport answers that GET with a clean 405.
    return render_transport_response if request.get?

    body = request.body.read.to_s

    if body.bytesize > MAX_BODY_BYTES
      return render_error(INVALID_REQUEST, "Request body exceeds #{MAX_BODY_BYTES} bytes", status: :payload_too_large)
    end
    return render_error(PARSE_ERROR, 'Invalid JSON', status: :bad_request) if body.blank?

    begin
      payload = JSON.parse(body)
    rescue JSON::ParserError
      return render_error(PARSE_ERROR, 'Invalid JSON', status: :bad_request)
    end

    unless payload.is_a?(Hash)
      return render_error(INVALID_REQUEST, 'Request body must be one JSON-RPC request object', status: :bad_request)
    end

    log_summary(payload)

    rejected = rejected_methods(payload)
    if rejected.any?
      return render_error(METHOD_NOT_FOUND,
                          "This server is read-only and does not support: #{rejected.uniq.join(', ')}",
                          id: request_id(payload), status: :not_found)
    end

    request.body.rewind
    render_transport_response
  ensure
    @transport&.close
  end

  private

  # Answered as JSON-RPC rather than an error page, so the AI assistant can read
  # what happened and tell the person why the search did not run.
  def too_many_requests
    retry_after = BlacklightMcp::RateLimit.period.to_i
    response.headers['Retry-After'] = retry_after.to_s

    render json: {
      jsonrpc: '2.0',
      id: nil,
      error: { code: RATE_LIMITED,
               message: "Too many requests. This endpoint allows " \
                        "#{BlacklightMcp::RateLimit.requests} requests every #{retry_after} seconds. " \
                        "Wait #{retry_after} seconds and try again." }
    }, status: :too_many_requests
  end

  def render_transport_response
    status, headers, response_body = transport.handle_request(request)
    headers.each { |name, value| response.set_header(name, value) }
    self.status = status
    self.response_body = response_body
  end

  # The SDK transport owns protocol negotiation, header/envelope validation and
  # HTTP status mapping. Stateless mode lets legacy clients initialize without
  # retaining a session and lets modern clients use self-contained requests.
  def transport
    @transport ||= MCP::Server::Transports::StreamableHTTPTransport.new(
      BlacklightMcp::Server.build(base_url: request.base_url),
      stateless: true,
      serve_subscriptions_listen: false,
      max_request_bytes: MAX_BODY_BYTES,
      allowed_hosts: allowed_hosts
    )
  end

  # The SDK always permits loopback hosts. Deployed catalog hosts live under
  # Cornell Library's controlled DNS zone; tests use Rails' example host.
  def allowed_hosts
    host = request.host.to_s.downcase
    return [host] if Rails.env.test? || host.end_with?('.library.cornell.edu')

    []
  end

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

  def render_error(code, message, id: nil, data: nil, status: :bad_request)
    error = { code: code, message: message }
    error[:data] = data if data
    render json: { jsonrpc: '2.0', id: id, error: error }, status: status
  end
end
