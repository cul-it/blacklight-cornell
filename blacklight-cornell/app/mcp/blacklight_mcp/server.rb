# frozen_string_literal: true

module BlacklightMcp
  # Builds the MCP server. It offers tools and nothing else, so there's no
  # other way in.
  module Server
    NAME = 'cornell-library-catalog'

    # The only requests this endpoint answers. Anything else is refused, which
    # keeps a public, unauthenticated endpoint limited to reading the catalog.
    ALLOWED_METHODS = %w[
      initialize
      notifications/initialized
      ping
      server/discover
      tools/list
      tools/call
    ].freeze

    INSTRUCTIONS = <<~TEXT
      Read-only access to the Cornell University Library catalog.

      Call describe_search_options first if you are unsure which search field, facet, or
      sort to use -- it lists exactly what this catalog is configured with, plus sample
      facet values. Use search for a single query string and advanced_search when terms
      need to be combined with AND/OR/NOT or searched in different fields. facet_values
      finds the exact spelling of a facet value, and get_record pulls a full record.
    TEXT

    module_function

    def tools
      [
        Tools::Search,
        Tools::AdvancedSearch,
        Tools::DescribeSearchOptions,
        Tools::FacetValues,
        Tools::GetRecord
      ]
    end

    def build(base_url: nil)
      MCP::Server.new(
        name: NAME,
        title: 'Cornell University Library catalog',
        version: BlacklightMcp::VERSION,
        instructions: INSTRUCTIONS,
        tools: tools,
        capabilities: { tools: {} },
        server_context: { base_url: base_url }
      )
    end

    def allowed_method?(name)
      ALLOWED_METHODS.include?(name.to_s)
    end
  end
end
