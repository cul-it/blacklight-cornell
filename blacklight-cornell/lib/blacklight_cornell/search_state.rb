module BlacklightCornell
  class SearchState < Blacklight::SearchState
    # Override has_constraints? to check :q_row for advanced search
    def has_constraints?
      !(query_param.blank? && advanced_query_param.blank? && filter_params.blank? && filters.blank? && clause_params.blank?)
    end

    def advanced_query_param
      params[:q_row]
    end

    # Retain facet, sort, and per_page from sanitized params for search
    def facet_params_for_search(params_to_merge = {})
      params_for_search(params_to_merge).slice(:f, :f_inclusive, :per_page, :range, :sort)
    end
  end
end
