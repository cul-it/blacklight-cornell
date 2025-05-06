module BlacklightCornell
  class SearchState < Blacklight::SearchState
    # Override has_constraints? to check :q_row for advanced search
    def has_constraints?
      !(query_param.blank? && advanced_query_param.blank? && filter_params.blank? && filters.blank? && clause_params.blank?)
    end

    private

    def advanced_query_param
      params[:q_row]
    end
  end
end
