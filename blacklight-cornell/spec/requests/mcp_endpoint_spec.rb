# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'The MCP endpoint', type: :request do
  PROTOCOL_VERSION = '2026-07-28'
  LEGACY_PROTOCOL_VERSION = '2025-11-25'

  # Adds the per-request metadata and mirrored HTTP headers required by modern,
  # stateless MCP.
  def rpc(body, headers = {})
    payload = body.is_a?(Hash) ? modern_request(body) : body
    method = payload.is_a?(Hash) ? payload[:method] : 'tools/list'
    params = payload.is_a?(Hash) ? payload[:params] : nil

    request_headers = {
      'CONTENT_TYPE' => 'application/json',
      'HTTP_ACCEPT' => 'application/json, text/event-stream',
      'HTTP_MCP_PROTOCOL_VERSION' => PROTOCOL_VERSION,
      'HTTP_MCP_METHOD' => method
    }
    request_headers['HTTP_MCP_NAME'] = params[:name] if params.is_a?(Hash) && params[:name]

    post '/mcp', params: payload.is_a?(String) ? payload : payload.to_json,
                 headers: request_headers.merge(headers)
  end

  def modern_request(body)
    request_body = body.deep_dup
    params = request_body[:params] ||= {}
    params[:_meta] = {
      'io.modelcontextprotocol/protocolVersion' => PROTOCOL_VERSION,
      'io.modelcontextprotocol/clientInfo' => { name: 'spec', version: '1' },
      'io.modelcontextprotocol/clientCapabilities' => {}
    }
    request_body
  end

  def legacy_rpc(body, headers = {})
    request_headers = {
      'CONTENT_TYPE' => 'application/json',
      'HTTP_ACCEPT' => 'application/json, text/event-stream'
    }
    post '/mcp', params: body.to_json, headers: request_headers.merge(headers)
  end

  def json
    JSON.parse(response.body)
  end

  describe 'GET /mcp' do
    it 'cleanly declines the optional legacy SSE stream' do
      get '/mcp', headers: { 'HTTP_ACCEPT' => 'text/event-stream' }

      expect(response).to have_http_status(:method_not_allowed)
      expect(json.dig('error', 'message')).to eq('Method not allowed')
    end
  end

  describe 'POST /mcp' do
    it 'supports stateless server discovery without a handshake' do
      rpc(jsonrpc: '2.0', id: 1, method: 'server/discover')

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('application/json')
      expect(json['result']['supportedVersions']).to eq([PROTOCOL_VERSION])
      expect(json.dig('result', '_meta', 'io.modelcontextprotocol/serverInfo', 'name'))
        .to eq(BlacklightMcp::Server::NAME)
    end

    it 'lists the tools' do
      rpc(jsonrpc: '2.0', id: 2, method: 'tools/list')

      expect(json['result']['tools'].map { |tool| tool['name'] })
        .to contain_exactly('search', 'advanced_search', 'describe_search_options', 'facet_values', 'get_record',
                            'check_availability')
    end

    it 'does not require a CSRF token' do
      expect { rpc(jsonrpc: '2.0', id: 3, method: 'tools/list') }.not_to raise_error
      expect(response).to have_http_status(:ok)
    end

    it 'accepts the legacy initialize handshake used by Claude' do
      legacy_rpc(jsonrpc: '2.0', id: 1, method: 'initialize',
                 params: { protocolVersion: LEGACY_PROTOCOL_VERSION, capabilities: {},
                           clientInfo: { name: 'mcp-remote-fallback-test', version: '0.0.0' } })

      expect(response).to have_http_status(:ok)
      expect(json.dig('result', 'protocolVersion')).to eq(LEGACY_PROTOCOL_VERSION)
      expect(json.dig('result', 'serverInfo', 'name')).to eq(BlacklightMcp::Server::NAME)
      expect(response.headers['Mcp-Session-Id']).to be_nil
    end

    it 'accepts legacy follow-up requests without retaining a session' do
      legacy_rpc({ jsonrpc: '2.0', id: 2, method: 'tools/list' },
                 'HTTP_MCP_PROTOCOL_VERSION' => LEGACY_PROTOCOL_VERSION)

      expect(response).to have_http_status(:ok)
      expect(json['result']['tools'].map { |tool| tool['name'] })
        .to contain_exactly('search', 'advanced_search', 'describe_search_options', 'facet_values', 'get_record',
                            'check_availability')
    end

    it 'accepts the legacy initialized notification' do
      legacy_rpc({ jsonrpc: '2.0', method: 'notifications/initialized' },
                 'HTTP_MCP_PROTOCOL_VERSION' => LEGACY_PROTOCOL_VERSION)

      expect(response).to have_http_status(:accepted)
      expect(response.body).to be_empty
    end

    it 'requires the protocol version header when the body uses the modern envelope' do
      rpc({ jsonrpc: '2.0', id: 2, method: 'tools/list' }, 'HTTP_MCP_PROTOCOL_VERSION' => nil)

      expect(response).to have_http_status(:bad_request)
      expect(json['error']['code']).to eq(MCP::ErrorCodes::HEADER_MISMATCH)
    end

    it 'runs a tool and returns its result' do
      stub_search_runner(response: solr_response(docs: [{ 'id' => '1', 'title_display' => 'Batman' }]))

      rpc(jsonrpc: '2.0', id: 4, method: 'tools/call',
          params: { name: 'search', arguments: { query: 'batman' } })

      payload = JSON.parse(json['result']['content'].first['text'])
      expect(payload['documents'].first).to include('id' => '1', 'title' => 'Batman')
    end

    it 'builds record urls from the requesting host' do
      stub_search_runner(response: solr_response(docs: [{ 'id' => '1' }]))

      rpc(jsonrpc: '2.0', id: 5, method: 'tools/call',
          params: { name: 'search', arguments: { query: 'x' } })

      payload = JSON.parse(json['result']['content'].first['text'])
      expect(payload['documents'].first['url']).to eq('http://www.example.com/catalog/1')
    end

    it 'rejects an argument the tool schema forbids, naming the allowed values' do
      stub_search_runner

      rpc(jsonrpc: '2.0', id: 6, method: 'tools/call',
          params: { name: 'search', arguments: { query: 'x', sort: 'popularity' } })

      expect(json['result']['isError']).to be true
      expect(json['result']['content'].first['text']).to match(/not one of.*relevance/m)
    end

    it 'returns a schema-valid but catalog-invalid argument as a tool error the caller can act on' do
      stub_search_runner

      rpc(jsonrpc: '2.0', id: 7, method: 'tools/call',
          params: { name: 'search', arguments: { query: 'x', filters: { 'not_a_facet' => ['y'] } } })

      expect(json['result']['isError']).to be true
      expect(json['result']['content'].first['text']).to match(/unknown facet field "not_a_facet"/)
    end
  end

  describe 'request logging' do
    # This summary is what shows up in the development log in place of the raw
    # `Parameters:` line, so its exact wording is worth pinning down. #summarize
    # only formats text, so it is called directly rather than through the logger.
    let(:controller) { McpController.new }

    def summarize(method, params, id = 14, expanded: true)
      allow(controller).to receive(:expanded_logging?).and_return(expanded)
      controller.send(:summarize, { 'id' => id, 'method' => method, 'params' => params })
    end

    def tool_call(arguments, name = 'advanced_search')
      summarize('tools/call', { 'name' => name, 'arguments' => arguments })
    end

    context 'in development, where the log is read by a person' do
      it 'heads the summary with the request id, method and tool' do
        expect(tool_call({ 'query' => 'cats' }, 'search').first).to eq('#14 tools/call search')
      end

      it 'breaks arguments out one per line, aligned on the longest label' do
        lines = tool_call('booleans' => %w[AND NOT],
                          'languages' => ['Spanish'],
                          'sort' => 'year ascending')

        expect(lines.drop(1)).to eq([
                                      '  booleans:  AND, NOT',
                                      '  languages: Spanish',
                                      '  sort:      year ascending'
                                    ])
      end

      it 'puts each object in a list of objects on its own numbered line' do
        lines = tool_call('rows' => [{ 'query' => 'Stephen King', 'field' => 'author', 'op' => 'AND' },
                                     { 'query' => 'cats', 'field' => 'subject', 'op' => 'AND' }])

        expect(lines.drop(1)).to eq([
                                      '  rows: [1] query="Stephen King"  field=author  op=AND',
                                      '        [2] query=cats  field=subject  op=AND'
                                    ])
      end

      it 'keeps a list of scalars and a small object on one line each' do
        lines = tool_call('formats' => ['Book', 'Journal/Periodical'],
                          'date_range' => { 'begin' => 1984, 'end' => 1999 })

        expect(lines.drop(1)).to eq([
                                      '  formats:    Book, Journal/Periodical',
                                      '  date_range: begin=1984  end=1999'
                                    ])
      end

      it 'quotes only the values that would otherwise be ambiguous' do
        lines = tool_call('rows' => [{ 'query' => 'red planet', 'op' => 'AND' }])

        expect(lines.last).to include('query="red planet"').and include('op=AND')
      end

      it 'summarizes modern discovery on one line' do
        expect(summarize('server/discover', {}, 0)).to eq(['#0 server/discover'])
      end

      it 'summarizes a legacy handshake by the client that sent it' do
        lines = summarize('initialize', { 'clientInfo' => { 'name' => 'claude-ai', 'version' => '0.1.0' } }, 0)

        expect(lines).to eq(['#0 initialize <- claude-ai 0.1.0'])
      end

      it 'logs a method with no arguments on a single line' do
        expect(summarize('tools/list', {}, 2)).to eq(['#2 tools/list'])
      end

      it 'survives a request object with nothing useful in it' do
        expect(summarize(nil, nil, nil)).to eq(['(no method)'])
      end

      it 'caps a long value rather than flooding the log' do
        lines = tool_call('query' => 'x' * 5_000)

        expect(lines.last.length).to be <= McpController::MAX_LOGGED_LINE_LENGTH + 1
        expect(lines.last).to end_with('…')
      end

      it 'caps the number of lines' do
        rows = Array.new(McpController::MAX_LOGGED_LINES + 10) { |i| { 'query' => "q#{i}" } }
        lines = tool_call('rows' => rows)

        expect(lines.length).to eq(McpController::MAX_LOGGED_LINES + 1)
        expect(lines.last).to match(/more line\(s\)/)
      end
    end

    context 'outside development, where one request should stay one line' do
      it 'keeps the summary compact' do
        lines = summarize('tools/call',
                          { 'name' => 'advanced_search',
                            'arguments' => { 'formats' => ['Book'], 'sort' => 'year ascending' } },
                          14, expanded: false)

        expect(lines).to eq(['#14 tools/call advanced_search {"formats":["Book"],"sort":"year ascending"}'])
      end
    end

    it 'writes the summary during a real request, tagged for the log formatter' do
      stub_search_runner
      allow(Rails.logger).to receive(:info).and_call_original

      rpc(jsonrpc: '2.0', id: 14, method: 'tools/call',
          params: { name: 'search', arguments: { query: 'cats' } })

      expect(Rails.logger).to have_received(:info).with(a_string_starting_with('[MCP] #14 tools/call search'))
    end
  end

  describe 'read-only enforcement' do
    it 'refuses any JSON-RPC method outside the read-only allowlist' do
      %w[resources/read resources/write prompts/get logging/setLevel sampling/createMessage].each do |method|
        rpc(jsonrpc: '2.0', id: 7, method: method)

        expect(json['error']['code']).to eq(-32_601)
        expect(json['error']['message']).to match(/read-only/)
      end
    end

    it 'refuses JSON-RPC batches because every modern POST is one request' do
      rpc([{ jsonrpc: '2.0', id: 1, method: 'tools/list' },
           { jsonrpc: '2.0', id: 2, method: 'resources/read' }])

      expect(json['error']['code']).to eq(-32_600)
    end

    it 'is not reachable by mutation verbs' do
      %i[put patch delete].each do |verb|
        send(verb, '/mcp')
        expect(response).to have_http_status(:not_found), "#{verb.upcase} should not be routed"
      end
    end
  end

  describe 'authorization discovery probes' do
    paths = [
      '/.well-known/oauth-protected-resource/mcp',
      '/.well-known/oauth-protected-resource',
      '/.well-known/oauth-authorization-server/mcp',
      '/.well-known/oauth-authorization-server',
      '/.well-known/openid-configuration/mcp',
      '/.well-known/openid-configuration',
      '/mcp/.well-known/openid-configuration'
    ]

    paths.each do |path|
      it "returns a quiet JSON 404 for #{path}" do
        get path

        expect(response).to have_http_status(:not_found)
        expect(response.media_type).to eq('application/json')
        expect(json['error']).to match(/does not require authorization/)
      end
    end

    it 'does not intercept unrelated well-known paths' do
      get '/.well-known/acme-challenge/token'

      expect(response).to have_http_status(:not_found)
      expect(response.body).not_to include('does not require authorization')
    end
  end

  describe 'malformed requests' do
    it 'reports invalid JSON' do
      rpc('{not json')

      expect(json['error']['code']).to eq(-32_700)
    end

    it 'reports an empty body' do
      rpc('')

      expect(json['error']['code']).to eq(-32_700)
    end

    it 'refuses an oversized body without parsing it' do
      rpc({ jsonrpc: '2.0', id: 1, method: 'tools/list', params: { pad: 'x' * McpController::MAX_BODY_BYTES } })

      expect(json['error']['code']).to eq(-32_600)
      expect(json['error']['message']).to match(/exceeds/)
    end

    it 'reports an unknown tool' do
      rpc(jsonrpc: '2.0', id: 8, method: 'tools/call', params: { name: 'delete_everything', arguments: {} })

      expect(json).to have_key('error').or satisfy { |body| body.dig('result', 'isError') }
    end
  end
end
