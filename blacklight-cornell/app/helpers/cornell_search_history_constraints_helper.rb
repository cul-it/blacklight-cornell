# ##########################################################################
# ## Override Blacklight::SearchHistoryConstraintsHelperBehavior Methods  ##
# #########################################################################
# ========================================================================
# Formats operators, filters, and boolean values for basic search history.
# Skips entries in query_text that are blank or contain only whitespace.
# ------------------------------------------------------------------------
module CornellSearchHistoryConstraintsHelper
  # =============================
  # Build the full search summary
  # -----------------------------
  def render_search_to_s(params)
    search_history_parts = []

    # --- SEARCH TERMS block ---------------------------------------------------
    if params['q'].present?
      search_history_parts << content_tag(:span, 'SEARCH TERM:', class: 'query-boolean ms-2')
      search_history_parts << render_search_to_s_q(params)
    end

    # --- FILTERED BY block ----------------------------------------------------
    if params[:f].present?
      search_history_parts << tag.div(class: 'w-100')
      search_history_parts << content_tag(:span, 'FILTERED BY:', class: 'query-boolean ms-2')

      filter_spans = []
      params[:f].each_with_index do |(facet_key, values), facet_index|
        values.each_with_index do |val, value_index|
          filter_spans << content_tag(:span, 'AND', class: 'query-boolean') if facet_index.positive? || value_index.positive?
          label = facet_field_label(facet_key)
          filter_spans << render_search_to_s_element(label, val)
        end
      end
      search_history_parts.concat(filter_spans)
    end

    # --- DATED BETWEEN block --------------------------------------------------
    if params[:range].present?
      search_history_parts << tag.div(class: 'w-100')
      search_history_parts << content_tag(:span, 'DATED BETWEEN:', class: 'query-boolean ms-2')

      range_spans = []
      params[:range].each_with_index do |(facet_key, v), range_index|
        if v['begin'].present? && v['end'].present?
          range_spans << content_tag(:span, 'AND', class: 'query-boolean') if range_index.positive?
          label = facet_field_label(facet_key)
          range_spans << render_search_to_s_element(label, "#{v['begin']} - #{v['end']}")
        end
      end
      search_history_parts.concat(range_spans)
    end

    # Create the link to the search history query
    link_to(search_action_path(params)) do
      content_tag(:div, safe_join(search_history_parts, ' '),
                  class: 'constraint',
                  style: 'display: inline-block; text-indent: 0rem; padding-left: 8px !important;')
    end
  end

  # ===============================
  # Build a single filter span pill
  # -------------------------------
  def render_search_to_s_element(label, plain_text, _options = {})
    span = content_tag(:span, class: 'combined-label-query btn btn-light') do
      content_tag(:span, class: 'filter-name') do
        inner = content_tag(:span, label, class: 'label-text')
        inner += ' All' if label == 'All Fields'
        inner
      end +
        content_tag(:span, plain_text, class: 'query-text')
    end
  end

  # ================================================
  # Build the search term pill (uses :q from params)
  # ------------------------------------------------
  def render_search_to_s_q(params)
    return ''.html_safe if params['q'].blank?
    label = label_for_search_field(params[:search_field])
    query_text = strip_tags(render_filter_value(params['q']))
    render_search_to_s_element(label, query_text)
  end
end
