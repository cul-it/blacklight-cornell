module SearchHistoryHelper
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

    # SEARCH TERMS SECTION -----------------------------------------------------
    terms_nodes = []
    q_row.each_with_index do |query, index|
      next if query.blank?
      field_key = sf_row[index] || 'all_fields'
      field_lbl = (search_field_def_for_key(field_key)[:label] rescue 'All Fields')
      op_lbl    = op_row_label_for(op_row[index])
      chip      = mk_chip_with_op(field_lbl, op_lbl, query.to_s)

      if index.zero?
        terms_nodes << chip
      else
        bool = b_row[index.to_s.to_sym].presence || ' AND '
        terms_nodes << pair_with_boolean(bool, chip)
      end
    end
    grp = wrap_group('Search:', terms_nodes)
    query_texts << grp if grp

    # FILTERED BY SECTION (exclusive facets) -----------------------------------
    filters_nodes = []

    # Missing Publication Year (-pub_date_facet)
    no_date = Array(dr_row['-pub_date_facet']).include?('[* TO *]')
    if no_date
      label = facet_label_for('-pub_date_facet')
      chip = mk_chip(label, mk_value('Missing'))
      filters_nodes << chip
    end

    # Other exclusive facets
    if f_row.present?
      first = filters_nodes.empty?
      f_row.each do |facet_key, values|
        Array(values).reject(&:blank?).each do |raw_val|
          label = facet_label_for(facet_key)
          val   = facet_value_label_for(facet_key, raw_val)
          chip  = mk_chip(label, mk_value(val))
          if first
            filters_nodes << chip
            first = false
          else
            filters_nodes << pair_with_boolean('AND', chip)
          end
        end
      end
    end
    grp = wrap_group('Filter:', filters_nodes)
    query_texts << grp if grp

    # INCLUDE ANY SECTION (inclusive facets) -----------------------------------
    includes_nodes = []
    if f_inclusive.present?
      index = 0
      f_inclusive.each do |facet_key, values|
        vals = Array(values).map { |v| facet_value_label_for(facet_key, v) }.map(&:to_s).reject(&:blank?)
        next if vals.empty?
        label = facet_label_for(facet_key)
        chip  = mk_inclusive_chip(" #{label}", vals)
        index.zero? ? includes_nodes << chip : includes_nodes << pair_with_boolean('AND', chip)
        index += 1
      end
    end
    grp = wrap_group('Include:', includes_nodes)
    query_texts << grp if grp

    # DATED BETWEEN (range) ----------------------------------------------------
    dates_nodes = []
    if dr_row.present? && dr_row[:pub_date_facet]&.[](:begin).present? && dr_row[:pub_date_facet]&.[](:end).present?
      dr_row.each_with_index do |(facet_key, values), row_index|
        next unless values[:begin].present? && values[:end].present?
        label = facet_label_for(facet_key)
        chip  = mk_chip(label, mk_value("#{values[:begin]} - #{values[:end]}"))
        row_index.zero? ? dates_nodes << chip : dates_nodes << pair_with_boolean('AND', chip)
      end
    end
    grp = wrap_group('Dated:', dates_nodes)
    query_texts << grp if grp

    query_texts
  end

  # ============================================================================
  # Builds formatted search URL from session params
  # ----------------------------------------------------------------------------
  def build_search_history_url(params, search_type)
    query        = { }
    base_path    = 'catalog'
    query[:sort] = params[:sort] if params[:sort].present?
    query[:utf8] = params[:utf8] if params[:utf8].present?
    q_row        = params[:q_row] || [params[:q]].compact
    sf_row       = params[:search_field_row] || [params[:search_field]].compact
    op_row       = params[:op_row] || ['AND']
    b_row        = params[:boolean_row] || {}
    dr_row       = params[:range] || {}
    f_row        = params[:f] || {}
    f_inclusive  = params[:f_inclusive] || {}

    if search_type == :advanced
      query[:q_row], query[:op_row], query[:search_field_row] = [], [], []
      query[:advanced_query] = 'yes'
      query[:search_field]   = 'advanced'
      query[:commit]         = 'Search'
      query.delete(:q)
    end

    # Query --------------------------------------------------------------------
    boolean_row_hash = {}
    q_row.each_with_index do |q, index|
      next if q.blank?
      if search_type == :advanced
        query[:q_row]            << q
        query[:op_row]           << op_row[index]
        query[:search_field_row] << (sf_row[index] || 'all_fields')
        boolean_row_hash[index] = b_row[index.to_s.to_sym].presence if index.positive?
      else
        # Basic search: single q + field
        query[:q] = q
        query[:search_field] = (sf_row[index] || 'all_fields')
      end
    end
    query[:boolean_row] = boolean_row_hash if boolean_row_hash.present?

    # Filters ------------------------------------------------------------------
    unless f_row.blank?
      query[:f] = {}
      f_row.each do |key, values|
        vals = Array(values).reject(&:blank?)
        query[:f][key] = vals if vals.any?
      end
      query.delete(:f) if query[:f].blank?
    end

    # Inclusive Filters --------------------------------------------------------
    unless f_inclusive.blank?
      query[:f_inclusive] = {}
      f_inclusive.each do |key, values|
        vals = Array(values).reject(&:blank?)
        query[:f_inclusive][key] = vals if vals.any?
      end
      query.delete(:f_inclusive) if query[:f_inclusive].blank?
    end

    # Dates --------------------------------------------------------------------
    # No dates facet
    if dr_row['-pub_date_facet'].present?
      query[:range] ||= {}
      query[:range]['-pub_date_facet'] = Array(dr_row['-pub_date_facet']).reject(&:blank?)
    end

    # Date range facets
    pub_date_facet = dr_row[:pub_date_facet]         || {}
    begin_val      = pub_date_facet[:begin].presence || ""
    end_val        = pub_date_facet[:end].presence   || ""

    if search_type == :advanced
      query[:range] = { pub_date_facet: { begin: begin_val, end: end_val } }
    else
      query[:range] = { pub_date_facet: { begin: begin_val, end: end_val } } if begin_val.present? && end_val.present?
    end

    # Build Query String -------------------------------------------------------
    advanced_params = [:utf8, :q_row, :op_row, :search_field_row,:boolean_row, :range,:sort, :search_field, :advanced_query, :commit, :f, :f_inclusive]
    basic_params    = [:utf8, :q, :search_field, :f, :f_inclusive, :range, :sort]
    desired_order   = search_type == :advanced ? advanced_params : basic_params

    ordered_query = {}
    desired_order.each { |k| ordered_query[k] = query[k] if query.key?(k) }

    "#{base_path}?#{ordered_query.to_query}" # Search URL with ordered query params
  end



  private

  # ============================================================================
  # Return display Operator (AND, OR, begins_with, phrase)
  # Uses blacklight.search.form.op_row.<key>, with mapped display values
  # ----------------------------------------------------------------------------
  def op_row_label_for(value)
    key = value.to_s
    mapped = {
      'AND'         => 'All',
      'OR'          => 'Any',
      'begins_with' => 'Begins with',
      'phrase'      => 'Phrase'
    }
    I18n.t("blacklight.search.form.op_row.#{key}", default: mapped[key] || key)
  end


  # ============================================================================
  # Blacklight config Label Mappings
  # ----------------------------------------------------------------------------
  # Fetch facet configuration from blacklight_config for a given key
  def facet_config_for(key)
    normalized = key.to_s.sub(/\A-/, '')
    blacklight_config.facet_configuration_for_field(normalized)
  end

  # Pull facet label from blacklight_config
  def facet_label_for(key)
    cfg = facet_config_for(key)
    return cfg.display_label(self) if cfg && cfg.respond_to?(:display_label)
    return cfg.label if cfg && cfg.respond_to?(:label) && cfg.label.present?
    key.to_s.sub(/\A-/, '').titleize
  end

  # Pull values from "query" facets
  def facet_value_label_for(key, value)
    cfg = facet_config_for(key)
    return value.to_s unless cfg && cfg.respond_to?(:query) && cfg.query.present?

    item = cfg.query[value.to_s] || cfg.query[value.to_sym]
    item && item[:label].present? ? item[:label] : value.to_s
  end


  # ============================================================================
  # Search history helper methods
  # ----------------------------------------------------------------------------
  def mk_value(text)
    content_tag(:span, text, class: 'query-text')
  end

  def mk_chip(label_text, inner_html)
    content_tag(:span, class: 'combined-label-query btn btn-light', style: 'padding: 0 6px;') do
      content_tag(:span, class: 'filter-name') do
        content_tag(:span, " #{label_text}: ", class: 'label-text')
      end + inner_html
    end
  end

  def mk_chip_with_op(label_text, op_text, value_text)
    content_tag(:span, class: 'combined-label-query btn btn-light', style: 'padding:0 6px;') do
      content_tag(:span, class: 'filter-name') do
        content_tag(:span, " #{label_text}: ", class: 'label-text') +
          (op_text.present? ? content_tag(:span, " #{op_text} ", class: 'op-label') : ''.html_safe)
      end + content_tag(:span, value_text, class: 'query-text')
    end
  end

  def mk_inclusive_chip(label_text, values)
    pieces = []
    values.each_with_index do |val, index|
      pieces << mk_value(val.to_s)
      pieces << content_tag(:span, ' OR ', class: 'inclusive-or') if index < values.length - 1
    end
    mk_chip(label_text, safe_join(pieces))
  end

  def pair_with_boolean(bool_text, chip_node)
    nbsp = "\u00A0" # non-breaking space
    content_tag(:span, class: 'bool-pair', style: 'display:inline-block;') do
      content_tag(:span, "#{nbsp}#{bool_text}#{nbsp}", class: 'query-boolean') + chip_node
    end
  end

  def wrap_group(label_text, nodes)
    return nil if nodes.blank?

    content_tag(:div, class: 'history-group') do
      content_tag(:span, label_text, class: 'query-boolean ms-2 group-label') +
        content_tag(:div, safe_join(nodes, ' '), class: 'group-body')
    end
  end
end