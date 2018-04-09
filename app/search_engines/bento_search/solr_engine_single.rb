class BentoSearch::SolrEngineSingle

  include BentoSearch::SearchEngine

  # Next, at a minimum, you need to implement a #search_implementation method,
  # which takes a normalized hash of search instructions as input (see documentation
  # at #normalized_search_arguments), and returns BentoSearch::Results item.
  #
  # The Results object should have #total_items set with total hitcount, and contain
  # BentoSearch::ResultItem objects for each hit in the current page. See individual class
  # documentation for more info.
  def search_implementation(args)

    # 'args' should be a normalized search arguments hash including the following elements:
    # :query, :per_page, :start, :page, :search_field, :sort
    Rails.logger.debug("mjc12test: #{self.class.name} called. Query is #{args[:query]}}")
    bento_results = BentoSearch::Results.new
    # solr search must be transformed to match simple search transformation.
    q = SearchController.transform_query args[:query]
    Rails.logger.debug("mjc12test: BentoSearch::SolrEngineSingle called. #{__FILE__} #{__LINE__} transformed q = #{q}")
    #solr = RSolr.connect :url => 'http://da-prod-solr1.library.cornell.edu/solr/blacklight'
    Rails.logger.debug("mjc12test: #{self.class.name} #{__FILE__} #{__LINE__} url is #{configuration.solr_url}")
    solr = RSolr.connect :url => configuration.solr_url
    solr_response = solr.get 'select', :params => {
                                        :q => q,
                                        #:fq => "format:\"#{format}\"",
                                       # :rows => args[:per_page],
                                        :rows => 20, # from sample single query; should set this dynamically?
                                        :group => true,
                                        'group.field' => 'format_main_facet',
                                        'group.limit' => 3,
                                        'group.ngroups' => 'true',
                                        :sort => 'score desc, pub_date_sort desc, title_sort asc',
                                        :fl => 'id,pub_date_display,format,fulltitle_display,fulltitle_vern_display,author_display,score,pub_info_display,url_access_display,availability_json',
                                        :mm => 1
                                        #:defType => 'edismax'
                                       }

    Rails.logger.debug("mjc12test: BlacklightEngine2 search called. #{__FILE__} #{__LINE__} solr_response #{solr_response}")
    # Because all our facets are packaged in a single query, we have to treat this as a single result
    # in order to have bento_search process it correctly. We'll split up into different facets
    # once we get back to the controller!
    result = BentoSearch::ResultItem.new
    result.custom_data = solr_response['grouped']['format_main_facet']['groups']
    bento_results << result
    bento_results.total_items = 1
    return bento_results

  end


end
