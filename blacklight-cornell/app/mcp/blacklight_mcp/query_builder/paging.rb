# frozen_string_literal: true

module BlacklightMcp
  class QueryBuilder
    # Which slice of the results to ask for, and how far into them a caller is
    # allowed to reach.
    class Paging
      # ========================================================================
      # Initialize Arguments
      # ------------------------------------------------------------------------
      def initialize(args)
        @args = args
      end

      # ========================================================================
      # Page and per_page together, because the depth check needs both.
      # ------------------------------------------------------------------------
      def to_h
        @to_h ||= { page: page, per_page: per_page }.tap { |values| check_window!(values) }
      end

      private

      attr_reader :args

      # ========================================================================
      # Which page to ask for. The first one unless told otherwise.
      # ------------------------------------------------------------------------
      def page
        value = args[:page]
        return 1 if value.blank?

        page = integer(value, 'page')
        raise InvalidArgument, 'page must be 1 or greater' if page < 1

        page
      end

      # ========================================================================
      # How many results on a page, within what the catalog allows.
      # ------------------------------------------------------------------------
      def per_page
        value = args[:per_page]
        return QueryBuilder::DEFAULT_PER_PAGE if value.blank?

        per_page = integer(value, 'per_page')
        unless per_page.between?(1, QueryBuilder::MAX_PER_PAGE)
          raise InvalidArgument, "per_page must be between 1 and #{QueryBuilder::MAX_PER_PAGE} (got #{per_page})"
        end

        per_page
      end

      # ========================================================================
      # Refuse a page so deep that Solr would have to walk most of the
      # index to reach it. The message names the last page that works.
      # ------------------------------------------------------------------------
      def check_window!(values)
        window = QueryBuilder::MAX_RESULT_WINDOW
        page = values[:page]
        per_page = values[:per_page]
        last_record = page * per_page
        return if last_record <= window

        raise InvalidArgument,
              "page #{page} at per_page #{per_page} would reach record #{last_record}, past this catalog's " \
              "#{window}-record limit. The last page at per_page #{per_page} is #{window / per_page}. " \
              'To reach records beyond it, narrow the search with filters or a date range, or change ' \
              'sort so the records you want come nearer the front.'
      end

      # ========================================================================
      # Read a whole number, or say plainly that it was not one.
      # ------------------------------------------------------------------------
      def integer(value, label)
        Integer(value.to_s.strip)
      rescue ArgumentError, TypeError
        raise InvalidArgument, "#{label} must be a whole number (got #{value.inspect})"
      end
    end
  end
end
