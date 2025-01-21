##########################################################################
## Override Blacklight::SearchHistoryConstraintsHelperBehavior Methods  ##
#########################################################################
module CornellSearchHistoryConstraintsHelper

  # ============================================================================
  # Formats operators and boolean values for display in the search history.
  # Custom logic for advanced searches.
  # Falls back to default rendering for non-advanced searches.
  # # ----------------------------------------------------------------------------
  def render_search_to_s_element(label, query_text, options = {})
    if options[:search_type] == "advanced search"
      search_history_node = ""
        query_text.each_with_index do |text, index|
          op_val = options[:op_row][index]
          operator = case op_val
                     when "AND"         then ""
                     when "OR"          then "ANY"
                     when "phrase"      then "CONTAINS PHRASE"
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
          space = " " if index > 0
          label_span = render_filter_name("#{space}#{label_parts.join(" ")}")

          # Render the query text in a separate span with 'filter-values' class
          query_span = tag.span(" #{text}", class: 'filter-values')

          # Combine both spans in a constraint container
          search_history_node += tag.span(label_span + query_span, class: 'constraint', style: 'display: inline-block; margin-right: -8px; text-decoration: underline;')
        end
      search_history_node.html_safe
    else
      tag.span(render_filter_name(label) + tag.span(query_text, class: 'filter-values'), class: 'constraint')
    end
  end
end