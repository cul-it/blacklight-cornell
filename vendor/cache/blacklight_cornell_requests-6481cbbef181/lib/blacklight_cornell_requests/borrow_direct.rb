module BlacklightCornellRequests

  module BorrowDirect
    # Main function to call. This exists mostly to wrap the meat of the pazpar2 querying within a begin/rescue block
    # params = { :isbn, :title } - the two parameters that we're using to query Borrow Direct availabiilty.
    # ISBN is best, but title will work if ISBN isn't available.
    def borrowDirect_available? params

      begin
        return _borrowDirect_available? params
      rescue => e
        Rails.logger.info "Error checking borrow direct availability: exception #{e.class.name} : #{e.message}"
        return false
      end

    end

    # Assemble and return a usable BD URL
    def _bd_url env_http_host
      
      host = Rails.configuration.borrow_direct_webservices_host
      host = env_http_host if host.blank?

      if !host.starts_with?('http')
        host = "http://#{host}"
      end
      if !Rails.configuration.borrow_direct_webservices_port.blank?
        return host + ":" + Rails.configuration.borrow_direct_webservices_port.to_s
      end

      return host

    end

    # Initialize a new pazpar2 session. Return a session id on success, or nil on failure
    def _initialize_session(url)
      
      request_url = url + '/search.pz2?command=init'
      response = HTTPClient.get_content(request_url)
      response_parsed = Hash.from_xml(response)
      session_id = response_parsed['init']['session']

    end

    # Actual BD lookup function (this could be called directly, but it lacks the rescue clause in case something fails)
    # params = { :isbn, :title } - the two parameters that we're using to query Borrow Direct availabiilty.
    # ISBN is best, but title will work if ISBN isn't available.
    def _borrowDirect_available? params
      
      if (params[:isbn].blank? && params[:title].blank?) || params[:env_http_host].nil?
        # Rails.logger.info "sk274_debug: No params passed"
        ## no valid params passed
        return false
      end

      base_url = _bd_url params[:env_http_host]

      session_id = _initialize_session base_url
      # TODO: Matt start here
      # Rails.logger.info "session id: #{session_id}"

      ## make pazpar2 search
      isbn = /([a-zA-Z0-9]+)/.match(params[:isbn][0])
      isbn = isbn[1]
      # isbn = params[:isbn][0].scan(/"([a-zA-Z0-9]+)[ "]/)
      # logger.info "isbn:"
      # logger.info isbn.inspect
      if isbn.blank? && !params[:title].blank?
        request_url = base_url + "/search.pz2?session=#{session_id}&command=search&query=ti%3D#{params[:title]}"
      elsif !isbn.blank?
        request_url = base_url + "/search.pz2?session=#{session_id}&command=search&query=isbn%3D#{isbn}"
      else
        return false
      end
      # Rails.logger.info "request url: #{request_url}"
      response = HTTPClient.get_content(request_url)
      response_parsed = Hash.from_xml(response)
      status = response_parsed['search']['status']
      # Rails.logger.info "bd response: " + response_parsed.inspect
      if status != 'OK'
        ## invalid search
        logger.info "Invalid search: #{status}"
        return false
      end

      ## get pazpar2 recid from show command to get record information
      ## make stat request repeatedly to check if the search process finished
      sleep(0.5)
      i = 0
      progress = '0.00'
      request_url = base_url + "/search.pz2?session=#{session_id}&command=stat"
      while (progress != '1.00' && i < 120)
        response = HTTPClient.get_content(request_url)
        response_parsed = Hash.from_xml(response)
        progress = response_parsed['stat']['progress']
        i = i + 1
        sleep(1)
      end
      # logger.info "finished search request in #{i} seconds"
      ## make show request to get record id
      request_url = base_url + "/search.pz2?session=#{session_id}&command=show&start=0&num=2&sort=title:1"
      response = HTTPClient.get_content(request_url)
      response_parsed = Hash.from_xml(response)
      hits = response_parsed['show']['hit']
      if hits.blank? || hits.class == String
        return false
      elsif hits.class == Hash
        return _determine_availablility? base_url, session_id, hits
      elsif hits.class == Array
        hits.each do |hit|
          return true if _determine_availablility? base_url, session_id, hit
        end
      else
        ## error?
      end

      ## get record for each hit returned until we find first available item or there is no more
      return false
    end

    def _determine_availablility? borrow_direct_webservices_url, session_id, hit
      recid = hit['recid']
      request_url = borrow_direct_webservices_url + "/search.pz2?session=#{session_id}&command=record&id=#{recid}"
      response = HTTPClient.get_content(URI::escape(request_url))
      response_parsed = Hash.from_xml(response)
      availabilities = response_parsed['record']['location']['md_available']
      if availabilities.class == String
        if availabilities.strip == 'Available'
          return true
        end
      elsif availabilities.class == Array
        availabilities.each do |availability|
          if availability.strip == 'Available'
            return true
          end
        end
      else
        ## what is this?
        # logger.debug availabilities.inspect
        return false
      end
    end

  end

end