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
    base = Addressable::URI.parse("https://digital.library.cornell.edu")
    uri = URI( base + "catalog.bento")
    params = {
      :q => args[:query],
      :utf8 => "✓",
      :search_field => "all_fields",
      :rows => 3
    }
    uri.query = URI.encode_www_form(params)
    url = Addressable::URI.parse(uri)
    url.normalize
    portal_response = JSON.load(URI.open(url))

    # Rails.logger.debug "mjc12test: #{portal_response}"
    if portal_response.nil? || portal_response['response'].nil? || portal_response['response']['docs'].nil?
      results = []
    else
      results = portal_response['response']['docs']
    end

    results.each do |i|

      item = BentoSearch::ResultItem.new
      item.title = i['title_tesim'][0].to_s
      [i['creator_facet_tesim']].each do |a|
        item.authors << a
      end
      if i['collection_tesim'].present? && i['solr_loader_tesim'].present? && i['solr_loader_tesim'][0] == "eCommons"
      item.abstract = i['collection_tesim'][0].to_s + " Collection in eCommons"
      elsif i['collection_tesim'].present?
        item.abstract = i['collection_tesim'][0].to_s
      elsif i['description_tesim'].present?
        item.abstract = i['description_tesim'][0].to_s
      end
      if i['media_URL_size_0_tesim'].present?
        item.format_str = i['media_URL_size_0_tesim'][0].to_s
        end
      if i['date_tesim'].present?
        item.publication_date = i['date_tesim'][0].to_s
      end
      if i['solr_loader_tesim'].present? && i['solr_loader_tesim'][0] == "eCommons"
        item.link =i['handle_tesim'][0]
      else
        url = URI(base + "catalog/#{i['id']}")
        url.normalize
        item.link = url.to_s
      end
      bento_results << item
    end

    if portal_response.nil? || portal_response['response'].nil? || portal_response['response']['pages'].nil? || portal_response['response']['pages']['total_count'].nil?
      bento_results.total_items = 0
    else
      bento_results.total_items = portal_response['response']['pages']['total_count']
    end

    return bento_results

  end


end
