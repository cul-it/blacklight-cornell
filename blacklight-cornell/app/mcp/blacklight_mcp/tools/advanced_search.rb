# frozen_string_literal: true

module BlacklightMcp
  module Tools
    # The catalog's /advanced page: several search rows, each with its own field
    # and match type, joined by AND/OR/NOT.
    class AdvancedSearch < Base
      tool_name 'advanced_search'
      read_only 'Advanced (boolean) catalog search'

      description <<~TEXT
        Search the Cornell University Library catalog with several query rows combined
        by boolean operators -- the catalog's /advanced form.

        Each row has its own `query`, `field`, and `op`:
          * op "AND"         - the row matches records containing all of its words (default)
          * op "OR"          - the row matches records containing any of its words
          * op "phrase"      - the row must match as an exact phrase
          * op "begins_with" - the row is a left-anchored prefix match

        `booleans` joins the rows and must have exactly one fewer entry than `rows`:
        booleans[0] joins rows[0] to rows[1], booleans[1] joins rows[1] to rows[2],
        and so on. Rows are combined left to right, so
        rows A, B, C with booleans ["AND", "OR"] means ((A AND B) OR C).

        Facets, date_range, and sort work exactly as they do in `search`.
      TEXT

      input_schema(
        properties: {
          rows: {
            type: 'array',
            minItems: 1,
            maxItems: QueryBuilder::MAX_ADVANCED_ROWS,
            description: 'The query rows, in order.',
            items: {
              type: 'object',
              properties: {
                query: { type: 'string', minLength: 1, description: 'Search terms for this row. Cannot be blank.' },
                field: {
                  type: 'string',
                  description: 'Which index this row searches. Defaults to all_fields.',
                  enum: CatalogOptions.search_field_keys
                },
                op: {
                  type: 'string',
                  description: CatalogOptions::OPS.map { |op, label| "#{op} = #{label}" }.join('; '),
                  enum: CatalogOptions::OPS.keys
                }
              },
              required: %w[query],
              additionalProperties: false
            }
          },
          booleans: {
            type: 'array',
            description: 'Operators joining consecutive rows. Length must be rows.length - 1. Defaults to all AND.',
            items: { type: 'string', enum: CatalogOptions::BOOLEANS }
          }
        }.merge(filter_properties),
        required: %w[rows],
        additionalProperties: false
      )

      def self.call(server_context: nil, **args)
        handling_errors do
          run_search(QueryBuilder.advanced(args), args, server_context)
        end
      end
    end
  end
end
