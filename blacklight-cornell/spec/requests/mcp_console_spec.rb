# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'The MCP console', type: :request do
  # The test environment is not development, so the console is off unless a
  # spec turns it on -- which is the behaviour being described.
  def console(setting)
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('MCP_CONSOLE', '').and_return(setting)
  end

  # The client is a directory of files, assembled by the Sprockets manifest.
  # Reading it the way Sprockets does means these assertions keep working as
  # the files are split up further.
  def client_files
    manifest = Rails.root.join('app/assets/javascripts/mcp_console.js')

    manifest.read.scan(%r{^//=\s*require\s+(\S+)}).flatten.map do |name|
      Rails.root.join('app/assets/javascripts', "#{name}.js")
    end
  end

  def client_source
    client_files.map(&:read).join("\n")
  end

  describe 'where it exists' do
    it 'is absent outside development' do
      get '/mcp/console'

      expect(response).to have_http_status(:not_found)
    end

    it 'is there in development' do
      allow(Rails.env).to receive(:development?).and_return(true)
      get '/mcp/console'

      expect(response).to have_http_status(:ok)
    end

    it 'can be turned on anywhere with MCP_CONSOLE=true' do
      console('true')
      get '/mcp/console'

      expect(response).to have_http_status(:ok)
    end

    it 'can be turned off in development with MCP_CONSOLE=false' do
      allow(Rails.env).to receive(:development?).and_return(true)
      console('false')
      get '/mcp/console'

      expect(response).to have_http_status(:not_found)
    end

    # Only the two words. Anything else falls back to the default, which in
    # development means the console stays.
    it 'treats a value that is neither word as unset' do
      allow(Rails.env).to receive(:development?).and_return(true)

      ['on', 'off', '1', '0', 'maybe'].each do |value|
        console(value)
        get '/mcp/console'

        expect(response).to have_http_status(:ok), "#{value.inspect} should fall back to the default"
      end
    end
  end

  describe 'the page' do
    before { console('true') }

    it 'serves the client page' do
      get '/mcp/console'

      expect(response.media_type).to eq('text/html')
      expect(response.body).to include('Catalog MCP console')
    end

    it 'carries no markup-level styling or scripting of its own' do
      get '/mcp/console'

      expect(response.body).not_to include('<style>', '<script>')
      expect(response.body).to include('class="mcp-console"')
    end

    it 'loads the MCP bundle rather than inlining it' do
      get '/mcp/console'

      expect(response.body).to match(%r{<link[^>]+href="/assets/mcp[-.]})
      expect(response.body).to match(%r{<script[^>]+src="/assets/mcp_console[-.]})
    end

    it 'ships no tool list of its own in the markup' do
      get '/mcp/console'

      expect(response.body).not_to match(/<option[^>]*>(search|get_record|facet_values)</)
    end

    it 'keeps itself out of search engines' do
      get '/mcp/console'

      expect(response.body).to include('name="robots" content="noindex, nofollow"')
    end
  end

  # These assertions are about the client's source, not about how it is
  # delivered, so they read the asset rather than the page.
  describe 'the client script' do
    let(:source) { client_source }

    # Sprockets only ships what the manifest names, and a file left out of it
    # fails as a missing function at runtime rather than as a missing file.
    it 'is assembled from every file in the console directory' do
      root = Rails.root.join('app/assets/javascripts')
      listed = client_files.map { |path| path.relative_path_from(root).to_s }
      present = root.glob('mcp/console/**/*.js').map { |path| path.relative_path_from(root).to_s }

      expect(listed).to match_array(present)
    end

    # The page is the client: it talks to /mcp itself rather than going through
    # a server-side proxy, so there is only ever one code path to the tools.
    it 'points at this app\'s own MCP endpoint and calls it over JSON-RPC' do
      expect(source).to include("new URL('/mcp', window.location.href)")
      expect(source).to include("call('tools/list')")
    end

    # The tool list and every form come from the endpoint, so a new tool or a
    # new argument needs no change here. A tool *class* is keyed by name on
    # purpose -- an availability card cannot be drawn generically -- and a tool
    # without one gets the base class, which prints the payload as JSON.
    it 'ships no tool list of its own' do
      expect(source).to include('result.tools')
      expect(source).to include('Tool.registry[spec.name] || Tool')
    end

    # Solr field names are exactly what the endpoint stopped advertising; the
    # console must not put them back.
    it 'names no Solr facet field of its own' do
      expect(source).not_to include('language_facet', 'fast_geo_facet', 'subject_content_facet')
    end
  end

  # Every tool in the dropdown needs something to click, or the console is only
  # usable by someone who already knows the schema. A tool earns its example
  # either from a class of its own under console/tools, or by taking an argument
  # the base class knows how to fill for itself -- a record id, or a facet name.
  describe 'try options' do
    # id and ids are filled by looking a record up; field comes from the facet
    # enum the endpoint reports.
    DERIVABLE_ARGUMENTS = %w[id ids field].freeze

    # Which tool names have a class of their own, and whether that class writes
    # its own examples rather than only drawing results.
    def tool_classes
      Rails.root.glob('app/assets/javascripts/mcp/console/tools/*.js').filter_map do |path|
        source = path.read
        name = source[/Tool\.register\('([^']+)'/, 1]

        [name, source] if name
      end.to_h
    end

    it 'offers at least one for every advertised tool' do
      classes = tool_classes

      without = BlacklightMcp::Server.tools.reject do |tool|
        arguments = tool.input_schema.to_h[:properties].keys.map(&:to_s)

        classes[tool.name_value].to_s.include?('examples()') || (arguments & DERIVABLE_ARGUMENTS).any?
      end

      expect(without.map(&:name_value)).to be_empty,
        "no Try example for: #{without.map(&:name_value).join(', ')}. Give it an examples() " \
        'in app/assets/javascripts/mcp/console/tools/, or a class of its own there.'
    end

    # A class registered under a name the endpoint no longer advertises is dead
    # code that nothing will ever reach.
    it 'registers no tool this endpoint does not have' do
      advertised = BlacklightMcp::Server.tools.map(&:name_value)

      expect(tool_classes.keys - advertised).to be_empty
    end
  end

  # Production runs with config.assets.compile = false, so an asset missing from
  # this list is a 500 on these pages rather than a missing stylesheet.
  describe 'the asset bundles' do
    it 'are precompiled' do
      expect(Rails.application.config.assets.precompile).to include('mcp.css', 'mcp_console.js')
    end
  end

  describe 'the landing page at /mcp' do
    it 'points people at the console when there is one' do
      console('true')
      get '/mcp', headers: { 'HTTP_ACCEPT' => 'text/html' }

      expect(response.body).to include('/mcp/console', 'Try it here')
    end

    it 'does not link to a console that is not there' do
      get '/mcp', headers: { 'HTTP_ACCEPT' => 'text/html' }

      expect(response.body).not_to include('/mcp/console')
    end
  end
end
