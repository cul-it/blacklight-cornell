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
        <style>#{STYLE}</style>
        </head>
        <body>
        <main>
          <p class="eyebrow">Cornell University Library</p>
          <h1>Catalog MCP endpoint</h1>
          <p class="lede">Connect the library catalog to your AI assistant of choice.
             Read-only, and no account or key required.</p>

          <p class="url">#{escape(url)}</p>

          <h2>Connecting</h2>
          <dl>
            <dt>Claude Code</dt>
            <dd><code>claude mcp add --transport http cornell-library-catalog #{escape(url)}</code></dd>

            <dt>Claude Desktop or claude.ai</dt>
            <dd>Settings &rarr; Connectors &rarr; Add custom connector, then paste the URL above.</dd>

            <dt>Anything else</dt>
            <dd>Add it as a remote MCP server over &ldquo;streamable HTTP&rdquo; using the URL above.</dd>
          </dl>

          <h2>What your assistant can do with it</h2>
          <ul class="tools">#{tool_items}</ul>

          <p class="footnote">This URL speaks the
             <a href="https://modelcontextprotocol.io">Model Context Protocol</a> over POST, so there
             is nothing to browse here. To search the catalog yourself, use
             <a href="/">the catalog</a>.</p>
        </main>
        </body>
        </html>
      HTML
    end

    def tool_items
      Server.tools.map do |tool|
        "\n    <li><code>#{escape(tool.name_value)}</code> #{escape(tool.annotations.title)}</li>"
      end.join
    end

    def escape(value)
      ERB::Util.html_escape(value.to_s)
    end

    STYLE = <<~CSS
      :root { color-scheme: light dark; --ink: #1a1a1a; --muted: #5c5c5c; --rule: #e0ddd8;
              --bg: #fbfaf8; --panel: #fff; --accent: #b31b1b; }
      @media (prefers-color-scheme: dark) {
        :root { --ink: #ececec; --muted: #a3a3a3; --rule: #333; --bg: #161615; --panel: #201f1e;
                --accent: #ff6b6b; }
      }
      * { box-sizing: border-box; }
      body { margin: 0; padding: 3rem 1.25rem; background: var(--bg); color: var(--ink);
             font: 16px/1.6 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; }
      main { max-width: 44rem; margin: 0 auto; }
      .eyebrow { margin: 0; color: var(--accent); font-size: .8rem; font-weight: 600;
                 letter-spacing: .08em; text-transform: uppercase; }
      h1 { margin: .25rem 0 0; font-size: 1.9rem; line-height: 1.2; font-weight: 600; }
      .lede { margin: .75rem 0 2rem; color: var(--muted); font-size: 1.05rem; max-width: 34rem; }
      h2 { margin: 2.25rem 0 .75rem; font-size: .8rem; font-weight: 600; letter-spacing: .08em;
           text-transform: uppercase; color: var(--muted); }
      .url { margin: 0; padding: .9rem 1.1rem; background: var(--panel); border: 1px solid var(--rule);
             border-radius: 8px; font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
             font-size: .95rem; overflow-wrap: anywhere; }
      dl { margin: 0; }
      dt { font-weight: 600; margin-top: 1.1rem; }
      dd { margin: .35rem 0 0; color: var(--muted); }
      code { font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size: .875rem;
             background: var(--panel); border: 1px solid var(--rule); border-radius: 5px;
             padding: .15rem .4rem; overflow-wrap: anywhere; }
      dd code { display: inline-block; padding: .55rem .7rem; }
      ul.tools { margin: 0; padding: 0; list-style: none; }
      ul.tools li { padding: .5rem 0; border-bottom: 1px solid var(--rule); color: var(--muted); }
      ul.tools li:last-child { border-bottom: 0; }
      ul.tools code { margin-right: .5rem; color: var(--ink); }
      .footnote { margin-top: 2.5rem; padding-top: 1.25rem; border-top: 1px solid var(--rule);
                  color: var(--muted); font-size: .9rem; }
      a { color: var(--accent); }
    CSS
  end
end
