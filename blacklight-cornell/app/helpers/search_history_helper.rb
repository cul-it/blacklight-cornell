module SearchHistoryHelper
  # ============================================================================
  # Map solr facet field names to display-friendly labels
  # ----------------------------------------------------------------------------
  FACET_LABEL_MAPPINGS = {
    online:                 'Access',
    language_facet:         'Language',
    format:                 'Format',
    pub_date_facet:         'Publication Year',
    "-pub_date_facet":      'Publication Year',
    fast_topic_facet:       'Subject',
    author_facet:           'Author',
    fast_genre_facet:       'Genre',
    lc_callnum_facet:       'Call Number',
    acquired_dt_query:      'Acquired Date',
    fast_geo_facet:         'Subject Region',
    subject_content_facet:  'Fiction/Non-fiction Type',
    fast_era_facet:         'Subject Era',
    last_1_week:            'Since last week',
    last_1_month:           'Since last month',
    last_1_years:           'Since last year',
  }

  # ============================================================================
  # Map Advanced Search Operators to display-friendly labels
  # ----------------------------------------------------------------------------
  OP_ROW_MAPPINGS = {
    begins_with: 'Begins With',
    phrase:      'Phrase',
    OR:          'Any',
    AND:         'All',
  }

  
  # ============================================================================
  # - Builds a visual label (query_texts) with proper span/button layout
  # - Uses build_search_history_url(params) to generate the URL
  # - Renders the label HTML inside a styled <div> block inside the link
  # ----------------------------------------------------------------------------
  def link_to_custom_search_history_link(params, search_type)
    query_texts = build_search_query_tags(params)
    link_to(build_search_history_url(params, search_type)) do
      content_tag(:div, safe_join(query_texts, ' '),
                  class: 'constraint custom-search-history-link')
    end
  end


  # ============================================================================
  # Generates query text nodes for advanced search params, including boolean,
  # facet, and range filters formatted for display
  # ----------------------------------------------------------------------------
  def build_search_query_tags(params)
    query_texts = []
    q_row       = params[:q_row] || [params[:q]].compact
    sf_row      = params[:search_field_row] || [params[:search_field]].compact
    op_row      = params[:op_row] || ['AND']
    b_row       = params[:boolean_row] || {}
    dr_row      = params[:range] || {}
    f_row       = params[:f] || {}
    f_inclusive = params[:f_inclusive] || {}

    # LAMBDA HELPER SECTION ----------------------------------------------------
    mk_value = ->(text) { content_tag(:span, text, class: 'query-text') }

    mk_chip = ->(label_text, inner_html) do
      content_tag(:span, class: 'combined-label-query btn btn-light', style: 'padding: 0 6px;') do
        content_tag(:span, class: 'filter-name') do
          content_tag(:span, label_text, class: 'label-text')
        end + inner_html
      end
    end

    mk_chip_with_op = ->(label_text, op_text, value_text) do
      content_tag(:span, class: 'combined-label-query btn btn-light', style: 'padding:0 6px;') do
        content_tag(:span, class: 'filter-name') do
          content_tag(:span, label_text, class: 'label-text') +
            (op_text.present? ? content_tag(:span, " #{op_text}", class: 'op-label') : ''.html_safe)
        end + content_tag(:span, value_text, class: 'query-text')
      end
    end

    mk_inclusive_chip = ->(label_text, values) do
      pieces = []
      values.each_with_index do |val, index|
        pieces << mk_value.call(val.to_s)
        pieces << content_tag(:span, ' OR ', class: 'inclusive-or') if index < values.length - 1
      end
      mk_chip.call(label_text, safe_join(pieces))
    end

    pair_with_boolean = ->(bool_text, chip_node) do
      nbsp = "\u00A0" # non-breaking space
      content_tag(:span, class: 'bool-pair', style: 'display:inline-block;') do
        content_tag(:span, "#{nbsp}#{bool_text}#{nbsp}", class: 'query-boolean') + chip_node
      end
    end

    wrap_group = ->(label_text, nodes) do
      return nil if nodes.blank?
      content_tag(:div, class: 'history-group') do
        content_tag(:span, label_text, class: 'query-boolean ms-2 group-label') +
          content_tag(:div, safe_join(nodes, ' '), class: 'group-body')
      end
    end

    # SEARCH TERMS SECTION -----------------------------------------------------
    terms_nodes = []
    q_row.each_with_index do |query, index|
      next if query.blank?
      field_key = sf_row[index] || 'all_fields'
      field_lbl = (search_field_def_for_key(field_key)[:label] rescue 'All Fields')
      op_lbl    = OP_ROW_MAPPINGS[op_row[index].to_sym] || op_row[index] || ''
      chip      = mk_chip_with_op.call(field_lbl, op_lbl, query.to_s)

      if index.zero?
        terms_nodes << chip
      else
        bool = b_row[index.to_s.to_sym].presence || ' AND '
        terms_nodes << pair_with_boolean.call(bool, chip)
      end
    end

    title_label = q_row.count(&:present?) > 1 ? 'Search:' : 'Search:'
    grp = wrap_group.call(title_label, terms_nodes)
    query_texts << grp if grp

    # FILTERED BY SECTION (exclusive facets) -----------------------------------
    filters_nodes = []

    no_date = Array(dr_row['-pub_date_facet']).include?('[* TO *]')
    if no_date
      dr_row.each_with_index do |(facet_key, values), row_index|
        next unless no_date
        label = FACET_LABEL_MAPPINGS[facet_key.to_sym] || facet_key.to_s.titleize
        chip  = mk_chip.call(label, mk_value.call("Missing"))
        row_index.zero? ? filters_nodes << chip : filters_nodes << pair_with_boolean.call('AND', chip)
      end
    end

    if f_row.present?
      first = true
      f_row.each do |facet_key, values|
        Array(values).each do |val|
          label = FACET_LABEL_MAPPINGS[facet_key.to_sym] || facet_key.to_s.titleize
          chip  = mk_chip.call(label, mk_value.call(val.to_s))
          first ? (filters_nodes << chip; first = false) : filters_nodes << pair_with_boolean.call('AND', chip)
        end
      end
    end
    grp = wrap_group.call('Filter:', filters_nodes)
    query_texts << grp if grp

    # INCLUDE ANY SECTION (inclusive facets) -----------------------------------
    includes_nodes = []
    if f_inclusive.present?
      index = 0
      f_inclusive.each do |facet_key, values|
        vals = Array(values).map(&:to_s).reject(&:blank?)
        next if vals.empty?
        label = FACET_LABEL_MAPPINGS[facet_key.to_sym] || facet_key.to_s.titleize
        chip  = mk_inclusive_chip.call(label, vals)
        index.zero? ? includes_nodes << chip : includes_nodes << pair_with_boolean.call('AND', chip)
        index += 1
      end
    end
    grp = wrap_group.call('Include:', includes_nodes)
    query_texts << grp if grp

    # DATED BETWEEN (range) ----------------------------------------------------
    dates_nodes = []
    if dr_row.present? && dr_row[:pub_date_facet]&.[](:begin).present? && dr_row[:pub_date_facet]&.[](:end).present?
      dr_row.each_with_index do |(facet_key, values), row_index|
        next unless values['begin'].present? && values['end'].present?
        label = FACET_LABEL_MAPPINGS[facet_key.to_sym] || facet_key.to_s.titleize
        chip  = mk_chip.call(label, mk_value.call("#{values['begin']} - #{values['end']}"))
        row_index.zero? ? dates_nodes << chip : dates_nodes << pair_with_boolean.call('AND', chip)
      end
    end
    grp = wrap_group.call('Dated:', dates_nodes)
    query_texts << grp if grp

    query_texts
  end

  # ============================================================================
  # Builds formatted search URL from session params
  # ----------------------------------------------------------------------------
  def build_search_history_url(params, search_type)
    sort_param     = params[:sort].presence || 'score desc, pub_date_sort desc, title_sort asc'
    start_params   = "catalog?only_path=true&utf8=✓" + (search_type == :advanced ? "&advanced_query=yes&omit_keys[]=page&params[advanced_query]=yes" : "")
    closing_params = "&sort=#{CGI.escape(sort_param)}" + (search_type == :advanced ? "&search_field=advanced&commit=Search" : "")

    link_text   = ''
    f_link_text = ''
    f_inclusive_link_text = ''

    q_row       = params[:q_row] || [params[:q]].compact
    sf_row      = params[:search_field_row] || [params[:search_field]].compact
    op_row      = params[:op_row] || ['AND']
    b_row       = params[:boolean_row] || {}
    dr_row      = params[:range] || {}
    f_row       = params[:f] || {}
    f_inclusive = params[:f_inclusive] || {}

    # Query --------------------------------------------------------------------
    q_row.each_with_index do |query, index|
      next if query.blank?
      boolean = index.positive? ? b_row[index.to_s.to_sym] : nil
      link_text += "&boolean_row[#{index}]=#{boolean}" if boolean
      link_text += (search_type == :advanced ? "&q_row[]=#{CGI.escape(query)}&op_row[]=#{op_row[index]}&search_field_row[]=#{sf_row[index]}" : "&q=#{CGI.escape(query)}&search_field=#{sf_row[index]}")
    end

    # Filters ------------------------------------------------------------------
    f_row.each do |key, values|
      values.each do |text|
        f_link_text += "&f[#{key}][]=#{CGI.escape(text)}"
      end
    end

    # Inclusive Filters --------------------------------------------------------
    f_inclusive.each do |key, values|
      values.each do |text|
        f_inclusive_link_text += "&f_inclusive[#{key}][]=#{CGI.escape(text)}"
      end
    end

    # Dates --------------------------------------------------------------------
    # No dates facet
    if dr_row['-pub_date_facet'].present?
      Array(dr_row['-pub_date_facet']).each do |val|
        next if val.blank?
        f_link_text << "&range[-pub_date_facet][]=#{CGI.escape(val.to_s)}"
      end
    end

    # Date range facets
    if dr_row.present? && dr_row[:pub_date_facet]&.[](:begin).present? && dr_row[:pub_date_facet]&.[](:end).present?
      dr_row.each do |field, range_opts|
        range_opts.each do |bound, val|
          next if val.blank?
          f_link_text += "&range[#{field}][#{bound}]=#{CGI.escape(val)}"
        end
      end
    end

    start_params + link_text + f_link_text + f_inclusive_link_text + closing_params
  end
end