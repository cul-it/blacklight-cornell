# frozen_string_literal: true

module BlacklightMcp
  # What a person sees when they paste the MCP URL into a browser.
  #
  # The endpoint speaks JSON-RPC over POST, so a browser -- which can only GET
  # -- gets a protocol error that looks like a broken site. It isn't broken, but
  # nobody can tell that from `"Method not allowed"`. This page says what the URL
  # is for and how to connect to it.
  #
  # MCP clients never see this. They ask for `text/event-stream` and keep the
  # 405 the protocol calls for.
  #
  # The tool list is generated from Server.tools, so the page cannot fall out of
  # step with what the endpoint actually offers.
  module LandingPage
    module_function

    def html(url:)
      <<~HTML
        <!DOCTYPE html>
        <html lang="en">
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <meta name="robots" content="noindex">
        <title>Cornell University Library Catalog &mdash; MCP</title>
        #{stylesheet}
        </head>
        <body class="mcp-landing">
        <main class="container py-5 mcp-page">
          <p class="mcp-eyebrow text-danger text-uppercase fw-semibold small mb-1">Cornell University Library</p>
          <h1 class="h2 fw-semibold mb-3">Catalog MCP endpoint</h1>
          <p class="lead text-body-secondary mb-4">Connect the library catalog to your AI assistant of
             choice. Read-only, and no account or key required.</p>

          <div class="card bg-body-tertiary mb-4">
            <div class="card-body py-3 d-flex flex-wrap justify-content-between align-items-baseline gap-2">
              <span class="font-monospace text-break">#{escape(url)}</span>
              <span class="badge text-bg-secondary">v#{escape(BlacklightMcp::VERSION)}</span>
            </div>
          </div>

          <h2 class="mcp-section h6 text-uppercase text-body-secondary fw-semibold mt-5 mb-3">Connecting</h2>
          <div class="list-group mb-4">
            <div class="list-group-item py-3">
              <p class="fw-semibold mb-2"><i class="fa fa-terminal text-body-secondary me-2" aria-hidden="true"></i>Claude Code</p>
              <code class="mcp-command bg-body-tertiary border rounded px-2 py-1">claude mcp add --transport http cornell-library-catalog #{escape(url)}</code>
            </div>
            <div class="list-group-item py-3">
              <p class="fw-semibold mb-2"><i class="fa fa-plug text-body-secondary me-2" aria-hidden="true"></i>Claude Desktop or claude.ai</p>
              <p class="text-body-secondary mb-0">Settings &rarr; Connectors &rarr; Add custom connector, then paste the URL above.</p>
            </div>
            <div class="list-group-item py-3">
              <p class="fw-semibold mb-2"><i class="fa fa-globe text-body-secondary me-2" aria-hidden="true"></i>Anything else</p>
              <p class="text-body-secondary mb-0">Add it as a remote MCP server over &ldquo;streamable HTTP&rdquo; using the URL above.</p>
            </div>
          </div>

          <h2 class="mcp-section h6 text-uppercase text-body-secondary fw-semibold mt-5 mb-3">What your assistant can do with it</h2>
          <ul class="list-group list-group-flush mb-4">#{tool_items}
          </ul>
          #{reconnect_note}
          #{console_section}
          <p class="small text-body-secondary border-top pt-3 mt-5 mb-0">
             <i class="fa fa-info-circle me-1" aria-hidden="true"></i>This URL speaks the
             <a href="https://modelcontextprotocol.io">Model Context Protocol</a> over POST, so there
             is nothing to browse here. To search the catalog yourself, use
             <a href="/">the catalog</a>.</p>
        </main>
        </body>
        </html>
      HTML
    end

    # An assistant reads the tool list once, when it connects, and keeps it for
    # the life of that connection. So this page can list a tool the assistant
    # in front of you has never heard of, and the fix is always the same:
    # connect again. Said here because this is where someone looks when their
    # assistant cannot find a tool the library has announced.
    def reconnect_note
      <<-HTML
          <div class="alert alert-secondary small d-flex gap-2" role="note">
            <i class="fa fa-refresh mt-1" aria-hidden="true"></i>
            <div>
              <span class="fw-semibold">Missing a tool from this list?</span>
              Your assistant only checks what this endpoint offers when it first connects, so
              disconnect it and connect again to pick up anything new.
            </div>
          </div>
      HTML
    end

    # McpController is an ActionController::API, so it has no asset helpers of
    # its own -- ask ActionController::Base for them. The stylesheet is a
    # precompiled bundle (config/initializers/assets.rb), shared with the
    # console so the two pages cannot drift apart visually.
    def stylesheet
      ActionController::Base.helpers.stylesheet_link_tag('mcp', media: 'all')
    end

    # Only where the console actually exists. A link to a 404 is worse than no
    # link, and on a deployed host the console is usually not there.
    def console_section
      return '' unless Console.enabled?

      <<-HTML
          <h2 class="mcp-section h6 text-uppercase text-body-secondary fw-semibold mt-5 mb-3">Try it here</h2>
          <p class="text-body-secondary">Run these tools in the browser &mdash; no client to install.</p>
          <a class="btn btn-outline-danger" href="#{Console::PATH}">
            <i class="fa fa-terminal me-2" aria-hidden="true"></i>Open the MCP console</a>
      HTML
    end

    # One icon per tool, from the set the rest of the catalog uses. Presentation
    # only -- a tool with no entry still lists, it just gets the generic glyph.
    TOOL_ICONS = {
      'search' => 'search',
      'advanced_search' => 'sliders',
      'describe_search_options' => 'list-ul',
      'facet_values' => 'tags',
      'get_record' => 'file-text-o',
      'check_availability' => 'check-circle-o',
      'fetch' => 'align-left'
    }.freeze

    DEFAULT_TOOL_ICON = 'book'

    def tool_items
      Server.tools.map do |tool|
        glyph = TOOL_ICONS.fetch(tool.name_value, DEFAULT_TOOL_ICON)

        "\n <li class=\"list-group-item d-flex align-items-baseline gap-2 px-0\">" \
          "<i class=\"fa fa-#{glyph} text-body-secondary\" aria-hidden=\"true\"></i>" \
          "<code>#{escape(tool.name_value)}</code>" \
          "<span class=\"text-body-secondary\">#{escape(tool.annotations.title)}</span></li>"
      end.join
    end

    def escape(value)
      ERB::Util.html_escape(value.to_s)
    end

  end
end
