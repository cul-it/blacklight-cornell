##########################################################################
## Override Blacklight::SearchHistoryConstraintsHelperBehavior Methods  ##
#########################################################################
module CornellSearchHistoryConstraintsHelper
  # ============================================================================
  # Formats operators and boolean values for display in the search history.
  # Custom logic for advanced searches.
  # Skips entries in query_text that are blank or contain only whitespace.
  # Falls back to default rendering for non-advanced searches.
  # ----------------------------------------------------------------------------
  def render_search_to_s_element(label, query_text, options = {})
    if options[:search_type] == "advanced search"
      search_history_spans = []
      query_text.each_with_index do |text, index|
        next if text.blank? || text.strip.empty? #Skip search section if text blank

        op_val = options[:op_row][index]
        operator = case op_val
                   when "AND"         then ""
                   when "OR"          then "ANY"
                   when "phrase"      then "CONTAINS PHRASE WITH"
                   when "NOT"         then "NOT"
                   when "begins_with" then "BEGINS WITH"
                   else
                     ""
                   end

        if options[:boolean_row].present?
          boolean = options[:boolean_row][index.to_s]
          boolean = "#{boolean}" if boolean.present?
        end

        # Get the field label (e.g., "Title: ")
        field_label = label_for_search_field(label[index])

        # Build the boolean + operator + field label part
        label_parts = []
        label_parts << boolean unless boolean.blank?
        label_parts << operator unless operator.blank?
        label_parts << field_label

        # Render the label parts in a span for styling
        label_span = render_filter_name("#{label_parts.join(" ")}")
        # Render the query text parts in a span for styling
        query_span = tag.span(text, class: 'filter-values')

        # Combine both spans in a constraint container
        search_text = tag.span(
          label_span + query_span,
          style: 'margin-right: 8px;'
        )
        search_history_spans << search_text
      end
      # Advanced Searches
      search_history_node = tag.div(
        safe_join(search_history_spans, " "),
        class: 'constraint',
        style: 'display: inline-block; text-indent: 0rem; padding-left: 8px !important;'
      )

      search_history_node.html_safe
    else
      # Non-Advanced Searches
      label_span = render_filter_name(label)
      query_span = tag.span(query_text, class: 'filter-values')

      tag.div(
        label_span + query_span,
        class: 'constraint',
        style: 'display: inline-block; text-indent: 0rem; padding-left: 8px !important;'
      )
      # tag.span(render_filter_name(label) + tag.span(query_text, class: 'filter-values'), class: 'constraint')
    end
  end
end