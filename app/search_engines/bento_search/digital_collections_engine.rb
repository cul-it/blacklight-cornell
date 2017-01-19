class BentoSearch::DigitalCollectionsEngine

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
    Rails.logger.debug("mjc12test: BlacklightEngine search called. Query is #{args[:query]}}")
    bento_results = BentoSearch::Results.new

    # Format is passed to the engine using the configuration set up in the bento_search initializer
    # If not specified, we can maybe default to books for now.
    format = configuration[:blacklight_format] || 'Digital Collections'

    solr = RSolr.connect :url => 'http://jrc88.solr.library.cornell.edu/solr/digitalcollections'
    solr_response = solr.get 'select', :params => {
                                        :q => args[:query],
                                        :rows => args[:per_page]
                                       }
    Rails.logger.debug "mjc12test: #{solr_response}"

    results = solr_response['response']['docs']

    results.each do |i|
      item = BentoSearch::ResultItem.new
      item.title = i['title_tesim'].to_s
     
      item.link = "http://digital.library.cornell.edu/catalog/#{i['id']}"
      bento_results << item
    end
    bento_results.total_items = solr_response['response']['numFound']

    return bento_results

  end


end
