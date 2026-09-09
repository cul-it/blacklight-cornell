# frozen_string_literal: true

module BlacklightMcp
  # Turns a tool's arguments into the same URL parameters the catalog's own
  # search forms submit. For the advanced form that looks like:
  #
  #   { advanced_query: 'yes', search_field: 'advanced', q: '',
  #     q_row: %w[batman Robin], op_row: %w[AND OR],
  #     search_field_row: %w[all_fields journaltitle],
  #     boolean_row: { '1' => 'NOT' },
  #     f_inclusive: { 'format' => ['Book'] },
  #     range: { 'pub_date_facet' => { 'begin' => '1966', 'end' => '2025' } },
  #     sort: 'score desc, pub_date_sort desc, title_sort asc' }
  #
  # If an argument doesn't match a real field, it raises InvalidArgument with a
  # message listing what is valid, so the AI can fix it and try again.
  class QueryBuilder

    DEFAULT_PER_PAGE  = 20
    MAX_PER_PAGE      = 100
    MAX_ADVANCED_ROWS = 10
    MAX_QUERY_LENGTH  = 1_000
    MAX_RESULT_WINDOW = 10_000 # Prevents anything past MAX_RESULT_WINDOW to prevent heavy Solr queries
    DEFAULT_SEARCH_FIELD = 'all_fields'
    # The facets the shortcut arguments point at.
    FORMAT_FIELD = 'format'
    LANGUAGE_FIELD = 'language_facet'
    DATE_RANGE_FIELD = 'pub_date_facet'

    class << self
      # ========================================================================
      # Entry point for a plain one-box search.
      # ------------------------------------------------------------------------
      def simple(args = {})
        new(args).simple
      end

      # ========================================================================
      # Entry point for a multi-row search, the /advanced form.
      # ------------------------------------------------------------------------
      def advanced(args = {})
        new(args).advanced
      end

      # ========================================================================
      # Check a field name is one the catalog really has. Used by the
      # one-box search and by every advanced row.
      # ------------------------------------------------------------------------
      def search_field_for(value, label = 'search_field')
        return DEFAULT_SEARCH_FIELD if value.blank?

        field = value.to_s.strip
        unless CatalogOptions.search_field?(field)
          raise InvalidArgument, "#{label} #{field.inspect} is not a configured search field. " \
                                 "Valid values: #{CatalogOptions.search_field_keys.join(', ')}"
        end

        field
      end

      # ========================================================================
      # Tidy the search words and refuse one that is absurdly long.
      # Escaping is the catalog's job, not ours.
      # ------------------------------------------------------------------------
      def clean_query(query)
        query = query.to_s.strip
        if query.length > MAX_QUERY_LENGTH
          raise InvalidArgument, "query must be #{MAX_QUERY_LENGTH} characters or fewer (got #{query.length})"
        end

        query
      end
    end

    # ==========================================================================
    # Take the caller's arguments and use symbol keys from here on.
    # --------------------------------------------------------------------------
    def initialize(args = {})
      @args = normalize_args(args)
    end

    # ==========================================================================
    # The finished parameters for a one-box search.
    # --------------------------------------------------------------------------
    def simple
      base.merge(
        q: self.class.clean_query(args[:query].to_s),
        search_field: self.class.search_field_for(args[:search_field])
      )
    end

    # ==========================================================================
    # The finished parameters for an advanced search: the shared ones,
    # plus one entry per row and the words joining the rows together.
    # --------------------------------------------------------------------------
    def advanced
      rows = Rows.new(args)

      base.merge(
        advanced_query: 'yes',
        search_field: 'advanced',
        # The advanced form always sends an empty q next to the rows. The search code drops it once it sees the rows.
        q: '',
        q_row: rows.to_a.map { |row| row[:query] },
        op_row: rows.to_a.map { |row| row[:op] },
        search_field_row: rows.to_a.map { |row| row[:field] },
        # boolean_row starts at 1, and each entry joins a row to the one before it.
        boolean_row: rows.booleans.each_with_index.to_h { |boolean, i| [(i + 1).to_s, boolean] }
      )
    end

    private

    attr_reader :args

    # ==========================================================================
    # The facet filters, worked out once and reused.
    # --------------------------------------------------------------------------
    def filters
      @filters ||= Filters.new(args)
    end

    # ==========================================================================
    # The year ranges, worked out once and reused.
    # --------------------------------------------------------------------------
    def ranges
      @ranges ||= Ranges.new(args)
    end

    # ==========================================================================
    # Turn the caller's sort into the catalog's own, or nil when they
    # did not ask for one.
    # --------------------------------------------------------------------------
    def sort
      return @sort if defined?(@sort)

      given = args[:sort]
      return @sort = nil if given.blank?

      normalized = CatalogOptions.normalize_sort(given)
      unless normalized
        raise InvalidArgument, "sort #{given.inspect} is not a configured sort. Valid values (key or label): " +
                               CatalogOptions.sort_options.map { |o| "#{o['sort']} (#{o['label']})" }.join('; ')
      end

      @sort = normalized
    end

    # ==========================================================================
    # The parts every search shares: filters, ranges, sort and paging.
    # --------------------------------------------------------------------------
    def base
      params = {}
      params[:f] = filters.conjunctive if filters.conjunctive.present?
      params[:f_inclusive] = filters.inclusive if filters.inclusive.present?
      params[:range] = ranges.to_h if ranges.to_h.present?
      params[:sort] = sort if sort
      params.merge(Paging.new(args).to_h)
    end

    # ==========================================================================
    # Accept string or symbol keys from the caller, and settle on
    # symbols so the rest of the class only deals with one shape.
    # --------------------------------------------------------------------------
    def normalize_args(args)
      raise InvalidArgument, 'arguments must be an object' unless args.nil? || args.is_a?(Hash)

      (args || {}).each_with_object({}) do |(key, value), result|
        result[key.to_sym] = value.is_a?(Hash) ? value.symbolize_keys : value
      end
    end
  end
end
