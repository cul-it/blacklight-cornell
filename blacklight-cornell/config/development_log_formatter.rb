# frozen_string_literal: true

require_relative "solr_query_pretty_printer"

# Adds useful ANSI colors to Rails' compact development log output. Rails'
# config.colorize_logging only colors messages created by color-aware logging
# ordinary request/controller/view messages otherwise remain monochrome.
class DevelopmentLogFormatter < ActiveSupport::Logger::SimpleFormatter
  RESET = "\e[0m"
  COLORS = {
    debug: "\e[38;5;244m", # Mid-Grey
    info: "\e[38;5;96m",   # faint magenta
    warn: "\e[33m",        # yellow
    error: "\e[31m",       # red
    miss: "\e[2;31m",      # faint red
    fatal: "\e[1;31m",     # bold red
    bold_blue: "\e[1;34m", # bold blue
    blue: "\e[34m",        # blue
    cyan: "\e[36m",        # magenta
    green: "\e[32m",       # green
    yellow: "\e[33m",      # yellow
    magenta: "\e[35m",     # magenta
    bold_green_cyan_bg: "\e[1;32;46m", # bold green, cyan background
    bold_light_green: "\e[1;92m",
    white_on_bright_red: "\e[1;97;101m",
    white_on_dark_green: "\e[37;42m", # regular white on dark green
    mcp: "\e[95m",          # bright magenta — MCP request lifecycle
    unknown: "\e[35m"      # magenta
  }.freeze

  # MCP traffic gets a badge in the gutter
  MCP_BADGE = "\e[1;97;105m MCP \e[0m " # bright white on bright magenta
  MCP_BADGE_PLAIN = "[MCP] "
  # 'Started POST "/mcp"', but not '/mcpanything'.
  MCP_STARTED = %r{\AStarted [A-Z]+ "/mcp(?:[/?"]|\z)}
  MCP_PROCESSING = /\AProcessing by McpController#/
  # Lines McpController logs itself, e.g. '[MCP] tools/call search {...}'.
  MCP_TAGGED = /\A\[MCP\]/

  # Set on the request's own thread by the 'Started' line and read by every line
  # after it, so 'Completed 200 OK' is badged too -- that line carries nothing
  # identifying the path it belongs to.
  MCP_FLAG = :development_log_formatter_mcp_request

  # Only lines *about* the MCP exchange take the MCP hue. Everything else inside
  # the request -- Solr queries, renders, etc keep it's default colors
  MCP_LIFECYCLE = Regexp.union(
    MCP_STARTED,     # Started POST "/mcp" ...
    MCP_PROCESSING,  # Processing by McpController#handle
    MCP_TAGGED,      # [MCP] tools/call search {...}
    /\AParameters:/  # the JSON-RPC envelope
  ).freeze

  # Rails logs the raw JSON-RPC envelope as one very long `Parameters:` line.
  # McpController re-logs the same content immediately after, broken out and
  # aligned, so in development the raw line is pure duplication
  MCP_RAW_PARAMETERS = /\AParameters: \{"jsonrpc"/

  # Solr query lines are a single very long hash. Set FORMAT_SOLR_QUERY=true to
  # break them out one parameter per line. Off by default.
  SOLR_QUERY = /\ASolr query: /

  def call(severity, timestamp, progname, message)
    body = super.sub(/\n+\z/, "")
    mcp = mcp_request?(body)

    return "" if mcp && body.lstrip.match?(MCP_RAW_PARAMETERS)

    body = expand_solr_query(body)
    plain = ENV["NO_COLOR"].present? || body.include?("\e[")
    color = plain ? nil : color_for(severity, body, mcp)

    body.split("\n", -1).map { |line| decorate(line, mcp, color) }.join
  end

  private

  # Falls back to the original line whenever the pretty printer doesnt work
  def expand_solr_query(body)
    return body unless format_solr_query? && body.lstrip.match?(SOLR_QUERY)

    SolrQueryPrettyPrinter.call(body)&.join("\n") || body
  end

  def format_solr_query?
    %w[true 1 yes on].include?(ENV["FORMAT_SOLR_QUERY"].to_s.strip.downcase)
  end

  def decorate(line, mcp, color)
    return "#{badge(mcp, line)}#{line}\n" if color.nil?

    "#{badge(mcp, line)}#{color}#{line}#{RESET}\n"
  end

  def badge(mcp, line)
    return "" unless mcp
    return "" if ENV["NO_COLOR"].present? && line.lstrip.start_with?(MCP_BADGE_PLAIN)

    ENV["NO_COLOR"].present? ? MCP_BADGE_PLAIN : MCP_BADGE
  end

  # Tracks whether the line belongs to an MCP request.
  def mcp_request?(line)
    message = line.lstrip

    if message.start_with?("Started ")
      # Re-decided on every request, so a thread reused after an aborted MCP request cannot inherit a stale badge.
      Thread.current[MCP_FLAG] = message.match?(MCP_STARTED)
    elsif message.match?(MCP_PROCESSING) || message.match?(MCP_TAGGED)
      Thread.current[MCP_FLAG] = true
    end

    mcp = Thread.current[MCP_FLAG] ? true : false
    Thread.current[MCP_FLAG] = false if message.start_with?("Completed ")
    mcp
  end

  # Colorize whole log lines by the Rails event they represent
  def color_for(severity, line, mcp = false)
    message = line.lstrip

    return COLORS[:mcp] if mcp && message.match?(MCP_LIFECYCLE)

    case message
    when /\AStarted /
      COLORS[:bold_blue] # Request begins: 'Started GET "/path" for 127.0.0.1 at …'
    when /\AProcessing by/, /\AParameters:/
      COLORS[:cyan] # Dispatch + params: 'Processing by Controller#show as HTML' / 'Parameters: {…}'
    when /\ACompleted 2/
      COLORS[:green] # 2xx — success (200 OK, 201 Created, 204 No Content, 206 Partial Content)
    when /\ACompleted 3/
      COLORS[:cyan] # 3xx — redirect / not modified (301, 302, 303, 304, 307, 308)
    when /\ACompleted 4/
      COLORS[:yellow] # 4xx — client error (400 Bad Request, 401, 403, 404, 422 Unprocessable, 429 …)
    when /\ACompleted 5/
      COLORS[:fatal] # 5xx — server error (500 Internal Server Error, 502, 503, 504 …)
    when /\ARendered \/usr\/local/ # Gem View Renders (Blacklight Views)
      COLORS[:info]
    when /\ARendering /, /\ARendered /
      COLORS[:magenta]  # View work: 'Rendering view.html.erb' / 'Rendered view/_partial (Duration: …)'
    else
      COLORS.fetch(severity.to_s.downcase.to_sym, COLORS[:magenta]) # Not a recognized request-lifecycle line — color by log severity (debug/info/warn/…)
    end
  end
end
