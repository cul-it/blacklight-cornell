##########################################################################
## Override Blacklight::SearchHistoryConstraintsHelperBehavior Methods  ##
#########################################################################
module CornellSearchHistoryConstraintsHelper

  # ============================================================================
  # Formats operators and boolean values for display in the search history.
  # Custom logic for advanced searches.
  # Falls back to default rendering for non-advanced searches.
  # ----------------------------------------------------------------------------
  def render_search_to_s_element(label, search_text, _options = {})
    if _options[:search_type] == "advanced search"
      search_history_node = ""
      search_text.each_with_index do |text, index|
        if _options[:op_row][index] == "AND"
          operator = "(AND) "
        elsif _options[:op_row][index] == "OR"
          operator = "(ANY) "
        elsif _options[:op_row][index] == "phrase"
          operator = "(CONTAINS PHRASE) "
        elsif _options[:op_row][index] == "NOT"
          operator = "(NOT) "
        else  _options[:op_row][index] == "begins_with"
        operator = "(BEGINS WITH) "
        end
        if index == 0
          if _options[:op_row][0] == "AND"
            operator = ""
          end
        else
          operator
        end

        if _options[:boolean_row].present?
          boolean = _options[:boolean_row][index.to_s]
          boolean = "(#{boolean})" if boolean.present?
        end

        search_history_node += tag.span(
          render_filter_name("#{boolean} #{operator}  " + label_for_search_field(label[index]))  +
            tag.span(text, class: 'filter-values'),
          class: 'constraint',
          style: 'display: inline-block; margin-right: -5px;'
        )
      end

      search_history_node.html_safe
    else
      tag.span(render_filter_name(label) + tag.span(search_text, class: 'filter-values'), class: 'constraint')
    end
  end
end