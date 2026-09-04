# frozen_string_literal: true

module BlacklightMcp
  module Tools
    # Shared pieces every catalog tool uses: the argument descriptions for
    # filtering, sorting and paging (built from the catalog's live settings), one
    # reply format, and error handling that returns a message the AI can
    # act on instead of a hard failure.
    class Base < MCP::Tool

      class << self
        # Every tool here only reads. Nothing writes.
        def read_only(title)
          annotations(
            title: title,
            read_only_hint: true,
            destructive_hint: false,
            idempotent_hint: true,
            open_world_hint: false
          )
        end

        # Filter, date range, sort and paging arguments. `search` and
        # `advanced_search` share these, so both accept the same words.
        def filter_properties
          {
            formats: {
              type: 'array',
              items: { type: 'string' },
              # Which facet these values come from, said once in a form a client
              # can act on. The description says the same in prose, and reading a
              # list back out of prose is how one ends up in the wrong place.
              # JSON Schema ignores keywords it does not recognise.
              'x-facet': FacetNames.public_name(QueryBuilder::FORMAT_FIELD),
              description: "Shortcut for filters[#{FacetNames.public_name(QueryBuilder::FORMAT_FIELD).inspect}]. " \
                           'Values are OR-ed, e.g. ["Book", "Journal/Periodical"]. ' \
                           'Use describe_search_options to see the available values.'
            },
            languages: {
              type: 'array',
              items: { type: 'string' },
              'x-facet': FacetNames.public_name(QueryBuilder::LANGUAGE_FIELD),
              description: "Shortcut for filters[#{FacetNames.public_name(QueryBuilder::LANGUAGE_FIELD).inspect}]. " \
                           'Values are OR-ed, e.g. ["English", "German"].'
            },
            filters: {
              type: 'object',
              description: 'Facet => array of values. Multiple values for one facet are OR-ed ' \
                           '(a record matching any of them is kept), which is what the catalog\'s facet ' \
                           'checkboxes do. Range facets are not accepted here; use date_range/ranges. ' \
                           "Facets: #{FacetNames.public_names.map(&:inspect).join(', ')}.",
              propertyNames: { enum: FacetNames.public_names },
              additionalProperties: { type: 'array', items: { type: 'string' } }
            },
            filters_all: {
              type: 'object',
              description: 'Facet => array of values, AND-ed instead of OR-ed: a record must carry ' \
                           'every listed value. Use this only when you really mean "all of these at once". ' \
                           "Same facets as filters.",
              propertyNames: { enum: FacetNames.public_names },
              additionalProperties: { type: 'array', items: { type: 'string' } }
            },
            date_range: {
              type: 'object',
              description: "Publication-year limit: the #{FacetNames.public_name(QueryBuilder::DATE_RANGE_FIELD).inspect} " \
                           'range facet. Both bounds are required -- the catalog ignores a half-open range.',
              properties: {
                begin: { type: 'integer', description: 'Earliest publication year, e.g. 1966' },
                end: { type: 'integer', description: 'Latest publication year, e.g. 2025' }
              },
              required: %w[begin end],
              additionalProperties: false
            },
            ranges: {
              type: 'object',
              description: 'Range facets other than the one date_range covers, facet => { begin, end }. ' \
                           "Configured: #{other_range_names.map(&:inspect).join(', ')}.",
              propertyNames: { enum: other_range_names },
              additionalProperties: {
                type: 'object',
                properties: { begin: { type: 'integer' }, end: { type: 'integer' } },
                required: %w[begin end],
                additionalProperties: false
              }
            },
            sort: {
              type: 'string',
              description: 'Result ordering. Accepts the sort key or its label ' +
                           CatalogOptions.sort_options.map { |o| "#{o['label']}" }.join(', ') + '.',
              enum: CatalogOptions.sort_field_keys + CatalogOptions.sort_options.map { |o| o['label'] }
            },
            page: {
              type: 'integer',
              minimum: 1,
              description: 'Result page, 1-based. page x per_page cannot reach past record ' \
                           "#{QueryBuilder::MAX_RESULT_WINDOW}; to go further, narrow the search or change sort."
            },
            per_page: {
              type: 'integer',
              minimum: 1,
              maximum: QueryBuilder::MAX_PER_PAGE,
              description: "Results per page (default #{QueryBuilder::DEFAULT_PER_PAGE}, max #{QueryBuilder::MAX_PER_PAGE})."
            },
            explain: {
              type: 'boolean',
              description: 'When true, return the catalog and Solr parameters this call would produce ' \
                           'without running the search. Useful for checking a query before spending a request.'
            }
          }.tap { |properties| properties.delete(:ranges) if other_range_names.empty? }
        end

        # date_range and ranges both set a start and end on a range facet.
        # date_range names one outright; ranges is the general form for the
        # others. When there are no others -- and this catalog has exactly one
        # range facet, publication year -- ranges can only duplicate date_range,
        # and offering both invites the "appears in both" error for no gain. It
        # is not removed, only unadvertised: a caller already sending it still
        # works, and configuring a second range facet brings it back on its own.
        def other_range_names
          FacetNames.public_names(
            CatalogOptions.range_facet_field_keys - [QueryBuilder::DATE_RANGE_FIELD]
          )
        end

        # Runs the search and formats the reply. With `explain`, describes the
        # search instead of running it.
        def run_search(params, args, server_context)
          runner = SearchRunner.new(params)

          return respond(explain_payload(params, runner)) if truthy?(args[:explain])

          response = runner.search_results
          respond(ResultPresenter.new(response, params: params, base_url: base_url(server_context)).to_h)
        end

        def explain_payload(params, runner)
          {
            'explain' => true,
            'catalog_params' => params,
            'solr_params' => runner.solr_params.deep_stringify_keys
          }
        end

        def respond(payload)
          MCP::Tool::Response.new([{ type: 'text', text: JSON.pretty_generate(payload) }])
        end

        # The AI sees this message and can fix its arguments.
        def failure(message)
          MCP::Tool::Response.new([{ type: 'text', text: message }], error: true)
        end

        def handling_errors
          yield
        rescue InvalidArgument, NotFound => e
          failure(e.message)
        rescue Blacklight::Exceptions::InvalidRequest, RSolr::Error::Http => e
          Rails.logger.warn("[mcp] solr rejected request: #{e.message}")
          failure('The catalog could not run that search. Try simplifying the query or removing filters.')
        rescue Blacklight::Exceptions::RepositoryTimeout, Blacklight::Exceptions::ECONNREFUSED => e
          # Only the class name: these messages embed the Solr connection, which
          # can carry credentials.
          Rails.logger.warn("[mcp] solr unavailable: #{e.class}")
          failure('The catalog took too long to answer. Try a narrower search, or try again in a moment.')
        end

        def base_url(server_context)
          server_context.respond_to?(:[]) ? server_context[:base_url] : nil
        end

        def truthy?(value)
          [true, 'true', 1, '1'].include?(value)
        end
      end
    end
  end
end
