# frozen_string_literal: true

# Helpers for the MCP specs: build fake Solr responses and run tools without
# needing a real Solr.
module McpSpecHelpers
  def blacklight_config
    CatalogController.blacklight_config
  end

  # A search response built from plain data, so the reply format can be checked
  # without an index behind it.
  def solr_response(docs: [], num_found: nil, rows: 20, start: 0, facets: {}, stats: {})
    payload = {
      'responseHeader' => { 'params' => { 'rows' => rows, 'start' => start } },
      'response' => { 'numFound' => num_found || docs.size, 'start' => start, 'docs' => docs }
    }
    payload['facet_counts'] = { 'facet_fields' => facets.transform_values { |pairs| pairs.flatten } } if facets.any?
    payload['stats'] = { 'stats_fields' => stats } if stats.any?

    Blacklight::Solr::Response.new(payload, { rows: rows, start: start }, blacklight_config: blacklight_config)
  end

  # Replaces the search runner so a tool can run without Solr, and records the
  # parameters the tool built. Returns those parameters.
  def stub_search_runner(response: nil, document: nil, facet_response: nil, solr_params: {})
    captured = {}
    runner = instance_double(BlacklightMcp::SearchRunner)

    allow(runner).to receive(:search_results).and_return(response || solr_response)
    allow(runner).to receive(:document).and_return(document)
    allow(runner).to receive(:facet_results).and_return(facet_response)
    allow(runner).to receive(:solr_params).and_return(solr_params)

    allow(BlacklightMcp::SearchRunner).to receive(:new) do |params|
      captured.replace(params.deep_dup)
      runner
    end

    captured
  end

  # Calls a tool and parses the JSON it replies with.
  #
  # server_context comes before any keywords on purpose. These helpers take tool
  # arguments written inline, like tool_payload(Tool, query: 'x'), and a keyword
  # here would swallow them.
  def call_tool(tool, args = {}, server_context = { base_url: 'http://test.host' })
    response = tool.call(server_context: server_context, **args)
    { error: response.error?, text: response.content.first[:text] }
  end

  def tool_payload(tool, args = {}, server_context = { base_url: 'http://test.host' })
    result = call_tool(tool, args, server_context)
    raise "tool returned an error: #{result[:text]}" if result[:error]

    JSON.parse(result[:text])
  end

  def tool_error(tool, args = {})
    result = call_tool(tool, args)
    raise "expected an error, got: #{result[:text]}" unless result[:error]

    result[:text]
  end
end

RSpec.configure do |config|
  config.include McpSpecHelpers
end
