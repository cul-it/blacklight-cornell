module SearchHistoryHelper
  # ============================================================================
  # Map solr facet field names to display-friendly labels
  # ----------------------------------------------------------------------------
  FACET_LABEL_MAPPINGS = {
    language_facet:         'Language',
    format:                 'Format',
    pub_date_facet:         'Publication Year',
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
  # - Uses parseHistoryQueryString(params) to generate the URL
  # - Renders the label HTML inside a styled <div> block inside the link
  # ============================================================================
  def link_to_custom_search_history_link(params)
    query_texts = build_search_query_tags(params)
    link_to(parseHistoryQueryString(params)) do
      content_tag(:div, safe_join(query_texts, ' '),
                  class: 'constraint',
                  style: 'display: inline-block; text-indent: 0rem; padding-left: 8px !important;')
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

    title_label = q_row.count(&:present?) > 1 ? "SEARCH TERMS: " : "SEARCH TERM: "
    query_texts << content_tag(:span, title_label, class: 'query-boolean ms-2')

    # Queries ------------------------------------------------------------------
    q_row.each_with_index do |query, i|
      next if query.blank?
      boolean     = i.positive? ? b_row[i.to_s.to_sym] : nil
      field_key   = sf_row[i] || 'all_fields'
      field_label = search_field_def_for_key(field_key)[:label] rescue 'All Fields'
      op_label    = OP_ROW_MAPPINGS[op_row[i].to_sym] || op_row[i] || ''

      query_html = content_tag(:span, class: 'combined-label-query btn btn-light') do
        content_tag(:span, class: 'filter-name') do
          content_tag(:span, field_label, class: 'label-text') + " #{op_label} "
        end + content_tag(:span, query, class: 'query-text')
      end

      query_texts << content_tag(:span, boolean, class: 'query-boolean') if boolean.present? && q_row[i - 1].present?
      query_texts << query_html
    end

    # Filters ------------------------------------------------------------------
    if f_row.present?
      query_texts << tag.div(class: 'w-100')
      query_texts << content_tag(:span, 'FILTERED BY: ', class: 'query-boolean ms-2')

      f_row.each_with_index do |(facet_key, values), filter_index|
        values.each_with_index do |val, value_index|
          query_texts << content_tag(:span, 'AND', class: 'query-boolean') if filter_index.positive? || value_index.positive?
          label = FACET_LABEL_MAPPINGS[facet_key.to_sym] || facet_key.to_s.titleize
          value = val.to_s

          facet_html = content_tag(:span, class: 'combined-label-query btn btn-light') do
            content_tag(:span, class: 'filter-name') do
              content_tag(:span, label, class: 'label-text')
            end + content_tag(:span, value, class: 'query-text')
          end
          query_texts << facet_html
        end
      end
    end

    # Inclusive Filters --------------------------------------------------------
    if f_inclusive.present?
      query_texts << tag.div(class: 'w-100')
      query_texts << content_tag(:span, 'INCLUDE ANY: ', class: 'query-boolean ms-2')

      f_inclusive.each_with_index do |(facet_key, values), filter_index|
        values.each_with_index do |val, value_index|
          query_texts << content_tag(:span, 'OR', class: 'query-boolean') if filter_index.positive? || value_index.positive?
          label = FACET_LABEL_MAPPINGS[facet_key.to_sym] || facet_key.to_s.titleize
          value = val.to_s

          facet_html = content_tag(:span, class: 'combined-label-query btn btn-light') do
            content_tag(:span, class: 'filter-name') do
              content_tag(:span, label, class: 'label-text')
            end + content_tag(:span, value, class: 'query-text')
          end
          query_texts << facet_html
        end
      end
    end

    # Date range ---------------------------------------------------------------
    if dr_row.present? && dr_row[:pub_date_facet]&.[](:begin).present? && dr_row[:pub_date_facet]&.[](:end).present?
      query_texts << tag.div(class: 'w-100')
      query_texts << content_tag(:span, 'DATED BETWEEN: ', class: 'query-boolean ms-2')

      dr_row.each_with_index do |(facet_key, values), ridx|
        next unless values['begin'].present? && values['end'].present?
        query_texts << content_tag(:span, 'AND', class: 'query-boolean') if ridx.positive?
        label = FACET_LABEL_MAPPINGS[facet_key.to_sym] || facet_key.titleize

        facet_html = content_tag(:span, class: 'combined-label-query btn btn-light') do
          content_tag(:span, class: 'filter-name') do
            content_tag(:span, label, class: 'label-text')
          end + content_tag(:span, "#{values['begin']} - #{values['end']}", class: 'query-text')
        end
        query_texts << facet_html
      end
    end

    query_texts
  end

  # ============================================================================
  # Builds formatted search URL from session params
  # ----------------------------------------------------------------------------
  def parseHistoryQueryString(params)
    start_params   = "catalog?only_path=true&utf8=✓&advanced_query=yes&omit_keys[]=page&params[advanced_query]=yes"
    sort_param     = params[:sort].presence || 'score desc, pub_date_sort desc, title_sort asc'
    closing_params = "&sort=#{CGI.escape(sort_param)}&search_field=advanced&commit=Search"

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
    q_row.each_with_index do |query, i|
      next if query.blank?
      boolean = i.positive? ? b_row[i.to_s.to_sym] : nil
      link_text += "&boolean_row[#{i}]=#{boolean}" if boolean
      link_text += "&q_row[]=#{CGI.escape(query)}&op_row[]=#{op_row[i]}&search_field_row[]=#{sf_row[i]}"
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

    # Date range ---------------------------------------------------------------
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



  # todo NOT USED?
  # # ============================================================================
  # # Render Basic and Advanced Query Constraint
  # # ----------------------------------------------------------------------------
  # def parseHistoryShowString(params)
  #   # showText = ''
  #   # sf_row   = params[:search_field_row]
  #   # q_row    = params[:q_row]
  #   # b_row    = params[:boolean_row]
  #   # i        = 0
  #   # num      = sf_row.length
  #   #
  #   # while i < num do
  #   #   if i > 0
  #   #     showText = showText + " " + "#{b_row[i.to_s.to_sym]}" + " " + search_field_def_for_key(sf_row[i])[:label] + ": " + q_row[i]
  #   #   else
  #   #     showText = showText + search_field_def_for_key(sf_row[i])[:label] + ": " + q_row[i]
  #   #   end
  #   #   i += 1
  #   # end
  #   #
  #   # params[:q] = showText # Sends 'correct' q param to link_link_to_previous_search
  #   # link_to_custom_search_history_link(params) # custom version of #link_to_previous_search from blacklight to include f_inclusive filters and visual formatting
  # end


end