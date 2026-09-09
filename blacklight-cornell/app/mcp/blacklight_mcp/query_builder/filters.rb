# frozen_string_literal: true

module BlacklightMcp
  class QueryBuilder
    # Turns the facet filters a caller sends -- filters, filters_all and the
    # formats and languages shortcuts -- into the Solr fields Blacklight uses.
    class Filters

      MAX_VALUES = 50 # Each facet value becomes its own Solr subquery, so a long list is real work for Solr.
      MAX_VALUE_LENGTH = 255 # Facet values are terms like "Journal/Periodical", not free text. `query` has its own, much longer limit.

      # ========================================================================
      # Initialize Arguments
      # ------------------------------------------------------------------------
      def initialize(args)
        @args = args
      end

      # ========================================================================
      # Values matched as "any of these" -- a record needs only one of
      # them. This is what ticking several boxes on the site does.
      # ------------------------------------------------------------------------
      def inclusive
        @inclusive ||= begin
          raw = from(args[:filters], 'filters')
          raw = merge(raw, QueryBuilder::FORMAT_FIELD, args[:formats], 'formats')
          raw = merge(raw, QueryBuilder::LANGUAGE_FIELD, args[:languages], 'languages')
          validate(raw, 'filters')
        end
      end



      # ========================================================================
      # Values matched as "all of these" -- a record needs every one.
      # Refuses a facet that was also given to `inclusive`.
      # ------------------------------------------------------------------------
      def conjunctive
        @conjunctive ||= begin
          raw = validate(from(args[:filters_all], 'filters_all'), 'filters_all')
          overlap = raw.keys & inclusive.keys
          if overlap.any?
            raise InvalidArgument, "#{FacetNames.public_names(overlap).join(', ')} appears in both " \
                                   'filters and filters_all; use one or the other for a given facet'
          end

          raw
        end
      end

      private

      attr_reader :args

      # ========================================================================
      # Read one filters hash: turn each facet name into the Solr field
      # behind it. Two spellings of the same facet become one filter.
      # ------------------------------------------------------------------------
      def from(value, label)
        return {} if value.blank?
        raise InvalidArgument, "#{label} must be an object of facet => array of values" unless value.is_a?(Hash)

        value.each_with_object({}) do |(name, values), result|
          field = FacetNames.resolve(name)
          unless field
            raise InvalidArgument, "#{label} contains unknown facet #{name.to_s.inspect}. " \
                                   "Valid facets: #{FacetNames.public_names.map(&:inspect).join(', ')}"
          end

          result[field] = Array.wrap(result[field]) + Array.wrap(values)
        end
      end

      # ========================================================================
      # Fold a shortcut argument (formats, languages) into the filters,
      # as if the caller had written it out longhand.
      # ------------------------------------------------------------------------
      def merge(filters, field, values, label)
        return filters if values.blank?

        unless values.is_a?(Array) || values.is_a?(String)
          raise InvalidArgument, "#{label} must be an array of facet values"
        end

        filters.merge(field => Array.wrap(filters[field]) + Array.wrap(values))
      end

      # ========================================================================
      # Check every filter's values, naming the facet the way the caller
      # wrote it rather than the way Solr stores it.
      # ------------------------------------------------------------------------
      def validate(filters, label)
        filters.each_with_object({}) do |(field, values), result|
          name = FacetNames.public_name(field)
          reject_range_facet(field, name, label)

          values = Array.wrap(values).map { |value| value.to_s.strip }.reject(&:blank?)
          check_values(values, name, label)

          result[field] = values
        end
      end

      # ========================================================================
      # A year range is not a pick-a-value facet, so point the caller at
      # date_range or ranges instead.
      # ------------------------------------------------------------------------
      def reject_range_facet(field, name, label)
        return unless CatalogOptions.range_facet_field?(field)

        with = field == QueryBuilder::DATE_RANGE_FIELD ? 'date_range' : "ranges[#{name}]"
        raise InvalidArgument, "#{name} is a range facet; filter it with #{with} " \
                               '(begin/end), not with ' + label
      end

      # ========================================================================
      # Refuse an empty list, more values than any real search uses, or
      # a value far too long to be a facet value.
      # ------------------------------------------------------------------------
      def check_values(values, name, label)
        raise InvalidArgument, "#{label}[#{name}] must contain at least one non-blank value" if values.empty?

        if values.length > MAX_VALUES
          raise InvalidArgument, "#{label}[#{name}] accepts at most #{MAX_VALUES} values " \
                                 "(got #{values.length}). Use fewer, or drop the filter and narrow the query."
        end

        too_long = values.find { |value| value.length > MAX_VALUE_LENGTH }
        return unless too_long

        raise InvalidArgument, "#{label}[#{name}] has a value of #{too_long.length} characters; " \
                               "facet values are at most #{MAX_VALUE_LENGTH}. " \
                               'Use facet_values to find the exact value you want.'
      end
    end
  end
end
