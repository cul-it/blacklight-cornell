# frozen_string_literal: true

module BlacklightMcp
  class QueryBuilder
    # The /advanced form's rows: each one a query, the field to search it in and
    # how its words are matched, plus the booleans joining each row to the one
    # above it.
    #
    # The two arrays travel together because they have to line up: `booleans` is
    # always exactly one shorter than the rows.
    class Rows
      DEFAULT_OP = 'AND'
      DEFAULT_BOOLEAN = 'AND'

      # ========================================================================
      # Initialize Arguments
      # ------------------------------------------------------------------------
      def initialize(args)
        @args = args
      end

      # ========================================================================
      # The rows, checked and tidied, in the order given.
      # ------------------------------------------------------------------------
      def to_a
        @to_a ||= given.each_with_index.map { |row, index| row_for(row, index) }
      end

      # ========================================================================
      # The words joining each row to the one above it.
      # ------------------------------------------------------------------------
      def booleans
        @booleans ||= booleans_for(to_a.size)
      end

      private

      attr_reader :args

      # ========================================================================
      # The rows as the caller sent them, refused if missing or if there
      # are more than the form allows.
      # ------------------------------------------------------------------------
      def given
        rows = args[:rows]
        unless rows.is_a?(Array) && rows.any?
          raise InvalidArgument, 'rows must be a non-empty array of search rows, e.g. ' \
                                 '[{ "query": "batman", "field": "all_fields", "op": "AND" }]'
        end

        if rows.size > QueryBuilder::MAX_ADVANCED_ROWS
          raise InvalidArgument, "rows accepts at most #{QueryBuilder::MAX_ADVANCED_ROWS} rows (got #{rows.size})"
        end

        rows
      end

      # ========================================================================
      # One row: the words to look for, the field to look in, and how
      # those words should be matched.
      # ------------------------------------------------------------------------
      def row_for(row, index)
        raise InvalidArgument, "rows[#{index}] must be an object with a 'query' key" unless row.is_a?(Hash)

        query = QueryBuilder.clean_query(row[:query].to_s)
        if query.blank?
          raise InvalidArgument, "rows[#{index}].query is required and cannot be blank; " \
                                 'omit the row entirely instead of sending an empty one'
        end

        { query: query,
          field: QueryBuilder.search_field_for(row[:field], "rows[#{index}].field"),
          op: op_for(row[:op], "rows[#{index}].op") }
      end

      # ========================================================================
      # The joining words. AND unless told otherwise, and always exactly
      # one fewer than the rows.
      # ------------------------------------------------------------------------
      def booleans_for(row_count)
        expected = [row_count - 1, 0].max
        given = args[:booleans]

        return Array.new(expected, DEFAULT_BOOLEAN) if given.nil?

        unless given.is_a?(Array)
          raise InvalidArgument, "booleans must be an array of #{CatalogOptions::BOOLEANS.join('/')} values"
        end

        if given.size != expected
          raise InvalidArgument, 'booleans must have exactly one fewer entry than rows ' \
                                 "(expected #{expected} for #{row_count} row(s), got #{given.size})"
        end

        given.each_with_index.map { |boolean, index| boolean_for(boolean, index) }
      end

      # ========================================================================
      # Check one joining word is AND, OR or NOT.
      # ------------------------------------------------------------------------
      def boolean_for(boolean, index)
        value = boolean.to_s.strip.upcase
        unless CatalogOptions::BOOLEANS.include?(value)
          raise InvalidArgument, "booleans[#{index}] must be one of " \
                                 "#{CatalogOptions::BOOLEANS.join(', ')} (got #{boolean.inspect})"
        end

        value
      end

      # ========================================================================
      # Check how a row's words should be matched.
      # ------------------------------------------------------------------------
      def op_for(value, label)
        return DEFAULT_OP if value.blank?

        op = value.to_s.strip
        unless CatalogOptions::OPS.key?(op)
          raise InvalidArgument, "#{label} must be one of #{CatalogOptions::OPS.keys.join(', ')} (got #{value.inspect})"
        end

        op
      end
    end
  end
end
