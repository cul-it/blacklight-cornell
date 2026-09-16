# frozen_string_literal: true

module BlacklightMcp
  # What a person sees when they paste the MCP URL into a browser.
  #
  # The endpoint speaks JSON-RPC over POST, so a browser -- which can only GET
  # -- gets a protocol error that looks like a broken site. It isn't broken, but
  # nobody can tell that from `"Method not allowed"`. This page says what the URL
  # is for, how to connect an assistant to it, and -- because most readers are
  # students who have never heard of MCP -- what to actually ask once they have.
  #
  # MCP clients never see this. They ask for `text/event-stream` and keep the
  # 405 the protocol calls for.
  #
  # The tool list is generated from Server.tools, so the page cannot fall out of
  # step with what the endpoint actually offers. TOOL_GUIDE adds the words and
  # example prompts for the tools it knows; a tool without an entry still lists,
  # with its own title and a generic glyph.
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
        <main class="container py-4 py-md-5 mcp-page">
          #{header(url)}
          <section class="bg-body-secondary border rounded-4 p-3 p-md-4 mb-4" aria-labelledby="mcp-section-1">
            #{connect_section(url)}
          </section>
          <section class="bg-body-secondary border rounded-4 p-3 p-md-4 mb-4" aria-labelledby="mcp-section-2">
            #{tools_section}
          </section>
          <section class="bg-body-secondary border rounded-4 p-3 p-md-4 mb-4" aria-labelledby="mcp-section-3">
            #{walkthrough_section}
          </section>
          <section class="bg-body-secondary border rounded-4 p-3 p-md-4 mb-4" aria-labelledby="mcp-section-4">
            #{tips_section}
          </section>
          #{console_section}
          #{footer}
        </main>
        #{copy_script}
        </body>
        </html>
      HTML
    end

    # ------------------------------------------------------------------------
    # Header: what this is, in one breath, and the URL to copy.
    # ------------------------------------------------------------------------
    def header(url)
      <<-HTML
          <p class="text-danger fs-4 fw-semibold mb-2">Cornell University Library</p>
          <h1 class="fw-semibold mb-3">Search the library catalog with your AI assistant</h1>
          <p class="lead text-body-secondary mb-1">Connect once, then ask questions in plain English. </p>
            <p class="lead text-body-secondary mb-4">Your AI assistant can then search the catalog for you. No library account or login needed.</p>

          <div class="card bg-body-secondary border-0 shadow-sm mb-4">
            <div class="card-body py-3">
              <p class="small text-uppercase fw-semibold text-body-secondary mb-2">Your connection URL</p>
              <div class="d-flex flex-wrap align-items-center gap-2">
                <code class="mcp-command bg-body border rounded px-3 py-2 flex-grow-1" id="endpoint-url">#{escape(url)}</code>
                #{copy_button('endpoint-url', 'Copy URL')}
                <span class="badge text-bg-secondary" title="Server version">v#{escape(BlacklightMcp::VERSION)}</span>
              </div>
              #{tool_list}
            </div>
          </div>
      HTML
    end

    # A compact reference, populated from the same registry as the server.
    # Native disclosure keeps it keyboard-accessible without extra JavaScript.
    def tool_list
      items = Server.tools.map do |tool|
        description = TOOL_GUIDE.fetch(tool.name_value, {})[:title] || tool.annotations.title

        "<li class=\"list-group-item py-2\"><code class=\"text-break\">#{escape(tool.name_value)}</code>" \
          " <span class=\"text-body-secondary\">&mdash; #{escape(description)}</span></li>"
      end.join

      <<-HTML
              <details class="mt-3">
                <summary class="btn btn-outline-secondary"><i class="fa fa-list-ul me-1" aria-hidden="true"></i>MCP Tool List</summary>
                <ul class="list-group mt-3" aria-label="Available MCP tools">#{items}</ul>
              </details>
      HTML
    end

    # ------------------------------------------------------------------------
    # Connecting: pick your assistant, get its steps. Every assistant has its
    # own menu for this, and a student only wants to read about the one they
    # have. The pills are Bootstrap's btn-check radios, so the selected state
    # needs no script; the script at the foot of the page only hides the
    # panels that were not picked. Without it, all four show.
    # ------------------------------------------------------------------------
    ASSISTANTS = [
      { key: 'claude', label: 'Claude', icon: 'comment-o' },
      { key: 'chatgpt', label: 'ChatGPT / Codex', icon: 'comments-o' },
      { key: 'gemini', label: 'Gemini', icon: 'star-o' },
      { key: 'other', label: 'Something else', icon: 'globe' }
    ].freeze

    def connect_section(url)
      <<-HTML
          #{section_heading('1', 'Connect it to your AI assistant', 'Choose your AI assistant for setup instructions.')}
          <div class="mcp-picker">
            <div class="d-flex flex-wrap gap-2 mb-3" role="radiogroup" aria-label="Your AI assistant">#{assistant_pills}
            </div>
            #{assistant_panel('claude', claude_steps(url))}
            #{assistant_panel('chatgpt', chatgpt_steps(url))}
            #{assistant_panel('gemini', gemini_steps(url))}
            #{assistant_panel('other', other_steps)}
          </div>
      HTML
    end

    def assistant_pills
      ASSISTANTS.each_with_index.map do |assistant, index|
        checked = index.zero? ? ' checked' : ''

        "\n              <input type=\"radio\" class=\"btn-check\" name=\"assistant\" " \
          "id=\"pick-#{assistant[:key]}\" value=\"#{assistant[:key]}\" autocomplete=\"off\"#{checked}>" \
          "\n              <label class=\"btn btn-outline-danger rounded-pill px-3\" for=\"pick-#{assistant[:key]}\">" \
          "<i class=\"fa fa-#{assistant[:icon]} me-2\" aria-hidden=\"true\"></i>#{escape(assistant[:label])}</label>"
      end.join
    end

    def assistant_panel(key, body)
      <<-HTML
            <div class="card rounded-3 shadow-sm mcp-assistant" id="assistant-#{key}" data-assistant="#{key}">
              <div class="card-body p-3 p-md-4">
#{body}
              </div>
            </div>
      HTML
    end

    def claude_steps(url)
      <<-HTML
                <div class="row g-4">
                  <div class="col-md-6">
                    <h3 class="h5 fw-semibold mb-3"><i class="fa fa-plug text-danger me-2" aria-hidden="true"></i>Claude app or claude.ai</h3>
                    <ol class="ps-3 mb-3">
                      <li class="mb-2">Open <span class="fw-semibold">Customize &rarr; Connectors</span>.</li>
                      <li class="mb-2">Choose <span class="fw-semibold">+ &rarr; Add custom connector</span>.</li>
                      <li class="mb-2">Paste the URL above and click <span class="fw-semibold">Add</span>.</li>
                      <li>In a chat, open <span class="fw-semibold">+ &rarr; Connectors</span> and enable the catalog.</li>
                    </ol>
                    <p class="text-body-secondary mb-2">On Team and Enterprise plans, an organization owner must add
                       the connector first. Free accounts are limited to one custom connector.</p>
                    <a href="https://support.claude.com/en/articles/11175166-get-started-with-custom-connectors-using-remote-mcp">Claude setup guide</a>
                  </div>
                  <div class="col-md-6">
                    <h3 class="h5 fw-semibold mb-3"><i class="fa fa-terminal text-danger me-2" aria-hidden="true"></i>Claude Code</h3>
                    <p class="mb-2">With Claude Code installed, run this once for all your projects:</p>
                    #{command_block('claude-code-command', "claude mcp add --transport http --scope user cornell-library-catalog #{url}")}
                    <a href="https://code.claude.com/docs/en/mcp">Claude Code setup guide</a>
                  </div>
                </div>
      HTML
    end

    def chatgpt_steps(url)
      <<-HTML
                <div class="row g-4">
                  <div class="col-md-6">
                    <h3 class="h5 fw-semibold mb-3"><i class="fa fa-plug text-danger me-2" aria-hidden="true"></i>ChatGPT</h3>
                    <ol class="ps-3 mb-3">
                      <li class="mb-2">Open <span class="fw-semibold">Settings &rarr; Security and login</span> and enable
                          <span class="fw-semibold">Developer mode</span>.</li>
                      <li class="mb-2">Open <span class="fw-semibold">Plugins</span> and select <span class="fw-semibold">+</span>.</li>
                      <li class="mb-2">Enter a name such as <span class="fw-semibold">Cornell Library Catalog</span> and a description.
                          Under <span class="fw-semibold">Connection</span>, enter the URL above. No catalog authentication is required.</li>
                      <li class="mb-2">Create the connection and review the discovered tools.</li>
                      <li>In a new chat, add the connection from the tools menu.</li>
                    </ol>
                    <p class="text-body-secondary mb-2">Developer mode availability depends on your account and workspace policy.</p>
                    <a href="https://developers.openai.com/plugins/deploy/connect-chatgpt">ChatGPT setup guide</a>
                  </div>
                  <div class="col-md-6">
                    <h3 class="h5 fw-semibold mb-3"><i class="fa fa-terminal text-danger me-2" aria-hidden="true"></i>Codex</h3>
                    <p class="mb-2">With the Codex CLI installed, run this once in your terminal:</p>
                    #{command_block('codex-command', "codex mcp add cornell-library-catalog --url #{url}")}
                    <a href="https://learn.chatgpt.com/docs/extend/mcp?surface=cli">Codex setup guide</a>
                  </div>
                </div>
      HTML
    end

    def gemini_steps(url)
      <<-HTML
                <div class="row g-4">
                  <div class="col-md-6">
                    <h3 class="h5 fw-semibold mb-3"><i class="fa fa-terminal text-danger me-2" aria-hidden="true"></i>Gemini CLI</h3>
                    <p class="mb-2">With Gemini CLI installed, run this once for all your projects:</p>
                    #{command_block('gemini-command', "gemini mcp add --transport http --scope user cornell-library-catalog #{url}")}
                    <a href="https://geminicli.com/docs/tools/mcp-server/">Gemini CLI setup guide</a>
                  </div>
                  <div class="col-md-6">
                    <h3 class="h5 fw-semibold mb-3"><i class="fa fa-plug text-danger me-2" aria-hidden="true"></i>Gemini app</h3>
                    <ol class="ps-3 mb-3">
                      <li class="mb-2">On <span class="fw-semibold">gemini.google.com</span>, open
                          <span class="fw-semibold">Settings &rarr; Connected Apps</span> (this may be under
                          <span class="fw-semibold">Personal Intelligence</span>).</li>
                      <li class="mb-2">Under <span class="fw-semibold">Custom apps</span>, add the URL above.</li>
                      <li>Click <span class="fw-semibold">Next</span> and follow the prompts. In a chat, type
                          <span class="fw-semibold">@</span> to select the app.</li>
                    </ol>
                    <p class="text-body-secondary mb-2">Requires a personal Google Account, age 18+, US location,
                       and Keep Activity enabled. Work and school accounts are not currently supported.</p>
                    <a href="https://support.google.com/gemini/answer/17209137">Gemini app setup guide</a>
                  </div>
                </div>
      HTML
    end

    def other_steps
      <<-HTML
                <h3 class="h5 fw-semibold mb-3"><i class="fa fa-globe text-danger me-2" aria-hidden="true"></i>Assistants that support remote MCP</h3>
                <p class="mb-3">Follow your assistant's instructions for adding a custom remote MCP server.
                   Paste the URL above, choose <span class="fw-semibold">Streamable HTTP</span> if asked for a transport,
                   and choose <span class="fw-semibold">None</span> for authentication.</p>
                <p class="text-body-secondary mb-2">Setup and availability vary by assistant and account.</p>
                <div class="d-flex flex-wrap gap-3">
                  <a href="https://cursor.com/docs/mcp">Cursor setup guide</a>
                  <a href="https://code.visualstudio.com/docs/agent-customization/mcp-servers">GitHub Copilot in VS Code setup guide</a>
                  <a href="https://www.perplexity.ai/help-center/en/articles/13915507-adding-custom-remote-connectors">Perplexity setup guide</a>
                </div>
      HTML
    end

    # A terminal command with its own copy button, on one line the reader can
    # select whole.
    def command_block(id, command)
      "<div class=\"bg-body-tertiary border rounded-3 p-3 mb-3\">" \
        "<code class=\"mcp-command d-block mb-3\" id=\"#{escape(id)}\">#{escape(command)}</code>\n" \
        "                    #{copy_button(id, 'Copy command')}</div>"
    end

    # ------------------------------------------------------------------------
    # The tools, as questions. A student never calls a tool by name -- they
    # ask, and the assistant picks the tool. So each card leads with when you
    # would want it and what you might say, and only then names the tool.
    # ------------------------------------------------------------------------
    def tools_section
      <<-HTML
          #{section_heading('2', 'Ask in plain English',
                            'You never have to name a tool. Ask a question and your assistant picks the right one. ' \
                            'Here is everything it can do for you, with things you could say to get there.')}
          <div class="row g-3">#{tool_cards}
          </div>
      HTML
    end

    def tool_cards
      Server.tools.map { |tool| tool_card(tool) }.join
    end

    def tool_card(tool)
      guide = TOOL_GUIDE.fetch(tool.name_value, {})
      glyph = guide.fetch(:icon, DEFAULT_TOOL_ICON)
      title = guide[:title] || tool.annotations.title
      use_when = guide[:use_when] || tool.annotations.title

      <<-HTML

            <div class="col-md-6 d-flex">
              <div class="card w-100 h-100 mcp-tool">
                <div class="card-body">
                  <div class="d-flex align-items-start gap-3 mb-3">
                    <span class="mcp-tool-icon bg-danger-subtle text-danger rounded-3 flex-shrink-0" aria-hidden="true">
                      <i class="fa fa-#{glyph}"></i></span>
                    <div>
                      <h3 class="h5 fw-semibold mb-1">#{escape(title)}</h3>
                      <p class="text-body-secondary mb-0">#{escape(use_when)}</p>
                    </div>
                  </div>
                  #{prompt_list(guide[:prompts])}
                  <p class="small text-body-secondary mb-0 mt-3 pt-3 border-top">
                    <i class="fa fa-wrench me-1" aria-hidden="true"></i>Your assistant will show this as <code>#{escape(tool.name_value)}</code>
                  </p>
                </div>
              </div>
            </div>
      HTML
    end

    # Example things to say, styled as messages: words to type, not commands.
    def prompt_list(prompts)
      return '' if prompts.blank?

      items = prompts.map do |prompt|
        "\n                    <li class=\"mcp-prompt\">" \
          "<i class=\"fa fa-comment-o text-body-secondary me-2\" aria-hidden=\"true\"></i>" \
          "&ldquo;#{escape(prompt)}&rdquo;</li>"
      end.join

      <<-HTML
                  <p class="small text-uppercase fw-semibold text-body-secondary mb-2">Try saying</p>
                  <ul class="list-unstyled mb-0 d-grid gap-2">#{items}
                  </ul>
      HTML
    end

    # ------------------------------------------------------------------------
    # One conversation that uses several tools in turn -- because the real
    # value is not any one tool, it is the assistant chaining them.
    # ------------------------------------------------------------------------
    def walkthrough_section
      <<-HTML
          #{section_heading('3', 'Put it together', 'One question can set off several tools. Here is what that looks like.')}
          <div class="card">
            <div class="card-body">
              <p class="mcp-prompt mb-4">
                <i class="fa fa-comment-o text-body-secondary me-2" aria-hidden="true"></i>&ldquo;I&rsquo;m writing a paper on
                the 1918 flu in New York. Find me five recent books, tell me which ones I can pick up
                today, and show me what&rsquo;s shelved next to the best one.&rdquo;</p>
              <p class="small text-uppercase fw-semibold text-body-secondary mb-2">Your assistant will</p>
              <ol class="mcp-steps list-unstyled d-grid gap-2 mb-3">
                <li class="d-flex gap-3 align-items-start">
                  <span class="badge rounded-pill text-bg-danger flex-shrink-0">1</span>
                  <span>Run <code>search</code> for <em>1918 influenza New York</em>, books only, newest first.</span>
                </li>
                <li class="d-flex gap-3 align-items-start">
                  <span class="badge rounded-pill text-bg-danger flex-shrink-0">2</span>
                  <span>Check each of those five with <code>check_availability</code> and tell you which are on a
                        shelf right now, in which library, and which you can read online.</span>
                </li>
                <li class="d-flex gap-3 align-items-start">
                  <span class="badge rounded-pill text-bg-danger flex-shrink-0">3</span>
                  <span>Take the best one&rsquo;s call number to <code>browse_call_numbers</code> and list its shelf
                        neighbours &mdash; books a subject search would have missed.</span>
                </li>
                <li class="d-flex gap-3 align-items-start">
                  <span class="badge rounded-pill text-bg-danger flex-shrink-0">4</span>
                  <span>Answer with titles, call numbers, and a link to each record in the catalog.</span>
                </li>
              </ol>
              <p class="text-body-secondary mb-0">Follow up in the same chat: <em>&ldquo;Summarize the second
                 one&rdquo;</em> (<code>fetch</code>), <em>&ldquo;What subject headings does it use?&rdquo;</em>
                 (<code>get_record</code>), <em>&ldquo;Any of these in Spanish?&rdquo;</em> (<code>facet_values</code>).</p>
            </div>
          </div>
      HTML
    end

    # ------------------------------------------------------------------------
    # The things people trip on, said up front.
    # ------------------------------------------------------------------------
    def tips_section
      <<-HTML
          #{section_heading('4', 'Good to know')}
          <div class="row g-3 mb-4">
            #{tip('book', 'Same catalog, same results',
                  'Your assistant searches the very same catalog you would at catalog.library.cornell.edu, so anything ' \
                  'it finds, you can find and check yourself.')}
            #{tip('clock-o', 'Availability can lag a little',
                  'Whether a book is on the shelf is updated a short while behind the circulation desk. ' \
                  'To borrow, recall or place a hold, follow the record link your assistant gives you.')}
            #{tip('link', 'Ask for the link',
                  'Every result carries a link to the record in the catalog. If your assistant summarizes without one, ' \
                  'ask for it — that page is where you request the item.')}
            #{tip('question-circle-o', 'Not sure what to ask?',
                  'Say “What can you search in the library catalog?” Your assistant will describe the search ' \
                  'fields, formats, languages and sort orders it has to work with.')}
          </div>
          #{reconnect_note}
      HTML
    end

    def tip(glyph, title, body)
      <<-HTML
            <div class="col-md-6 d-flex">
              <div class="d-flex gap-3 p-3 border rounded-3 bg-body w-100">
                <i class="fa fa-#{glyph} fa-lg text-danger mt-1" aria-hidden="true"></i>
                <div>
                  <p class="fs-5 fw-semibold mb-1">#{escape(title)}</p>
                  <p class="text-body-secondary mb-0">#{escape(body)}</p>
                </div>
              </div>
            </div>
      HTML
    end

    # An assistant reads the tool list once, when it connects, and keeps it for
    # the life of that connection. So this page can list a tool the assistant
    # in front of you has never heard of, and the fix is always the same:
    # connect again. Said here because this is where someone looks when their
    # assistant cannot find a tool the library has announced.
    def reconnect_note
      <<-HTML
          <div class="alert alert-secondary d-flex gap-2 mb-0" role="note">
            <i class="fa fa-refresh mt-1" aria-hidden="true"></i>
            <div>
              <span class="fw-semibold">Missing a tool from this list?</span>
              Your assistant only checks what the catalog offers when it first connects, so
              disconnect it and connect again to pick up anything new.
            </div>
          </div>
      HTML
    end

    # Only where the console actually exists. A link to a 404 is worse than no
    # link, and on a deployed host the console is usually not there.
    def console_section
      return '' unless Console.enabled?

      <<-HTML
          <div class="card border-0 bg-danger-subtle mt-5 mb-4">
            <div class="card-body d-flex flex-wrap justify-content-between align-items-center gap-3">
              <div>
                <p class="fw-semibold mb-1"><i class="fa fa-terminal me-2" aria-hidden="true"></i>No assistant handy? Try the tools in your browser.</p>
                <p class="text-body-secondary mb-0">Run any of the examples above right here and see what the catalog sends back.</p>
              </div>
              <a class="btn btn-danger" href="#{Console::PATH}">Open the MCP console</a>
            </div>
          </div>
      HTML
    end

    def footer
      <<-HTML
          <p class="text-body-secondary border-top pt-3 mt-5 mb-0">
             <i class="fa fa-info-circle me-1" aria-hidden="true"></i>This address is for your assistant;
             there is nothing to search on this page. To search the catalog yourself, go to
             <a href="#{escape(BlacklightMcp.catalog_url)}">the catalog</a>.
             Built on the <a href="https://modelcontextprotocol.io">Model Context Protocol</a>.</p>
      HTML
    end

    # ------------------------------------------------------------------------
    # Small pieces
    # ------------------------------------------------------------------------
    def section_heading(number, title, lede = nil)
      lede_html = lede ? "<p class=\"text-body-secondary mb-0\">#{escape(lede)}</p>" : ''

      <<-HTML
          <div class="d-flex align-items-start gap-3 mb-4">
            <span class="mcp-step badge rounded-pill text-bg-danger fs-6 flex-shrink-0" aria-hidden="true">#{escape(number)}</span>
            <div>
              <h2 class="h4 fw-semibold mb-1" id="mcp-section-#{escape(number)}">#{escape(title)}</h2>
              #{lede_html}
            </div>
          </div>
      HTML
    end

    # Progressive: the button is hidden until the script below confirms the
    # browser can write to the clipboard, so nothing on the page promises what
    # it cannot do.
    def copy_button(target_id, label, size: nil)
      size_class = size ? " btn-#{size}" : ''

      "<button type=\"button\" class=\"btn btn-outline-secondary#{size_class} mcp-copy\" " \
        "data-copy-target=\"#{escape(target_id)}\" hidden>" \
        "<i class=\"fa fa-clipboard me-1\" aria-hidden=\"true\"></i>#{escape(label)}</button>"
    end

    def copy_script
      <<~HTML
        <script>
        (function () {
          // Show only the assistant that was picked. Without this script every
          // panel shows, which still reads.
          var picks = document.querySelectorAll('input[name="assistant"]');
          var panels = document.querySelectorAll('.mcp-assistant');
          function showPicked() {
            var picked = document.querySelector('input[name="assistant"]:checked');
            panels.forEach(function (panel) {
              panel.hidden = !picked || panel.dataset.assistant !== picked.value;
            });
          }
          picks.forEach(function (pick) { pick.addEventListener('change', showPicked); });
          showPicked();

          if (!navigator.clipboard) { return; }
          document.querySelectorAll('.mcp-copy').forEach(function (button) {
            button.hidden = false;
            button.addEventListener('click', function () {
              var source = document.getElementById(button.dataset.copyTarget);
              var label = button.innerHTML;
              navigator.clipboard.writeText(source.textContent.trim()).then(function () {
                button.innerHTML = '<i class="fa fa-check me-1" aria-hidden="true"></i>Copied';
                setTimeout(function () { button.innerHTML = label; }, 1500);
              });
            });
          });
        })();
        </script>
      HTML
    end

    # McpController is an ActionController::API, so it has no asset helpers of
    # its own. In development, use a fresh view context so Sprockets picks up
    # stylesheet edits. Elsewhere, reuse the shared helpers proxy.
    def stylesheet
      helpers = Rails.env.development? ? ActionController::Base.new.helpers : ActionController::Base.helpers
      helpers.stylesheet_link_tag('mcp', media: 'all')
    end

    def escape(value)
      ERB::Util.html_escape(value.to_s)
    end

    # ------------------------------------------------------------------------
    # The words for each tool: a heading in a student's terms, when they would
    # want it, and things they could say to their assistant to reach it.
    #
    # Presentation only. A tool missing from here still lists, with its own
    # title and the generic glyph.
    # ------------------------------------------------------------------------
    DEFAULT_TOOL_ICON = 'book'

    TOOL_GUIDE = {
      'search' => {
        icon: 'search',
        title: 'Search the catalog',
        use_when: 'The everyday search. One question, optionally narrowed by format, language, ' \
                  'publication year or sort order.',
        prompts: [
          'Find recent books about climate change and coastal cities.',
          'What does the library have by Toni Morrison? Newest first.',
          'Are there any books about jazz in Spanish?'
        ]
      },
      'advanced_search' => {
        icon: 'sliders',
        title: 'Combine searches with AND, OR and NOT',
        use_when: 'For questions with an AND, OR or NOT in them, or where different words belong ' \
                  'in different fields (author, title, subject).',
        prompts: [
          'Find books with cholera as a subject that mention London.',
          'Show me works by Shakespeare, but leave out Hamlet.',
          'Books with "machine learning" or "deep learning" in the title.'
        ]
      },
      'describe_search_options' => {
        icon: 'list-ul',
        title: 'See what you can search and filter by',
        use_when: 'When you are not sure what the catalog can filter or sort by. Lists every ' \
                  'search field, filter and sort order, with examples of each.',
        prompts: [
          'What can you search or filter in the library catalog?',
          'What formats and languages does the catalog have?'
        ]
      },
      'facet_values' => {
        icon: 'tags',
        title: 'See every option in one filter',
        use_when: 'To see every option in one filter, with counts: all the languages, formats or ' \
                  'libraries, or just the ones among the results of a search.',
        prompts: [
          'Which languages are the books about ancient Rome in?',
          'List every format the catalog has, most common first.'
        ]
      },
      'get_record' => {
        icon: 'file-text-o',
        title: 'Get everything about one item',
        use_when: 'The complete record for one result: every detail the catalog has, including ' \
                  'subject headings and tables of contents.',
        prompts: [
          'Show me the full record for the first result.',
          'What subject headings does that book use? I want to search on them.'
        ]
      },
      'fetch' => {
        icon: 'align-left',
        title: 'Read one item as plain text',
        use_when: 'One record as readable text: title, a description, the main fields, and the ' \
                  'link. What an assistant reads before summarizing or citing something.',
        prompts: [
          'Summarize the second result for me.',
          'Give me a citation for that book in APA style.'
        ]
      },
      'check_availability' => {
        icon: 'check-circle-o',
        title: 'Find out if you can get it today',
        use_when: 'The "can I get it today" question. Which library holds it, its call number, how ' \
                  'many copies are on the shelf, and any online access links.',
        prompts: [
          'Which of those five books can I pick up from Olin today?',
          'Is there an online copy of that one?'
        ]
      },
      'browse_call_numbers' => {
        icon: 'list-ol',
        title: 'Browse the shelf around a call number',
        use_when: 'Walk the shelf around a call number, the way you would in the stacks. Finds ' \
                  'books a subject search misses.',
        prompts: [
          'What is shelved next to PS3561.I483?',
          'And what comes just before it on the shelf?'
        ]
      }
    }.freeze
  end
end
