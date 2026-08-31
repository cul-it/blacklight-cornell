# frozen_string_literal: true

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
    fatal: "\e[1;31m",     # bold red
    bold_blue: "\e[1;34m", # bold blue
    cyan: "\e[36m",        # magenta
    green: "\e[32m",       # green
    yellow: "\e[33m",      # yellow
    unknown: "\e[35m"      # magenta
  }.freeze

  def call(severity, timestamp, progname, message)
    line = super
    return line if ENV["NO_COLOR"].present? || line.include?("\e[")

    "#{color_for(severity, line)}#{line.sub(/\n+\z/, "")}#{RESET}\n"
  end

  private

  # Colorize whole log lines by the Rails event they represent
  def color_for(severity, line)
    message = line.lstrip

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
    when /\ARendering /, /\ARendered /
      COLORS[:info]  # View work: 'Rendering view.html.erb' / 'Rendered view/_partial (Duration: …)'
    else
      COLORS.fetch(severity.to_s.downcase.to_sym, COLORS[:unknown]) # Not a recognized request-lifecycle line — color by log severity (debug/info/warn/…)
    end
  end
end
