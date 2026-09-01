# frozen_string_literal: true

module BlacklightMcp
  module Tools
    # The catalog's one-box search, with every filter, date range and sort the
    # website itself offers.
    class Search < Base
      tool_name 'search'
      read_only 'Search the library catalog'

      description <<~TEXT
        Search the Cornell University Library catalog. This is the single-search-box
        form: one query string against one search field, optionally narrowed by
        facets, a publication-year range, and a sort order.

        Use advanced_search instead when you need several query terms combined with
        AND/OR/NOT, or different fields per term.

        Multiple values for one facet are OR-ed. Leaving `query` empty is valid and
        returns everything matching the filters, which is a good way to browse a facet.
      TEXT

      input_schema(
        properties: {
          query: {
            type: 'string',
            description: 'Search terms. Quote a phrase to require it verbatim. May be empty to browse by filters alone.'
          },
          search_field: {
            type: 'string',
            description: 'Which index to search. Defaults to all_fields.',
            enum: CatalogOptions.search_field_keys
          }
        }.merge(filter_properties),
        required: [],
        additionalProperties: false
      )

      def self.call(server_context: nil, **args)
        handling_errors do
          run_search(QueryBuilder.simple(args), args, server_context)
        end
      end
    end
  end
end
