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

    DEFAULT_PER_PAGE = 20
    MAX_PER_PAGE = 100
    MAX_ADVANCED_ROWS = 10
    MAX_QUERY_LENGTH = 1_000

    # How far into a result set a request may reach. Solr walks every row it
    # skips, so page 50,000 costs the whole index no matter how narrow the query
    # is -- the cheapest way there is to knock the catalog over. Nobody reads
    # their way to record 10,000 either: past that, the answer is a better
    # search, not another page.
    MAX_RESULT_WINDOW = 10_000

    # Each facet value becomes its own Solr subquery, so a long list is real work
    # for Solr. No genuine search picks 50 formats or 50 languages; a list that
    # long means the caller is filtering by the wrong thing.
    MAX_FILTER_VALUES = 50

    # Facet values are terms like "Journal/Periodical", not free text. `query`
    # already has its own, much longer limit.
    MAX_FILTER_VALUE_LENGTH = 255

    DEFAULT_SEARCH_FIELD = 'all_fields'
    DEFAULT_OP = 'AND'
    DEFAULT_BOOLEAN = 'AND'

    # The facets the shortcut arguments point at.
    FORMAT_FIELD = 'format'
    LANGUAGE_FIELD = 'language_facet'
    DATE_RANGE_FIELD = 'pub_date_facet'

    class << self
      # Parameters for a one-box search (the catalog's basic search form).
      def simple(args = {})
        new(args).simple
      end

      # Parameters for a multi-row search (the /advanced form).
      def advanced(args = {})
        new(args).advanced
      end
    end

    def initialize(args = {})
      @args = normalize_args(args)
    end

    def simple
      base.merge(
        q: clean_query(@args[:query].to_s),
        search_field: search_field_for(@args[:search_field], DEFAULT_SEARCH_FIELD)
      )
    end

    def advanced
      rows = advanced_rows
      booleans = advanced_booleans(rows.size)

      base.merge(
        advanced_query: 'yes',
        search_field: 'advanced',
        # The advanced form always sends an empty q next to the rows. The search
        # code drops it once it sees the rows.
        q: '',
        q_row: rows.map { |row| row[:query] },
        op_row: rows.map { |row| row[:op] },
        search_field_row: rows.map { |row| row[:field] },
        # boolean_row starts at 1, and each entry joins a row to the one before
        # it. That's the numbering the catalog's own form uses.
        boolean_row: booleans.each_with_index.to_h { |boolean, i| [(i + 1).to_s, boolean] }
      )
    end

    private

    attr_reader :args

    # Filters, date ranges, sorting and paging work the same for both searches.
    def base
      params = {}
      params[:f] = conjunctive_filters if conjunctive_filters.present?
      params[:f_inclusive] = inclusive_filters if inclusive_filters.present?
      params[:range] = ranges if ranges.present?
      params[:sort] = sort if sort
      params[:page] = page
      params[:per_page] = per_page
      check_result_window!(params[:page], params[:per_page])
      params
    end

    # --- advanced rows ------------------------------------------------------

    def advanced_rows
      rows = args[:rows]
      raise InvalidArgument, 'rows must be a non-empty array of search rows, e.g. ' \
                             '[{ "query": "batman", "field": "all_fields", "op": "AND" }]' unless rows.is_a?(Array) && rows.any?

      if rows.size > MAX_ADVANCED_ROWS
        raise InvalidArgument, "rows accepts at most #{MAX_ADVANCED_ROWS} rows (got #{rows.size})"
      end

      rows.each_with_index.map { |row, index| advanced_row(row, index) }
    end

    def advanced_row(row, index)
      unless row.is_a?(Hash)
        raise InvalidArgument, "rows[#{index}] must be an object with a 'query' key"
      end

      query = clean_query(row[:query].to_s)
      if query.blank?
        raise InvalidArgument, "rows[#{index}].query is required and cannot be blank; " \
                               'omit the row entirely instead of sending an empty one'
      end

      { query: query,
        field: search_field_for(row[:field], DEFAULT_SEARCH_FIELD, "rows[#{index}].field"),
        op: op_for(row[:op], "rows[#{index}].op") }
    end

    def advanced_booleans(row_count)
      expected = [row_count - 1, 0].max
      given = args[:booleans]

      return Array.new(expected, DEFAULT_BOOLEAN) if given.nil?

      unless given.is_a?(Array)
        raise InvalidArgument, "booleans must be an array of #{CatalogOptions::BOOLEANS.join('/')} values"
      end

      if given.size != expected
        raise InvalidArgument, "booleans must have exactly one fewer entry than rows " \
                               "(expected #{expected} for #{row_count} row(s), got #{given.size})"
      end

      given.each_with_index.map do |boolean, index|
        value = boolean.to_s.strip.upcase
        unless CatalogOptions::BOOLEANS.include?(value)
          raise InvalidArgument, "booleans[#{index}] must be one of #{CatalogOptions::BOOLEANS.join(', ')} (got #{boolean.inspect})"
        end

        value
      end
    end

    def op_for(value, label)
      return DEFAULT_OP if value.blank?

      op = value.to_s.strip
      unless CatalogOptions::OPS.key?(op)
        raise InvalidArgument, "#{label} must be one of #{CatalogOptions::OPS.keys.join(', ')} (got #{value.inspect})"
      end

      op
    end

    def search_field_for(value, default, label = 'search_field')
      return default if value.blank?

      field = value.to_s.strip
      unless CatalogOptions.search_field?(field)
        raise InvalidArgument, "#{label} #{field.inspect} is not a configured search field. " \
                               "Valid values: #{CatalogOptions.search_field_keys.join(', ')}"
      end

      field
    end

    # --- filters ------------------------------------------------------------

    # Several values for one facet, matched as "any of these". A record needs
    # only one of them. This is what the advanced form's checkboxes do, and what
    # someone almost always means by "books or journals".
    def inclusive_filters
      @inclusive_filters ||= begin
        raw = filter_hash(args[:filters], 'filters')
        raw = merge_filter(raw, FORMAT_FIELD, args[:formats], 'formats')
        raw = merge_filter(raw, LANGUAGE_FIELD, args[:languages], 'languages')
        validate_filters(raw, 'filters')
      end
    end

    # Several values for one facet, matched as "all of these". A record must
    # have every one. This is what clicking sidebar facets one after another does.
    def conjunctive_filters
      @conjunctive_filters ||= begin
        raw = validate_filters(filter_hash(args[:filters_all], 'filters_all'), 'filters_all')
        overlap = raw.keys & inclusive_filters.keys
        if overlap.any?
          raise InvalidArgument, "#{FacetNames.public_names(overlap).join(', ')} appears in both " \
                                 'filters and filters_all; use one or the other for a given facet'
        end

        raw
      end
    end

    # Keys arrive as the names the tools advertise ("Library Location") and leave
    # as the Solr fields Blacklight filters on. Two spellings of the same facet
    # -- the readable name and the Solr field -- are one filter, not two.
    def filter_hash(value, label)
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

    def merge_filter(filters, field, values, label)
      return filters if values.blank?

      unless values.is_a?(Array) || values.is_a?(String)
        raise InvalidArgument, "#{label} must be an array of facet values"
      end

      filters.merge(field => Array.wrap(filters[field]) + Array.wrap(values))
    end

    # Keys are Solr fields by now -- filter_hash resolved them -- but every
    # message here names the facet the way the caller does.
    def validate_filters(filters, label)
      filters.each_with_object({}) do |(field, values), result|
        name = FacetNames.public_name(field)

        if CatalogOptions.range_facet_field?(field)
          raise InvalidArgument, "#{name} is a range facet; filter it with " \
                                 "#{field == DATE_RANGE_FIELD ? 'date_range' : "ranges[#{name}]"} " \
                                 '(begin/end), not with ' + label
        end

        values = Array.wrap(values).map { |value| value.to_s.strip }.reject(&:blank?)
        if values.empty?
          raise InvalidArgument, "#{label}[#{name}] must contain at least one non-blank value"
        end

        if values.length > MAX_FILTER_VALUES
          raise InvalidArgument, "#{label}[#{name}] accepts at most #{MAX_FILTER_VALUES} values " \
                                 "(got #{values.length}). Use fewer, or drop the filter and narrow the query."
        end

        too_long = values.find { |value| value.length > MAX_FILTER_VALUE_LENGTH }
        if too_long
          raise InvalidArgument, "#{label}[#{name}] has a value of #{too_long.length} characters; " \
                                 "facet values are at most #{MAX_FILTER_VALUE_LENGTH}. " \
                                 'Use facet_values to find the exact value you want.'
        end

        result[field] = values
      end
    end

    # --- ranges -------------------------------------------------------------

    # A start and end year. The catalog ignores a range that's missing either
    # end, so both are required here.
    def ranges
      @ranges ||= begin
        raw = {}
        raw[DATE_RANGE_FIELD] = args[:date_range] if args[:date_range].present?

        if args[:ranges].present?
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
        end

        raw.each_with_object({}) do |(field, bounds), result|
          result[field] = range_bounds(field, bounds)
        end
      end
    end

    def range_bounds(field, bounds)
      name = FacetNames.public_name(field)

      unless CatalogOptions.range_facet_field?(field)
        raise InvalidArgument, "#{name.inspect} is not a range facet. " \
                               "Range facets: #{FacetNames.public_range_names.map(&:inspect).join(', ')}"
      end

      unless bounds.is_a?(Hash)
        raise InvalidArgument, "ranges[#{name}] must be an object with 'begin' and 'end'"
      end

      bounds = bounds.symbolize_keys
      first = year(bounds[:begin], "ranges[#{name}].begin")
      last = year(bounds[:end], "ranges[#{name}].end")

      if first > last
        raise InvalidArgument, "ranges[#{name}] begin (#{first}) must not be later than end (#{last})"
      end

      # Sent as text, exactly like the date range form does.
      { 'begin' => first.to_s, 'end' => last.to_s }
    end

    def year(value, label)
      raise InvalidArgument, "#{label} is required (a range needs both a begin and an end)" if value.nil? || value.to_s.strip.empty?

      Integer(value.to_s.strip)
    rescue ArgumentError, TypeError
      raise InvalidArgument, "#{label} must be a whole year, e.g. 1966 (got #{value.inspect})"
    end

    # --- sort and paging ----------------------------------------------------

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

    def page
      value = args[:page]
      return 1 if value.blank?

      page = integer(value, 'page')
      raise InvalidArgument, 'page must be 1 or greater' if page < 1

      page
    end

    def per_page
      value = args[:per_page]
      return DEFAULT_PER_PAGE if value.blank?

      per_page = integer(value, 'per_page')
      unless per_page.between?(1, MAX_PER_PAGE)
        raise InvalidArgument, "per_page must be between 1 and #{MAX_PER_PAGE} (got #{per_page})"
      end

      per_page
    end

    # Paging is checked as a pair, because neither number is a problem on its
    # own. The message names the last page that does work, so the caller can
    # either stop there or narrow the search instead of probing for the edge.
    def check_result_window!(page, per_page)
      last_record = page * per_page
      return if last_record <= MAX_RESULT_WINDOW

      raise InvalidArgument,
            "page #{page} at per_page #{per_page} would reach record #{last_record}, past this catalog's " \
            "#{MAX_RESULT_WINDOW}-record limit. The last page at per_page #{per_page} is " \
            "#{MAX_RESULT_WINDOW / per_page}. To reach records beyond it, narrow the search with filters " \
            'or a date range, or change sort so the records you want come nearer the front.'
    end

    def integer(value, label)
      Integer(value.to_s.strip)
    rescue ArgumentError, TypeError
      raise InvalidArgument, "#{label} must be a whole number (got #{value.inspect})"
    end

    # --- misc ---------------------------------------------------------------

    # The catalog's search code handles escaping. This only blocks input that
    # would be pointless or abusive to send at all.
    def clean_query(query)
      query = query.to_s.strip
      if query.length > MAX_QUERY_LENGTH
        raise InvalidArgument, "query must be #{MAX_QUERY_LENGTH} characters or fewer (got #{query.length})"
      end

      query
    end

    def normalize_args(args)
      raise InvalidArgument, 'arguments must be an object' unless args.nil? || args.is_a?(Hash)

      (args || {}).each_with_object({}) do |(key, value), result|
        result[key.to_sym] = value.is_a?(Hash) ? value.symbolize_keys : value
      end
    end
  end
end
