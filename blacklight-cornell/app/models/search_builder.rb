# frozen_string_literal: false
# operations on strings are so prevalent must unfreeze them.
class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include BlacklightRangeLimit::RangeLimitBuilder
  include SolrQueryBuilder

  self.default_processor_chain += [:sortby_title_when_browsing, :sortby_callnum, :set_fl, :set_fq, :set_query, :homepage_default]

  def sortby_title_when_browsing user_parameters
    # if no search term is submitted and user hasn't specified a sort
    # assume browsing and use the browsing sort field
    if user_parameters[:q].blank? and user_parameters[:sort].blank?
      browsing_sortby =  blacklight_config.sort_fields.values.select { |field| field.browse_default == true }.first
    end
  end

  # Removes unnecessary elements from the solr query when the homepage is loaded.
  # The check for the q parameter ensures that searches, including empty searches, and
  # advanced searches are not affected.
  def homepage_default user_parameters
    if !user_parameters['facet.field'].kind_of?(Array) || user_parameters['facet.field'].count == 1
      # this is a request for a facet page, like /catalog/facet/author_facet
    elsif user_parameters['q'].nil? && user_parameters['fq'].blank?
      user_parameters = streamline_query(user_parameters)
    end
  end

  #sort call number searches by call number
  def sortby_callnum user_parameters
    if blacklight_params[:search_field] == 'lc_callnum' && blacklight_params[:sort].nil?
       callnum_sortby =  blacklight_config.sort_fields.values.select { |field| field.callnum_default == true }.first
       user_parameters[:sort] = callnum_sortby.field
    end
  end

  def set_fl solr_parameters
    # Overrides default fl set in solrconfig to return all stored fields
    solr_parameters[:fl] = '*' if blacklight_params['controller'] == 'bookmarks' || blacklight_params['format'].present? || blacklight_params['controller'] == 'book_bags'
  end

  # Add any facets not already defined by blacklight to the solr fq
  # Useful for backend cataloging work
  def set_fq solr_parameters
    if blacklight_params[:f].present?
      solr_parameters[:fq] = solr_parameters[:fq] || []
      blacklight_params[:f].each do |key, value|
        unless blacklight_config.facet_fields.keys.include?(key)
          value.each do |val|
            fq_string = "{!term f=#{key.to_s}}#{val}"
            solr_parameters[:fq] << fq_string
          end
        end
      end
    end
  end

  # Sets solr q param from search fields, booleans, and ops (simple and advanced search)
  def set_query solr_parameters
    # Multiple actions run through this SearchBuilder - only set_query for simple and advanced searches
    if blacklight_params[:q_row].present? || blacklight_params[:search_field].present?
      # Standard blacklight_params from advanced search form:
      # {
      #   "advanced_query"=>"yes", 
      #   "boolean_row"=>{"1"=>"AND"},
      #   "commit"=>"Search", 
      #   "op_row"=>["AND", "AND"], 
      #   "q_row"=>["test", ""], 
      #   "range_end"=>"2025", 
      #   "range_field"=>"pub_date_facet", 
      #   "range_start"=>"0", 
      #   "search_field"=>"advanced", 
      #   "search_field_row"=>["all_fields", "all_fields"], 
      #   "sort"=>"score desc, pub_date_sort desc, title_sort asc", 
      #   "utf8"=>"✓", 
      #   "controller"=>"catalog", 
      #   "action"=>"range_limit"
      # }
      # For non-standard advanced search params, use presence of q_row to determine if query should be processed as advanced search
      if blacklight_params[:q_row].present?
        # Build solr q param for advanced search
        # Clean up/reset non-standard advanced search params
        blacklight_params.delete('q')
        solr_parameters[:search_field] = 'advanced'
      elsif blacklight_params[:search_field].present?
        # Remove any unexpected advanced search params
        if blacklight_params[:advanced_query].present?
          blacklight_params.delete(:advanced_query)
          blacklight_params.delete(:search_field_row)
          blacklight_params.delete(:op_row)
          blacklight_params.delete(:boolean_row)
          blacklight_params.delete(:count)
        end
      end

      # Set solr q param for simple and advanced search
      solr_parameters[:q] = build_solr_q(blacklight_params)
    end
  end

  def streamline_query(user_params)
    homepage_facets = ["online", "format", "language_facet", "location", "hierarchy_facet"]
    user_params['facet.field'] = homepage_facets
    user_params['stats'] = false
    user_params['stats.field'] = []
    user_params['rows'] = 0
    user_params.delete('sort')
    user_params.delete('f.lc_callnum_facet.facet.limit')
    user_params.delete('f.lc_callnum_facet.facet.sort')
    user_params.delete('f.author_facet.facet.limit')
    user_params.delete('f.fast_topic_facet.facet.limit')
    user_params.delete('f.fast_geo_facet.facet.limit')
    user_params.delete('f.fast_era_facet.facet.limit')
    user_params.delete('f.fast_genre_facet.facet.limit')
    user_params.delete('f.subject_content_facet.facet.limit')
    user_params.delete('f.lc_alpha_facet.facet.limit')
    return user_params
  end
end
