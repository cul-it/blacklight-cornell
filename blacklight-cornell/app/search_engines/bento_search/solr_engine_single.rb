class BentoSearch::SolrEngineSingle
  include BentoSearch::SearchEngine

  include LoggingHelper

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

    # :nocov:
      log_debug_info("#{__FILE__}:#{__LINE__}", ['args:', args])
    # :nocov:

    # Use Blacklight::SearchService to get the search results
    search_params = { q: args[:query], search_field: 'all_fields', bento: true }
    response = BentoSearch::CatalogSearcher.new(search_params).search_response

    # Because all our facets are packaged in a single query, we have to treat this as a single result
    # in order to have bento_search process it correctly. We'll split up into different facets
    # once we get back to the controller!
    bento_results = BentoSearch::Results.new
    result = BentoSearch::ResultItem.new
    result.custom_data = response.group['groups']
    bento_results << result
    bento_results.total_items = 1
    bento_results
  end
end
