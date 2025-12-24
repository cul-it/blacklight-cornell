module BlacklightCornell
  class SearchState < Blacklight::SearchState
    # Override has_constraints? to check :q_row for advanced search
    def has_constraints?
      !(query_param.blank? && advanced_query_param.blank? && filter_params.blank? && filters.blank? && clause_params.blank?)
    end

    def advanced_query_param
      params[:q_row]
    end

    ############################################################################
    ##  Resolves -- DEPRECATION WARNING:
    ##  add_facet_params is deprecated and will be removed from a future release
    ##  (Use filter(field).add(item) instead).
    ## -------------------------------------------------------------------------
    def add_facet_params_and_redirect(field, item)
      new_params = filter(field).add(item).params.to_h.with_indifferent_access
      request_keys = blacklight_config.facet_paginator_class.request_keys
      new_params.extract!(*request_keys.values)
      new_params
    end
  end
end
