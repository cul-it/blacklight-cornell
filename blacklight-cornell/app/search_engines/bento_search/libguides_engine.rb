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
      bento_results = BentoSearch::Results.new
      token = get_auth_token
      guides_response = get_guides_response(args[:query], token)
    end

    results = guides_response[0, 3]

    results.each do |i|
      item = BentoSearch::ResultItem.new
      item.title = i["name"].to_s
      item.abstract = i["description"].to_s if i["description"].present?
      item.link = i["friendly_url"]
      bento_results << item
    end
    
    bento_results.total_items = 0
    return bento_results
  end

  def get_guides_response(search_terms, token)
    uri = URI("#{ENV["LIBGUIDES_API_URL"]}/guides")
    uri.query = URI.encode_www_form({ search_terms: search_terms, sort_by: "relevance", status: 1 })
    response = Net::HTTP.get_response(uri, { "Authorization" => "Bearer #{token}" })

    if response.is_a? Net::HTTPSuccess
      JSON.parse(response.body)
    else
      Rails.logger.error "Net::HTTP Error for #{uri}. HTTP response: #{response.inspect}"
      []
    end
  end

  def get_auth_token
    cached = Rails.cache.read(cache_key)
    if cached.present? && cached[:expires_at] > Time.current.to_i + 60
      cached[:access_token].to_s
    else
      client_id = ENV["LIBGUIDES_CLIENT_ID"]
      client_secret = ENV["LIBGUIDES_CLIENT_SECRET"]

      uri = URI("#{ENV["LIBGUIDES_API_URL"]}/oauth/token")
      client_data = { client_id: client_id, client_secret: client_secret, grant_type: "client_credentials" }
      response = Net::HTTP.post_form(uri, client_data)

      if response.is_a? Net::HTTPSuccess
        token_data = JSON.parse(response.body)
        access_token = token_data["access_token"].to_s
        expires_in = token_data["expires_in"].to_i
        expires_at = (Time.current + (expires_in.present? ? expires_in : 3600).seconds).to_i

        Rails.logger.info "Caching new LibGuides auth token"
        write_cached_token(access_token, expires_in, expires_at)
        access_token
      else
        Rails.logger.error "Net::HTTP Error for #{uri}. HTTP response: #{response.inspect}"
        nil
      end
    end

    rescue StandardError => e
      nil
  end

  private
    def cache_key
      "libguides_auth_token"
    end

    def write_cached_token(access_token, expires_in, expires_at)
      payload = { access_token: access_token, expires_at: expires_at }
      Rails.cache.write(cache_key, payload, expires_in: expires_in)
    end
end
