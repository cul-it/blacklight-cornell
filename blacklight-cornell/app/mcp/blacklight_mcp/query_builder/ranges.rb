# frozen_string_literal: true

module BlacklightMcp
  class QueryBuilder
    # Start and end years on a range facet: the `date_range` shortcut, which
    # names publication year outright, and `ranges` for any other range facet.
    #
    # The catalog ignores a range missing either end, so both are required.
    class Ranges
      # ========================================================================
      # Initialize Arguments
      # ------------------------------------------------------------------------
      def initialize(args)
        @args = args
      end

      # ========================================================================
      # Every year range asked for, in the shape the catalog wants.
      # Empty when the caller asked for none.
      # ------------------------------------------------------------------------
      def to_h
        @to_h ||= requested.each_with_object({}) do |(field, bounds), result|
          result[field] = bounds_for(field, bounds)
        end
      end

      private

      attr_reader :args

      # ========================================================================
      # Gather date_range and ranges into one hash, so the same facet
      # being asked for twice is caught before either is read.
      # ------------------------------------------------------------------------
      def requested
        raw = {}
        raw[QueryBuilder::DATE_RANGE_FIELD] = args[:date_range] if args[:date_range].present?
        return raw if args[:ranges].blank?

        unless args[:ranges].is_a?(Hash)
          raise InvalidArgument, 'ranges must be an object of facet => { "begin": year, "end": year }'
        end

        args[:ranges].each do |name, bounds|
          field = FacetNames.resolve(name) || name.to_s
          if raw.key?(field)
            raise InvalidArgument, "#{FacetNames.public_name(field)} appears in both date_range " \
                                   'and ranges; use one or the other'
          end

          raw[field] = bounds
        end

        raw
      end

      # ========================================================================
      # Check one range: a real range facet, both years given, and the
      # start not later than the end.
      # ------------------------------------------------------------------------
      def bounds_for(field, bounds)
        name = FacetNames.public_name(field)

        unless CatalogOptions.range_facet_field?(field)
          raise InvalidArgument, "#{name.inspect} is not a range facet. " \
                                 "Range facets: #{FacetNames.public_range_names.map(&:inspect).join(', ')}"
        end

        raise InvalidArgument, "ranges[#{name}] must be an object with 'begin' and 'end'" unless bounds.is_a?(Hash)

        bounds = bounds.symbolize_keys
        first = year(bounds[:begin], "ranges[#{name}].begin")
        last = year(bounds[:end], "ranges[#{name}].end")

        if first > last
          raise InvalidArgument, "ranges[#{name}] begin (#{first}) must not be later than end (#{last})"
        end

        # Sent as text, exactly like the date range form does.
        { 'begin' => first.to_s, 'end' => last.to_s }
      end

      # ========================================================================
      # Read a year, or say plainly what was wrong with it.
      # ------------------------------------------------------------------------
      def year(value, label)
        if value.nil? || value.to_s.strip.empty?
          raise InvalidArgument, "#{label} is required (a range needs both a begin and an end)"
        end

        Integer(value.to_s.strip)
      rescue ArgumentError, TypeError
        raise InvalidArgument, "#{label} must be a whole year, e.g. 1966 (got #{value.inspect})"
      end
    end
  end
end
