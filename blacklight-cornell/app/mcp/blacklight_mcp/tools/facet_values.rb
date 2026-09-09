# frozen_string_literal: true

module BlacklightMcp
  module Tools
    # Lists all the values for one facet, not just the few the sidebar shows.
    class FacetValues < Base
      tool_name 'facet_values'
      read_only 'List the values of one catalog facet'

      description <<~TEXT
        List the values available for a single facet field, with counts -- the catalog's
        "more" facet view. Use it to find the exact spelling of a facet value before
        filtering on it (e.g. every language, or every format).

        The listing is scoped by the same query and filters `search` accepts, so you can
        ask "which languages appear among books about Rome" as well as "which languages
        exist at all".
      TEXT

      # ========================================================================
      # The arguments this tool takes, as JSON Schema.
      #
      # Two jobs:
      # 1. The client shows it to the AI so it knows what to send.
      # 2. The client checks a call against it before the tool ever runs.
      #    bad arguments fail early.
      #
      # Every list of allowed values is read from the catalog's live settings,
      # so adding a facet in catalog_controller.rb shows up here with no edit.
      # ------------------------------------------------------------------------
      input_schema(
        properties: {
          # enum
          field: {
            type: 'string',
            description: 'The facet to list.',
            enum: FacetNames.public_names
          },
          query: {
            type: 'string',
            description: 'Optional search terms scoping the facet counts.'
          },
          search_field: {
            type: 'string',
            enum: CatalogOptions.search_field_keys
          },
          formats: {
            type: 'array',
            items: { type: 'string' },
            'x-facet': FacetNames.public_name(QueryBuilder::FORMAT_FIELD)
          },
          languages: {
            type: 'array', items: { type: 'string' },
            'x-facet': FacetNames.public_name(QueryBuilder::LANGUAGE_FIELD)
          },
          filters: {
            type: 'object',
            propertyNames: { enum: FacetNames.public_names },
            additionalProperties: { type: 'array', items: { type: 'string' } }
          },
          filters_all: {
            type: 'object',
            propertyNames: { enum: FacetNames.public_names },
            additionalProperties: { type: 'array', items: { type: 'string' } }
          },
          date_range: {
            type: 'object',
            properties: { begin: { type: 'integer' }, end: { type: 'integer' } },
            required: %w[begin end],
            additionalProperties: false
          },
          prefix: {
            type: 'string',
            description: 'Only values starting with this prefix.'
          },
          parent: {
            type: 'string',
            description: 'For a facet whose values are paths, like Call Number: list what sits ' \
              'directly under this value, e.g. "A - General". Leave it out for the ' \
              'top level.'
          },
          sort: {
            type: 'string',
            enum: %w[count index],
            description: '"count" for most-used first (default), "index" for alphabetical.'
          },
          page: {
            type: 'integer',
            minimum: 1,
            description: 'Page of facet values, 1-based. Paging cannot reach past value ' \
              "#{QueryBuilder::MAX_RESULT_WINDOW}; use prefix to jump instead."
          }
        },
        required: %w[field], # Only `field` must be sent.
        additionalProperties: false # Anything not listed above is rejected, so typos fails loudly instead of being silently ignored.
      )

      def self.call(server_context: nil, **args)
        handling_errors do
          field = resolved_field(args[:field])

          separator = CatalogOptions.hierarchy_separator(field)
          return respond(one_level(field, separator, args)) if separator

          runner = SearchRunner.new(facet_params(field, args))
          response = runner.facet_results(field)
          respond(payload(field, response, args))
        end
      end

      # Takes the name the caller used and gives back the Solr field, or explains
      # what it could have said instead.
      def self.resolved_field(value)
        field = FacetNames.resolve(value)
        unless field
          raise InvalidArgument, "#{value.to_s.inspect} is not a facet in this catalog. " \
                                 "Valid values: #{FacetNames.public_names.map(&:inspect).join(', ')}"
        end

        if CatalogOptions.range_facet_field?(field)
          raise InvalidArgument, "#{FacetNames.public_name(field)} is a range facet and has no discrete " \
                                 'values; search with date_range instead, and read min/max off the ' \
                                 'search response.'
        end

        field
      end

      # The search that narrows the counts, plus the paging arguments. Careful:
      # `sort` here orders the facet values, not the search results, so it must
      # not be passed along as a result sort.
      def self.facet_params(field, args)
        params = QueryBuilder.simple(args.except(:sort, :page, :per_page, :field, :prefix))
        params[:'facet.page'] = checked_page(field, args[:page]) if args[:page].present?
        params[:'facet.sort'] = args[:sort] if args[:sort].present?
        params[:'facet.prefix'] = args[:prefix] if args[:prefix].present?
        params
      end

      # Facet paging becomes a Solr facet.offset, which is walked the same way a
      # deep result page is, so it gets the same window. `prefix` is the cheap
      # way to reach a value far down the list.
      def self.checked_page(field, value)
        page = Integer(value.to_s.strip)
        raise InvalidArgument, 'page must be 1 or greater' if page < 1

        limit = more_limit(field).to_i
        return page if limit <= 0 || page * limit <= QueryBuilder::MAX_RESULT_WINDOW

        raise InvalidArgument,
              "page #{page} would reach facet value #{page * limit}, past this catalog's " \
              "#{QueryBuilder::MAX_RESULT_WINDOW}-value limit. The last page for " \
              "#{FacetNames.public_name(field)} is " \
              "#{QueryBuilder::MAX_RESULT_WINDOW / limit}. Use prefix to jump to the values you want, " \
              'or scope the counts with a query and filters.'
      rescue ArgumentError, TypeError
        raise InvalidArgument, "page must be a whole number (got #{value.inspect})"
      end

      # Call Number is one long flat list -- thousands of values, only twenty of
      # them top level. Return one level at a time instead, the way the dropdown does.
      def self.one_level(field, separator, args)
        parent = args[:parent].to_s.strip.presence
        params = facet_params(field, args.except(:parent))
        params[:'facet.prefix'] = "#{parent}#{separator}" if parent
        # No paging: one level is short, and Solr would page the whole flat list.
        params.delete(:'facet.page')

        response = SearchRunner.new(params).facet_results(field, :"f.#{field}.facet.limit" => -1)

        { 'facet' => FacetNames.public_name(field),
          'label' => CatalogOptions.label_for_facet(field),
          'parent' => parent,
          'values' => children_of(response, field, parent, separator) }.compact
      end

      # Keep only the level asked for: no separator for the top, one more than
      # the parent for its children.
      def self.children_of(response, field, parent, separator)
        depth = parent ? parent.split(separator).length : 0

        Array(response.aggregations[field]&.items).filter_map do |item|
          value = item.value.to_s
          next unless value.split(separator).length == depth + 1

          { 'value' => value, 'count' => item.hits.to_i }
        end
      end

      def self.payload(field, response, args)
        limit = more_limit(field)
        # The catalog asks for one more value than it needs so it can tell
        # whether another page exists. Drop that extra one here.
        items = Array(response.aggregations[field]&.items)
        page = [args[:page].to_i, 1].max

        {
          'facet' => FacetNames.public_name(field),
          'label' => CatalogOptions.label_for_facet(field),
          'page' => page,
          'per_page' => limit,
          'has_more' => items.size > limit,
          'values' => items.first(limit).map { |item| { 'value' => item.value.to_s, 'count' => item.hits.to_i } }
        }
      end

      def self.more_limit(field)
        field_config = CatalogOptions.facet_fields[field]
        field_config.fetch(:more_limit, CatalogOptions.blacklight_config.default_more_limit)
      end
    end
  end
end
