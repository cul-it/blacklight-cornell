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
    ############################################################################
    ## Advanced Searches ##
    #######################
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

        # Get the label field (e.g., "Title: ")
        field_label = tag.span(label_for_search_field(label[index]), class: 'label-text')

        # Build the boolean + operator + field label part
        label_parts = []
        label_parts << boolean unless boolean.blank?
        label_parts << operator unless operator.blank?
        label_parts << field_label

        # Create label, and text spans, then combine into search_text span
        label_span  = tag.span(safe_join(label_parts, " "), class: 'filter-name')
        query_span  = tag.span(text, class: 'query-text')
        search_text = tag.span(label_span + query_span, class: 'combined-label-query btn btn-light')

        search_history_spans << search_text
      end
      # Advanced Searches
      advanced_search_history_node = tag.div(
        safe_join(search_history_spans, " "),
        class: 'constraint',
        style: 'display: inline-block; text-indent: 0rem; padding-left: 8px !important;'
      )

      advanced_search_history_node # Return the advanced search history node
    else

      ##########################################################################
      ## Basic Searches ##
      ####################
      label_span  = tag.span(label, class: 'filter-name')
      query_span  = tag.span(query_text, class: 'query-text')
      search_text = tag.span(label_span + query_span, class: 'combined-label-query btn btn-light')

      basic_search_history_node = tag.div(
        search_text,
        class: 'constraint',
        style: 'display: inline-block; text-indent: 0rem; padding-left: 8px !important;'
      )

      basic_search_history_node # Return the basic search history node
    end
  end
end