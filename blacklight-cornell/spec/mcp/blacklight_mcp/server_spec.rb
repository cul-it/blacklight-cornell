# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BlacklightMcp::Server do
  subject(:server) { described_class.build(base_url: 'http://test.host') }

  # id comes before any keywords so a params hash written inline here is not
  # mistaken for keyword arguments.
  def rpc(method, params = nil, id = 1)
    params ||= {}
    params[:_meta] = {
      'io.modelcontextprotocol/protocolVersion' => '2026-07-28',
      'io.modelcontextprotocol/clientCapabilities' => {}
    }
    body = { jsonrpc: '2.0', id: id, method: method }
    body[:params] = params
    result = server.handle_json(body.to_json)
    result && JSON.parse(result)
  end

  describe 'tools' do
    it 'advertises exactly the read-only catalog tools' do
      expect(described_class.tools.map(&:name_value))
        .to contain_exactly('search', 'advanced_search', 'describe_search_options', 'facet_values', 'get_record',
                            'check_availability', 'fetch')
    end

    it 'marks every tool read-only and non-destructive' do
      described_class.tools.each do |tool|
        expect(tool.annotations.read_only_hint).to be(true), "#{tool.name_value} is not read-only"
        expect(tool.annotations.destructive_hint).to be(false), "#{tool.name_value} is marked destructive"
      end
    end
  end

  describe 'server/discover' do
    it 'identifies the modern stateless server and declares only the tools capability' do
      result = rpc('server/discover')['result']

      expect(result['supportedVersions']).to eq(['2026-07-28'])
      expect(result.dig('_meta', 'io.modelcontextprotocol/serverInfo'))
        .to include('name' => described_class::NAME, 'version' => BlacklightMcp::VERSION)
      expect(result['capabilities'].keys).to eq(['tools'])
    end

    it 'ships instructions telling a client where to start' do
      result = rpc('server/discover')['result']
      expect(result['instructions']).to include('describe_search_options')
    end
  end

  describe 'tools/list' do
    let(:tools) { rpc('tools/list')['result']['tools'] }

    it 'returns every tool with a schema and a description' do
      expect(tools.map { |tool| tool['name'] })
        .to contain_exactly('search', 'advanced_search', 'describe_search_options', 'facet_values', 'get_record',
                            'check_availability', 'fetch')

      tools.each do |tool|
        expect(tool['description']).to be_present
        expect(tool['inputSchema']).to be_present
        expect(tool['annotations']['readOnlyHint']).to be true
      end
    end
  end

  describe 'the allowlist of JSON-RPC methods' do
    it 'permits only lifecycle methods, discovery and reads' do
      expect(described_class::ALLOWED_METHODS)
        .to eq(%w[initialize notifications/initialized ping server/discover tools/list tools/call])
    end

    it 'rejects anything else' do
      expect(described_class.allowed_method?('tools/call')).to be true
      expect(described_class.allowed_method?('initialize')).to be true
      expect(described_class.allowed_method?('resources/read')).to be false
      expect(described_class.allowed_method?('completion/complete')).to be false
    end
  end
end
