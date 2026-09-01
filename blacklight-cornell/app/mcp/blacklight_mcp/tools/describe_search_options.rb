# frozen_string_literal: true

module BlacklightMcp
  module Tools
    # Lists what this catalog can be asked for, read from its own settings, so
    # field names never have to be guessed.
    class DescribeSearchOptions < Base
      tool_name 'describe_search_options'
      read_only 'List catalog search fields, facets and sorts'

      description <<~TEXT
        List everything `search` and `advanced_search` accept: the search fields, the
        boolean and per-row operators, the facet fields, the range facets, and the sort
        orders -- all read from the running catalog configuration.

        By default it also samples the most-used values for the facets the catalog's own
        advanced form exposes (format, language, publication year), so you can pick real
        facet values instead of guessing at spelling.
      TEXT

      # How many example values to show per facet.
      SAMPLE_LIMIT = 25

      input_schema(
        properties: {
          include_facet_values: {
            type: 'boolean',
            description: 'Sample real values for the facets listed in CatalogOptions.facet_fields. Defaults to true.'
          },
          facet_fields: {
            type: 'array',
            items: { type: 'string', enum: CatalogOptions.facet_field_keys },
            description: 'Which facets to sample values for. Defaults to the facets on the advanced search form.'
          }
        },
        required: [],
        additionalProperties: false
      )

      def self.call(server_context: nil, **args)
        handling_errors do
          payload = {
            'search_fields' => described_search_fields,
            'advanced_search_fields' => CatalogOptions.advanced_search_fields.keys.map(&:to_s),
            'row_operators' => CatalogOptions::OPS,
            'row_booleans' => CatalogOptions::BOOLEANS,
            'sorts' => CatalogOptions.sort_options,
            'default_sort' => CatalogOptions.default_sort,
            'facet_fields' => described_facet_fields,
            'range_facet_fields' => CatalogOptions.range_facet_field_keys,
            'advanced_facet_fields' => CatalogOptions.advanced_facet_fields.keys.map(&:to_s)
          }

          payload['facet_values'] = facet_values(args[:facet_fields]) unless args[:include_facet_values] == false
          respond(payload)
        end
      end

      # Named for what it returns -- the description sent back to the AI,
      # not the settings CatalogOptions.search_fields hands over.
      def self.described_search_fields
        CatalogOptions.search_fields.map do |key, field|
          { 'search_field' => key.to_s,
            'label' => field.label.to_s,
            'in_advanced_form' => field.include_in_advanced_search != false }
        end
      end

      def self.described_facet_fields
        CatalogOptions.facet_fields.map do |key, field|
          entry = { 'facet_field' => key.to_s, 'label' => field.label.to_s }
          entry['type'] = 'range' if field.range
          entry['type'] = 'query' if field.query
          entry['values'] = field.query.keys.map(&:to_s) if field.query
          entry['in_advanced_form'] = true if field.include_in_advanced_search
          entry
        end
      end

      # One empty search returns the counts for every facet at once. That's
      # cheaper than asking about each facet separately, and the counts match
      # what the website shows.
      def self.facet_values(requested)
        fields = Array(requested).map(&:to_s).presence || CatalogOptions.advanced_facet_fields.keys.map(&:to_s)
        unknown = fields.reject { |field| CatalogOptions.facet_field?(field) }
        raise InvalidArgument, "unknown facet field(s): #{unknown.join(', ')}" if unknown.any?

        presented = ResultPresenter.new(sample_response, params: {}).to_h['facets']
        fields.each_with_object({}) do |field, result|
          result[field] = presented[field] if presented.key?(field)
        end
      end

      # Empty search: we only want the facet counts, not the records.
      def self.sample_response
        SearchRunner.new(q: '', search_field: 'all_fields', per_page: 1).search_results
      end
    end
  end
end
