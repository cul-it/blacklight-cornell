module BlacklightCornellRequests
  # @author Matt Connolly, Rick Silterra

  class HoldingsData
    
    attr_reader :bibid     # The bib ID associated with the instance holdings
    attr_reader :document  # The Solr document associated with the bib ID
    attr_reader :holdings  # A parsed object of holdings data based on the holdings service and Solr doc
    
    # Basic initializer
    # 
    # @param bibid [Fixnum] The bibID associated with the holding(s) records
    # @param document [Hash] The Solr document associated with bibid
    def initialize(bibid, document)
      @bibid = bibid
      @document = document
      @holdings = initialize_holdings
    end
    
    def inspect
      puts "hello!"
    end
    
    def mfhds
      @holdings.map { |h| h['mfhd_id'] }.uniq
    end
    
    def items
      @holdings.map { |h| h['item_id'] }
    end
    
    def mfhds_items
      output = Hash.new {|h, k| h[k] = [] }
      @holdings.each do |h|
        if output.keys.include? h['mfhd_id']
          puts "include: #{output}"
          output[h['mfhd_id']] << h['item_id']
        else
          puts "new: #{output}"
          output[h['mfhd_id']] = h['item_id']
        end
      end
      output
    end
    
    # Use @bibid and @document to parse a set of holdings data and assign
    # the result to @holdings
    # 
    # @return [Hash] A completely parsed holdings object
    # @todo refactor this method
    def initialize_holdings
      
      return nil if @bibid.nil?
      
      bibid_s = @bibid.to_s
      
      response = fetch_holdings     
      # Holdings object should (?) look like the following:
      #   {bibid => {bibid => {"records" => ...}}} 
      records = response[bibid_s] && 
                response[bibid_s][bibid_s] && 
                response[bibid_s][bibid_s][:records]
      if records
        
        # Keep track of status and call number for each ITEM id
        status_call_data = parse_status_call records
      
        location_seen = Hash.new
        location_ids = Array.new
        ## assume there is one holdings location per bibid
        call_number = ''
        
        locations = Hash.new
        # Iterate over the holdings record display array from the Solr record.
        # Example iteration:
        #   "{\"id\":\"5248433\",\"modified_date\":\"20030702095332\",
        #   \"copy_number\":\"2\",\"callnos\":[\"Oversize HD205 1962 .S52 
        #   +\"],\"notes\":[],\"holdings_desc\":[\"v.1-2\"],\"recent_holdings_desc\":[],
        #   \"supplemental_holdings_desc\":[],\"index_holdings_desc\":[],\"locations\":
        #   [{\"code\":\"olin\",\"number\":99,\"name\":\"Olin Library\",\"library\":\"Olin Library\"}]}"
        holdrecs = @document[:holdings_record_display]
        #@document[:holdings_record_display].each do |hrd|
        holdrecs.each do |hrd|
          hrdJSON = parseJSON hrd
          hrdJSON[:locations].each do |loc|
            locations[loc[:number].to_s] = loc[:name]
          end
        end# if @document[:holdings_record_display]
  
        holdings = @document[:item_record_display].present? ?
                     @document[:item_record_display].map { |item| parseJSON item } :
                     Array.new

        holdings.each do |holding|
          # For each item record, set status, call number, perm location, and
          # temp location
          holding[:status] = item_status status_call_data[:statuses][holding['item_id'].to_s]
          holding[:call_number] = item_status status_call_data[:call_nums][holding['item_id'].to_s] # ??????????
          holding[:location] = get_holding_location holding, locations
          
      
          
          location_seen[holding[:location]] = 1 unless location_seen[holding[:location]] # is unless necessary?
          exclude_location_list = Array.new
          
          if location_seen[holding[:location]] == 1
            response = Circ_policy_locs.select('CIRC_GROUP_ID').where( 'location_id' =>  holding[:location] )
            
            ## handle exceptions
            ## group id 3  - Olin
            ## group id 19 - Uris
            ## group id 5  - Annex
            ## Olin or Uris can't deliver to itselves and each other
            ## Annex group can deliver to itself
            ## Law group can deliver to itself
            ## Others can't deliver to itself
            # there might not be an entry in this table  
            if response.present? 
              circ_group_id = response[0]['CIRC_GROUP_ID']
              #circ_group_id[0]['CIRC_GROUP_ID'] = res.nil? ? 0 : Float(circ_group_id[0]['CIRC_GROUP_ID'])
              case circ_group_id
                when 3, 19
                  # Include both group ids if Olin or Uris
                  circ_group_id = [3, 19]
                when 5, 14
                  ## skip annex and law library next time
                  location_seen[holding[:location]] = exclude_location_list
                  holding[:exclude_location_id] = exclude_location_list
              end
              
              pickup_locs = Circ_policy_locs.select('location_id').where( :circ_group_id =>  circ_group_id, :pickup_location => 'Y' )
              pickup_locs.each do |loc|
                exclude_location_list.push loc['LOCATION_ID']
              end
              location_seen[holding[:location]] = exclude_location_list
            end # if location_seen[location] == 1
          else
            exclude_location_list = location_seen[holding[:location]]
          end
          
          holding[:exclude_location_id] = exclude_location_list
        
        end # holdings.each do |holding|
      end # if records
      
      holdings

    end
    
    # Given a holdings record, parse out and return all the statuses and call numbers
    # it contains
    #
    # @param records [Hash] A group of records from a call to the holdings service
    # @return [Hash] A list of :statuses and a list of :call_nums
    def parse_status_call records
      
      statuses = {}
      call_numbers = {}
      
      # Each record lists the different holdings records associated with one bibid (?)
      records.each do |record|
        # Safety check: the inner bibid *should* be the same as the outer one (maybe? Rick isn't)
        # quite sure), but we'll check here so we don't end up parsing something we don't want.
        if record[:bibid].to_s == @bibid.to_s
          # Each holding is for a particular item ID
          record[:holdings].each do |holding|
            # item statuses and call numbers are keyed by item ID
            statuses[holding[:ITEM_ID].to_s]     = holding[:ITEM_STATUS]
            call_numbers[holding[:ITEM_ID].to_s] = holding[:DISPLAY_CALL_NO]
          end
        end
      end

      return { :statuses => statuses, :call_nums => call_numbers }

    end
    
    
    def get_holding_location holding, locations
      
      location = holding[:perm_location]
      if location.is_a?(Hash)
        location = location['number'].to_s 
      end
      if holding[:temp_location].is_a?(Hash)
        temp_location_s = holding[:temp_location]['number'].to_s 
        temp_location =  holding[:temp_location]
      else 
        temp_location_s = holding[:temp_location]
      end

      # Use perm location if temp location isn't set
      if temp_location_s == '0'
        return locations[holding[:perm_location].to_s]
      else
        # Use temp location
        if temp_location.is_a?(Hash)
          holding[:location] = temp_location[:name]
        else
          Rails.logger.warn "#{__FILE__}:#{__LINE__} Cannot use temp location (not a hash). Your solr database is not up to date.: #{temp_location.inspect}"
          return nil
        end
      end
    end
    
    def parseJSON data
      JSON.parse(data).with_indifferent_access
    end
    
    #private
    
      # Retrieve a holdings record from the holdings service. Requires
      # that @bibid be set
      # 
      # @return [Hash] A JSON hash of holdings data
      def fetch_holdings
        parseJSON(HTTPClient.get_content(Rails.configuration.voyager_holdings + "/holdings/status_short/#{@bibid}"))
      end

      # Locate and translate the item status from the holdings data
      # into the 'real' code (for purposes of making a request)
      # 
      # @param item_status [Int] An item status code
      # @return [Int] Another item status code
      def item_status item_status

        case item_status
          when STATUSES[:discharged],
               STATUSES[:catalog_review],
               STATUSES[:circulation_review],
               STATUSES[:in_transit],
               STATUSES[:in_transit_discharged]
            return STATUSES[:not_charged]

          when STATUSES[:renewed],
               STATUSES[:call_slip_request],
               STATUSES[:recall_request],
               STATUSES[:hold_request],
               STATUSES[:in_transit_on_hold],
               STATUSES[:overdue],
               STATUSES[:claims_returned],
               STATUSES[:damaged],
               STATUSES[:withdrawn],
               STATUSES[:on_hold]
            return STATUSES[:charged]

          when STATUSES[:lost_library_applied],
               STATUSES[:lost_system_applied]
            return STATUSES[:lost]

          else
            # covers self-returning statuses 
            # like LOST, MISSING, AT_BINDERY, CHARGED, NOT_CHARGED
            return item_status
        end

      end
    
  end # class
  
end