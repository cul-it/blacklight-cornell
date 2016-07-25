require 'dotenv'
require 'borrow_direct'

module BlacklightCornellRequests

  module CULBorrowDirect

    ######################## NOTE: THIS LIBRARY IS NO LONGER IN USE ##################
    #
    # The two functions below have been moved into request.rb. This whole file can
    # probably be deleted sooner or later (along with its rspec file).
    #
    ##################################################################################

    # Determine Borrow Direct availability for an ISBN or title
    # params = { :isbn, :title }
    # ISBN is best, but title will work if ISBN isn't available.
    def self.available_in_bd? netid, params

      # Set up params for BorrowDirect gem
      if Rails.env.production?
        # if this isn't specified, defaults to BD test database
    #    BorrowDirect::Defaults.api_base = BorrowDirect::Defaults::PRODUCTION_API_BASE
      end
      BorrowDirect::Defaults.library_symbol = "CORNELL"
      BorrowDirect::Defaults.find_item_patron_barcode = patron_barcode(netid)
      BorrowDirect::Defaults.timeout = 15 # (seconds)

      ####### possible FALSE test isbn?
      #response = BorrowDirect::FindItem.new.find(:isbn => "1212121212")

      response = nil
      # This block can throw timeout errors if BD takes to long to respond
      begin
        if !params[:isbn].nil?
          response = BorrowDirect::FindItem.new.find(:isbn => params[:isbn])
        elsif !params[:title].nil?
          response = BorrowDirect::FindItem.new.find(:phrase => params[:title])
        end

        return response.requestable?

      rescue BorrowDirect::HttpTimeoutError
        Rails.logger.warn 'Requests: Borrow Direct check timed out'

      end

    end

    # Use the external netid lookup script to figure out the patron's barcode
    # (this might duplicate what's being done in the voyager_request patron method)
    def self.patron_barcode(netid)

      uri = URI.parse(ENV['NETID_URL'] + "?netid=#{netid}")
      response = Net::HTTP.get_response(uri)

      # Make sure that we got a real result. Unfortunately, the CGI doesn't
      # return a nice error code
      return nil if response.body.include? 'Software error'

      # Return the barcode
      JSON.parse(response.body)['bc']

    end

    # # Assemble and return a usable BD URL
    # def _bd_url env_http_host
    #
    #   host = Rails.configuration.borrow_direct_webservices_host
    #   host = env_http_host if host.blank?
    #
    #   if !host.starts_with?('http')
    #     host = "http://#{host}"
    #   end
    #   if !Rails.configuration.borrow_direct_webservices_port.blank?
    #     return host + ":" + Rails.configuration.borrow_direct_webservices_port.to_s
    #   end
    #
    #   return host
    #
    # end
    #
    # # Initialize a new pazpar2 session. Return a session id on success, or nil on failure
    # def _initialize_session(url)
    #
    #   request_url = url + '/search.pz2?command=init'
    #   response = HTTPClient.get_content(request_url)
    #   response_parsed = Hash.from_xml(response)
    #   session_id = response_parsed['init']['session']
    #
    # end
    #
    # # Actual BD lookup function (this could be called directly, but it lacks the rescue clause in case something fails)
    # # params = { :isbn, :title } - the two parameters that we're using to query Borrow Direct availabiilty.
    # # ISBN is best, but title will work if ISBN isn't available.
    # def _borrowDirect_available? params
    #
    #   if (params[:isbn].blank? && params[:title].blank?) || params[:env_http_host].nil?
    #     # Rails.logger.info "sk274_debug: No params passed"
    #     ## no valid params passed
    #     return false
    #   end
    #
    #   isbn = params[:isbn]
    #   if isbn.present?
    #     isbn = /([a-zA-Z0-9]+)/.match(params[:isbn][0])
    #     isbn = isbn[1]
    #   end
    #
    #   search_params = nil
    #   if isbn.blank? && !params[:title].blank?
    #     # Do a title search
    #     search_params = "@attr 1=4 #{params[:title].gsub(' ', '+')}"
    #   elsif !isbn.blank?
    #     # Do an isbn search
    #     search_params = "@attr 1=7 #{isbn}}"
    #   else
    #     return false
    #   end
    #
    #   servers = [
    #     ['josiah.brown.edu', 210, 'INNOPAC'],   # 'available'
    #     ['clio-db.cc.columbia.edu', 7090, 'voyager'], # 'circulations'
    #     ['catalog-lib.dartmouth.edu', 210, 'innopac'], # 'available'
    #     ['catalog.lib.jhu.edu', 210, 'ipac'],     # 'circulations'
    #     ['library.mit.edu', 9909, 'mit01pub'],      # NIL?!
    #     ['catalog.princeton.edu', 7090, 'voyager'], # 'circulations'
    #     ['libcat.uchicago.edu', 210, 'uofc'],   # 'circulations'
    #     ['z3950.franklin.library.upenn.edu', 7090, 'voyager'], #'circulations'
    #     ['prodorbis.library.yale.edu', 7090, 'voyager'] #'circulations'
    #   ]
    #
    #   available = false
    #
    #   # Main z39.50 search loop. For each library server in the list,
    #   # make a connection and search by isbn or title as appropriate.
    #   # As soon as we find a positive result for availability, break
    #   # out and return true so the system can get on with things.
    #   # NOTE: this method only checks general availability, not
    #   # actual Borrow Direct availability. This will give us some
    #   # false positives, but, if we're lucky, not nearly as many
    #   # false positives as the number of false negatives we're currently
    #   # seeing because pazpar2 simply isn't returning results for
    #   # many of these servers!
    #   servers.each do |s|
    #
    #     begin
    #
    #       ZOOM::Connection.open(s[0], s[1]) do |conn|
    #
    #         conn.database_name = s[2]
    #         conn.preferred_record_syntax = 'opac'
    #         results = conn.search(search_params)
    #         #Rails.logger.warn "mjc12test: results: #{results[0].inspect}"
    #         results_xml = Nokogiri::XML(results[0].to_s)
    #
    #         # innopac servers indicate availability in the publicNote field;
    #         # all others in the list (all voyager?) use 'availableNow'
    #         if s[2] == 'INNOPAC' or s[2] == 'innopac'
    #           holdings = results_xml.xpath('//holdings/holding/publicNote')
    #           holdings.each do |h|
    #             available = (h.content == 'AVAILABLE')
    #             if available
    #               Rails.logger.debug "mjc12test: available from #{s[0]}"
    #             end
    #             return true if available
    #           end
    #         else
    #           holdings =results_xml.xpath('//holdings/holding/circulations/circulation/availableNow')
    #           holdings.each do |h|
    #             available = (h.attribute('value').to_s == '1')
    #             if available
    #               Rails.logger.debug "mjc12test: available from #{s[0]}"
    #             end
    #             return true if available
    #           end
    #         end
    #
    #       end # zoom do
    #
    #     rescue => e
    #       Rails.logger.info "Error checking borrow direct availability: exception #{e.class.name} : #{e.message}"
    #     end
    #
    #      return true if available
    #
    #   end # servers.each
    #
    #   return available
    #
    # end # def borrowdirect_available?

  end # module

end
