class BentoSearch::LibguidesEngine
  include BentoSearch::SearchEngine

  # Next, at a minimum, you need to implement a #search_implementation method,
  # which takes a normalized hash of search instructions as input (see documentation
  # at #normalized_search_arguments), and returns BentoSearch::Results item.
  #
  # The Results object should have #total_items set with total hitcount, and contain
  # BentoSearch::ResultItem objects for each hit in the current page. See individual class
  # documentation for more info.
  def search_implementation(args)
    begin
      # 'args' should be a normalized search arguments hash including the following elements:
      # :query, :per_page, :start, :page, :search_field, :sort
      Rails.logger.debug("mjc12test: BlacklightEngine search called. Query is #{args[:query]}}")
      bento_results = BentoSearch::Results.new

      # Format is passed to the engine using the configuration set up in the bento_search initializer
      # If not specified, we can maybe default to books for now.
      format = configuration[:blacklight_format] || "Research Guides"
      guides_response = []
      path = "http://lgapi-us.libapps.com/1.1/guides/"
      st = args[:query].gsub(/["”“]/, '')
      escaped = { site_id: 45, search_terms: st, status: 1, key: ENV["LIBGUIDES_API_KEY"] }.to_param
      guides_url = path + "?" + escaped
      guides_response = JSON.load(URI.open(guides_url))
    rescue Exception => e
      guides_response = []
      Rails.logger.error "Runtime Error: #{__FILE__} #{__LINE__} Error:: #{e.inspect}"
      Rails.logger.error "Guides URL: " + guides_url
    end

    Rails.logger.debug "mjc12test: #{guides_response}"
    results = guides_response[0, 3]

    results.each do |i|
      item = BentoSearch::ResultItem.new
      item.title = i["name"].to_s
      if i["description"].present?
        item.abstract = i["description"].to_s
      end
      item.link = i["friendly_url"]
      bento_results << item
    end
    bento_results.total_items = 0

    return bento_results
  end
end
