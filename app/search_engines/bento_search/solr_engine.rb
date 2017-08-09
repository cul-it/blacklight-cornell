class BentoSearch::SolrEngine

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
    format = configuration[:blacklight_format] || 'Book'

    solr = RSolr.connect :url => configuration.solr_url
    solr_response = solr.get 'select', :params => {
                                        :q => args[:query],
                                        :fq => "format:\"#{format}\"",
                                        :rows => args[:per_page]
                                       }
    Rails.logger.debug "mjc12test: #{solr_response}"

    results = solr_response['response']['docs']

    results.each do |i|
      item = BentoSearch::ResultItem.new
      item.title = i['title_display'].to_s
      [i['author_display']].each do |a|
        next if a.nil?
        # author_display comes in as a combined name and date with a pipe-delimited display name.
        # bento_search does some slightly odd things to author strings in order to display them,
        # so the raw string coming out of *our* display value turns into nonsense by default
        # Telling to create a new Author with an explicit 'display' value seems to work.
        item.authors << BentoSearch::Author.new({:display => a.split('|')[1][0..-2]})
      end
      item.year = i['pub_date_facet'].to_s
      item.link = "http://newcatalog.library.cornell.edu/catalog/#{i['id']}"
      bento_results << item
    end
    bento_results.total_items = solr_response['response']['numFound']

    return bento_results

  end


end
