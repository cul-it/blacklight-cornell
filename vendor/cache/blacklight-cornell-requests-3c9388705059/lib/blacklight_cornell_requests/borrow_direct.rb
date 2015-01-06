require 'zoom'

module BlacklightCornellRequests

  module BorrowDirect

    # Main function to call. This exists mostly to wrap the meat of the pazpar2 querying within a begin/rescue block
    # params = { :isbn, :title } - the two parameters that we're using to query Borrow Direct availabiilty.
    # ISBN is best, but title will work if ISBN isn't available.
    def borrowDirect_available? params

      return _borrowDirect_available? params

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

      isbn = params[:isbn]
      if isbn.present?
        isbn = /([a-zA-Z0-9]+)/.match(params[:isbn][0])
        isbn = isbn[1]
      end

      search_params = nil
      if isbn.blank? && !params[:title].blank?
        # Do a title search
        search_params = "@attr 1=4 #{params[:title].gsub(' ', '+')}"
      elsif !isbn.blank?
        # Do an isbn search
        search_params = "@attr 1=7 #{isbn}}"
      else
        return false
      end

      servers = [
        ['josiah.brown.edu', 210, 'INNOPAC'],   # 'available'
        ['clio-db.cc.columbia.edu', 7090, 'voyager'], # 'circulations'
        ['catalog-lib.dartmouth.edu', 210, 'innopac'], # 'available'
        ['catalog.lib.jhu.edu', 210, 'ipac'],     # 'circulations'
        ['library.mit.edu', 9909, 'mit01pub'],      # NIL?!
        ['catalog.princeton.edu', 7090, 'voyager'], # 'circulations'
        ['libcat.uchicago.edu', 210, 'uofc'],   # 'circulations'
        ['z3950.franklin.library.upenn.edu', 7090, 'voyager'], #'circulations'
        ['prodorbis.library.yale.edu', 7090, 'voyager'] #'circulations'
      ]

      available = false

      # Main z39.50 search loop. For each library server in the list, 
      # make a connection and search by isbn or title as appropriate.
      # As soon as we find a positive result for availability, break
      # out and return true so the system can get on with things.
      # NOTE: this method only checks general availability, not 
      # actual Borrow Direct availability. This will give us some 
      # false positives, but, if we're lucky, not nearly as many
      # false positives as the number of false negatives we're currently
      # seeing because pazpar2 simply isn't returning results for 
      # many of these servers!
      servers.each do |s|

        begin

          ZOOM::Connection.open(s[0], s[1]) do |conn|

            conn.database_name = s[2]
            conn.preferred_record_syntax = 'opac'
            results = conn.search(search_params)
            #Rails.logger.warn "mjc12test: results: #{results[0].inspect}"
            results_xml = Nokogiri::XML(results[0].to_s)

            # innopac servers indicate availability in the publicNote field;
            # all others in the list (all voyager?) use 'availableNow'
            if s[2] == 'INNOPAC' or s[2] == 'innopac'
              holdings = results_xml.xpath('//holdings/holding/publicNote')
              holdings.each do |h|
                available = (h.content == 'AVAILABLE')
                if available
                  Rails.logger.debug "mjc12test: available from #{s[0]}"
                end
                return true if available
              end
            else
              holdings =results_xml.xpath('//holdings/holding/circulations/circulation/availableNow')
              holdings.each do |h|
                available = (h.attribute('value').to_s == '1')
                if available
                  Rails.logger.debug "mjc12test: available from #{s[0]}"
                end
                return true if available
              end
            end

          end # zoom do

        rescue => e
          Rails.logger.info "Error checking borrow direct availability: exception #{e.class.name} : #{e.message}"
        end

         return true if available

      end # servers.each

      return available

    end # def borrowdirect_available?

  end # module

end