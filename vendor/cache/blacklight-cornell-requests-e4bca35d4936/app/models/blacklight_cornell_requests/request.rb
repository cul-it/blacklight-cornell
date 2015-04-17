require 'blacklight_cornell_requests/cornell'
#require 'blacklight_cornell_requests/borrow_direct'
require 'borrow_direct'

module BlacklightCornellRequests
  class Request

    L2L = 'l2l'
    BD = 'bd'
    HOLD = 'hold'
    RECALL = 'recall'
    PURCHASE = 'purchase' # Note: this is a *purchase request*, which is different from a patron-driven acquisition
    PDA = 'pda'
    ILL = 'ill'
    ASK_CIRCULATION = 'circ'
    ASK_LIBRARIAN = 'ask'
    LIBRARY_ANNEX = 'Library Annex'
    DOCUMENT_DELIVERY = 'document_delivery'
    # The doc del form can't be pre-populated as we do with the ILL form, so the URL is constant
    DOCUMENT_DELIVERY_URL = ENV['ILLIAD_URL'] + '?Action=10&Form=22'
    HOLD_PADDING_TIME = 3
    OCLC_TYPE_ID = 'OCoLC'
    
    NOT_CHARGED = 1
    CHARGED = 2
    RENEWED = 3
    OVERDUE = 4
    RECALL_REQUEST = 5
    HOLD_REQUEST = 6
    ON_HOLD = 7
    IN_TRANSIT = 8
    IN_TRANSIT_DISCHARGED = 9
    IN_TRANSIT_ON_HOLD = 10
    DISCHARGED = 11
    MISSING = 12
    LOST_LIBRARY_APPLIED = 13
    LOST_SYSTEM_APPLIED = 14
    LOST = 26 # means LOST_LIBRARY_APPLIED or LOST_SYSTEM_APPLIED
    CLAIMS_RETURNED = 15
    DAMAGED = 16
    WITHDRAWN = 17
    AT_BINDERY = 18
    CATALOG_REVIEW =19
    CIRCULATION_REVIEW = 20
    SCHEDULED = 21
    IN_PROCESS = 22
    CALL_SLIP_REQUEST = 23
    SHORT_LOAN_REQUEST = 24
    REMOTE_STORAGE_REQUEST = 25
    REQUESTED = 27

    # attr_accessible :title, :body
    include ActiveModel::Validations
    include Cornell::LDAP
    include BorrowDirect

    attr_accessor :bibid, :holdings_data, :service, :document, :request_options, :alternate_options
    attr_accessor :au, :ti, :isbn, :document, :ill_link, :pub_info, :netid, :estimate, :items, :volumes, :all_items, :in_borrow_direct
    attr_accessor :L2L, :BD, :HOLD, :RECALL, :PURCHASE, :PDA, :ILL, :ASK_CIRCULATION, :ASK_LIBRARIAN, :DOCUMENT_DELIVERY
    attr_accessor :NOT_CHARGED, :CHARGED, :RENEWED, :OVERDUE, :RECALL_REQUEST, :HOLD_REQUEST, :ON_HOLD
    attr_accessor :IN_TRANSIT, :IN_TRANSIT_DISCHARGED, :IN_TRANSIT_ON_HOLD, :DISCHARGED, :MISSING
    attr_accessor :LOST_LIBRARY_APPLIED, :LOST_SYSTEM_APPLIED, :LOST, :CLAIMS_RETURNED, :DAMAGED
    attr_accessor :WITHDRAWN, :AT_BINDERY, :CATALOG_REVIEW, :CIRCULATION_REVIEW, :SCHEDULED, :IN_PROCESS
    attr_accessor :CALL_SLIP_REQUEST, :SHORT_LOAN_REQUEST, :REMOTE_STORAGE_REQUEST, :REQUESTED
    validates_presence_of :bibid
    def save(validate = true)
      validate ? valid? : true
    end

    def initialize(bibid)
      self.bibid = bibid
      @bd = nil
    end

    def save!
      save
    end

    def get_hold_padding
      HOLD_PADDING_TIME
    end

    ##################### Calculate optimum request method ##################### 
    def magic_request(document, env_http_host, options = {})
      target = options[:target]
      volume = options[:volume]
      request_options = []
      alternate_options = []
      service = ASK_LIBRARIAN

      if self.bibid.nil?
        self.request_options = request_options
        self.service = { :service => service }
        self.document = document
        return
      end

      # Get holdings
      self.holdings_data = get_holdings document unless self.holdings_data
      Rails.logger.debug "es287_log :#{__FILE__}:#{__LINE__} holdings data returned."+ Time.new.inspect

      # Check borrow direct availability
      bd_params = { :isbn => document[:isbn_display], :title => document[:title_display], :env_http_host => env_http_host }
      self.in_borrow_direct = available_in_bd? self.netid, bd_params


      # Get item status and location for each item in each holdings record; store in working_items
      # We now have two item arrays! working_items (which eventually gets set in self.items) is a 
      # list of all 'active' items, e.g., those for a particular volume or other set. 
      # self.all_items includes *all* the items in the holdings data for the bibid, so that we can
      # use that list to, for example, obtain a list of all the volumes in the bibid.
      working_items = []
      self.all_items = []
      item_status = CHARGED
      self.holdings_data.each do |h|
        self.all_items.push h # Everything goes into all_items
        # If volume is specified, only populate items with matching enum/chron/year values
        # Unpack volume if necessary
        if volume.present?
          parts = volume.split '|'
          e = parts[1] || ''
          c = parts[2] || ''
          y = parts[3] || ''

          # Require a match on all three iterator values to determine a match
          next if ( y != h[:year] or c != h[:chron] or e != h[:item_enum])
        end
          
        # Only a subset of all_items gets put into working_items
        working_items.push h
      end

      self.items = working_items
      self.document = document
      #Rails.logger.debug "es287_log :#{__FILE__}:#{__LINE__} working items processed. number of items: #{self.items.size} at"+ Time.new.inspect

      unless document.nil?

        # Iterate through all items and get list of delivery methods
      #  bd_params = { :isbn => document[:isbn_display], :title => document[:title_display], :env_http_host => env_http_host }
        n = 0
        working_items.each do |item|
          n = n + 1
          #Rails.logger.debug "es287_log :#{__FILE__}:#{__LINE__} prepare for deliv options for each item. (#{n})"+ Time.new.inspect
          services = get_delivery_options item
          #Rails.logger.debug "es287_log :#{__FILE__}:#{__LINE__} delivoptions for each item. (#{n}) (#{service.inspect})"+ Time.new.inspect
          item[:services] = services
        end
        populate_document_values
        
      #Rails.logger.debug "es287_log :#{__FILE__}:#{__LINE__} services established for each item."+ Time.new.inspect
        
        # handle pda
        patron_type = get_patron_type self.netid
        if patron_type == 'cornell' && !document['url_pda_display'].blank?
          self.document = document
          
          pda_url = document[:url_pda_display][0]
          pda_url, note = pda_url.split('|')
          iids = { :itemid => 'pda', :url => pda_url, :note => note }
          pda_entry = { :service => PDA, :iid => iids, :estimate => get_delivery_time(PDA, nil) }
          
          bd_entry = nil
          if available_in_bd? self.netid, bd_params
            bd_entry = { :service => BD, :iid => {}, :estimate => get_delivery_time(BD, nil) }
          end
          ill_entry = { :service => ILL, :iid => {}, :estimate => get_delivery_time(ILL, nil) }
          self.request_options = request_options
          if target.blank? or target == PDA
            self.service = PDA
            request_options.push pda_entry
            alternate_options.push bd_entry unless bd_entry.nil?
            alternate_options.push ill_entry
          elsif target == BD
            self.service = BD
            request_options.push bd_entry
            alternate_options.push pda_entry
            alternate_options.push ill_entry
          elsif target == ILL
            self.service = ILL
            request_options.push ill_entry
            alternate_options.push pda_entry
            alternate_options.push bd_entry unless bd_entry.nil?
          end
          
          self.request_options = request_options
          self.alternate_options = alternate_options

          populate_options self.service, request_options 
          return
        end
      #Rails.logger.debug "es287_log :#{__FILE__}:#{__LINE__} bd/pda processed."+ Time.new.inspect

      #Rails.logger.debug "es287_log :#{__FILE__}:#{__LINE__} self request options: #{self.request_options}"
        # Determine whether this is a multi-volume thing or not (i.e, multi-copy)
        # They will be handled differently depending
        if self.document[:multivol_b] and volume.blank?
          # Multi-volume
          self.set_volumes(working_items)
        else

          # Multi-copy
          working_items.each do |item|
            request_options.push *item[:services]
          end
          request_options = sort_request_options request_options
        end

      end

      #Rails.logger.debug "es287_log :#{__FILE__}:#{__LINE__} self request options: #{self.request_options}"
      if  working_items.size < 1 
        hld_entry = {:service => HOLD, :location => '', :status => ''}
        request_options.push hld_entry
      end
      if !target.blank?
        self.service = target
      elsif request_options.present?
        # Don't present document delivery as the default option unless
        # there's no other choice
        if (request_options[0][:service] == DOCUMENT_DELIVERY) and 
           (request_options.length > 1)

           # There may be more than one DD option in the queue, so we have to
           # check the whole list. (There really shouldn't be more than one,
           # probably!)
           index = request_options.index{ |o| o[:service] != DOCUMENT_DELIVERY }
           request_options[0], request_options[index] = request_options[index], request_options[0]
        end

        self.service = request_options[0][:service]
      else
        self.service = ASK_LIBRARIAN
      end

      request_options.push ( { :service => ASK_LIBRARIAN, :estimate => get_delivery_time( ASK_LIBRARIAN, nil ) } )
      populate_options self.service, request_options unless self.service == ASK_LIBRARIAN

      self.document = document
    end
    
    def populate_options target, request_options
      self.alternate_options = []
      self.request_options = []
      seen = {}
      request_options.each do |option|
        if option[:service] == target
          self.estimate = option[:estimate] if self.estimate.blank?
          self.request_options.push option
        else
          if seen[option[:service]].blank?
            self.alternate_options.push option
            seen[option[:service]] = 1
          end
        end
      end
    end

    # set the class volumes from a list of item records
    def set_volumes(items) 
      volumes = {}
      num_enum = 0
      num_chron = 0
      num_year = 0
      
      ## take first integer from each of enum, chron and year
      ## if not populated, use big number to rank low
      ## if the field is blank, use 'z' to rank low
      ## record number of occurances for each of the 
      items.each do |item|
        
        # item[:numeric_enumeration] = item[:item_enum][/\d+/]  
        enums = item[:item_enum].scan(/\d+/)  
        if enums.count > 0  
          numeric_enumeration = ''  
          enums.each do |enum|  
            numeric_enumeration = numeric_enumeration + enum.rjust(9,'0')  
          end  
          item[:numeric_enumeration] = numeric_enumeration
          num_enum = num_enum + 1
        else
          item[:numeric_enumeration] = '999999999'
        end
        
        item[:numeric_chron] = item[:chron][/\d+/]
        if !item[:numeric_chron].blank?
          item[:numeric_chron] = item[:numeric_chron].to_i
          num_chron = num_chron + 1
        else
          item[:numeric_chron] = 999999999
        end
        
        item[:numeric_year] = item[:year][/\d+/]
        if !item[:numeric_year].blank?
          item[:numeric_year] = item[:numeric_year].to_i
          num_year = num_year + 1
        else
          item[:numeric_year] = 999999999
        end
        
        if item[:item_enum].blank?  
          item[:item_enum_compare] = 'z'  
        else  
          item[:item_enum_compare] = item[:item_enum]  
        end
        
        if item[:chron].blank?  
          item[:chron_compare] = 'z'  
          item[:chron_month] = 13  
        else  
          item[:chron_compare] = item[:chron].delete(' ')  
          item[:chron_month] = Date::ABBR_MONTHNAMES.index(item[:chron]).to_i  
        end
        
        if item[:year].blank?
          item[:year_compare] = 'z'
        else
          item[:year_compare] = item[:year]
        end
      end

      ## sort based on number of occurances of each of three fields
      ## when tied, year has highest weight followed by enum
      sorted_items = {}
      if num_year >= num_enum and num_year >= num_chron
        if num_enum >= num_chron
          sorted_items = items.sort_by {|h| [ h[:numeric_year],h[:year_compare],h[:numeric_enumeration],h[:item_enum_compare],h[:numeric_chron],h[:chron_month],h[:chron_compare] ]}
        else
          sorted_items = items.sort_by {|h| [ h[:numeric_year],h[:year_compare],h[:numeric_chron],h[:chron_month],h[:chron_compare],h[:numeric_enumeration],h[:item_enum_compare] ]}
        end
      elsif num_enum >= num_chron and num_enum >= num_year
        if num_year >= num_chron
          sorted_items = items.sort_by {|h| [ h[:numeric_enumeration],h[:item_enum_compare],h[:numeric_year],h[:year_compare],h[:numeric_chron],h[:chron_month],h[:chron_compare] ]}
        else
          sorted_items = items.sort_by {|h| [ h[:numeric_enumeration],h[:item_enum_compare],h[:numeric_chron],h[:chron_month],h[:chron_compare],h[:numeric_year],h[:year_compare] ]}
        end
      else
        if num_year >= num_enum
          sorted_items = items.sort_by {|h| [ h[:numeric_chron],h[:chron_month],h[:chron_compare],h[:numeric_year],h[:year_compare],h[:numeric_enumeration],h[:item_enum_compare] ]}
        else
          sorted_items = items.sort_by {|h| [ h[:numeric_chron],h[:chron_month],h[:chron_compare],h[:numeric_enumeration],h[:item_enum_compare],h[:numeric_year],h[:year_compare] ]}
        end
      end
      
      ## as of ruby 1.9, hash preserves insertion order
      sorted_items.each do |item|
        e = item[:item_enum]
        c = item[:chron]
        y = item[:year]
        
        next if e.blank? and c.blank? and y.blank?

        # if e.present? and c.blank? and y.blank?
          # volumes[e] = "|#{e}|||"
        # elsif c.present? and e.blank? and y.blank?
          # volumes[c] = "||#{c}||"
        # elsif y.present? and e.blank? and c.blank?
          # volumes[y] = "|||#{y}|"
        # else
          # label = ''
          # [e, c, y].each do |element|
            # if element.present?
              # label += ' - ' unless label == ''
              # label += element
            # end
          # end
          # volumes[label] = "|#{e}|#{c}|#{y}|"
        # end
        
        label = ''
        [e, c, y].each do |element|
          if element.present?
            label += ' - ' unless label == ''
            label += element
          end
        end
        volumes[label] = "|#{e}|#{c}|#{y}|"

      end
      
      self.volumes = volumes
    end

    ##################### Manipulate holdings data #####################

    # Set holdings data from the Voyager service configured in the
    # environments file.
    # holdings_param = { :bibid => <bibid>, :type => retrieve|retrieve_detail_raw}
    def get_holdings document
      #Rails.logger.debug "es287_log: #{__FILE__} #{__LINE__} entered get_holdings"
      holdings = document[:item_record_display].present? ? document[:item_record_display].map { |item| parseJSON item } : Array.new
      #Rails.logger.debug "es287_log: #{__FILE__} #{__LINE__} #{holdings.inspect}"
      return nil unless self.bibid

      response = parseJSON(HTTPClient.get_content(Rails.configuration.voyager_holdings + "/holdings/status_short/#{self.bibid}"))
      #Rails.logger.debug "es287_log: #{__FILE__} #{__LINE__} #{response.inspect}"
      
      if response[self.bibid.to_s] and response[self.bibid.to_s][self.bibid.to_s] and response[self.bibid.to_s][self.bibid.to_s][:records]
        statuses = {}
        call_numbers = {}
        response[self.bibid.to_s][self.bibid.to_s]['records'].each do |record|
          if record[:bibid].to_s == self.bibid.to_s
            record[:holdings].each do |holding|
              statuses[holding[:ITEM_ID].to_s] = holding[:ITEM_STATUS]
              call_numbers[holding[:ITEM_ID].to_s] = holding[:DISPLAY_CALL_NO]
            end
          end
        end
        
        #Rails.logger.debug "es287_log: #{__FILE__} #{__LINE__} #{call_numbers.inspect}"
        location_seen = Hash.new
        location_ids = Array.new
        ## assume there is one holdings location per bibid
        locations = Hash.new
        call_number = ''
        document[:holdings_record_display].each do |hrd|
          hrdJSON = parseJSON hrd
          hrdJSON[:locations].each do |loc|
            locations[loc[:number].to_s] = loc[:name]
          end
        end if document[:holdings_record_display]
        holdings.each do |holding|
          holding[:status] = item_status statuses[holding['item_id'].to_s]
          holding[:call_number] = item_status call_numbers[holding['item_id'].to_s]
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

          #if holding[:temp_location].to_s == '0'
          if temp_location_s == '0'
            # use holdings location
            holding[:location] = locations[holding[:perm_location].to_s]
          else
            # use temp location
            #tempLocJSON = parseJSON holding[:temp_location]
            if temp_location.is_a?(Hash)
              tempLocJSON = temp_location 
              holding[:location] = tempLocJSON[:name]
            else
             Rails.logger.warn "#{__FILE__}:#{__LINE__} Cannot use temp location (not a hash) Your solr database is not up to date.: #{temp_location.inspect}"
            end
          end
          
          # Rails.logger.info "sk274_log: holding: #{holding.inspect}"
          location_seen[location] = 1 unless location_seen[location]
          exclude_location_list = Array.new
          
          if location_seen[location] == 1
            circ_group_id = Circ_policy_locs.select('CIRC_GROUP_ID').where( 'location_id' =>  location )
            
            ## handle exceptions
            ## group id 3  - Olin
            ## group id 19 - Uris
            ## group id 5  - Annex
            ## Olin or Uris can't deliver to itselves and each other
            ## Annex group can deliver to itself
            ## Law group can deliver to itself
            ## Others can't deliver to itself
            # logger.debug "sk274_log: " + circ_group_id.inspect
            # there might not be an entry in this table  
            if !circ_group_id.blank? 
              res  = circ_group_id[0]['CIRC_GROUP_ID']
              circ_group_id[0]['CIRC_GROUP_ID'] = res.nil? ? 0 : Float(circ_group_id[0]['CIRC_GROUP_ID'])
              if circ_group_id[0]['CIRC_GROUP_ID'] == 3 || circ_group_id[0]['CIRC_GROUP_ID'] == 19
                ## include both group id if Olin or Uris
                circ_group_id = [3, 19]
                # logger.debug "sk274_log: Olin or Uris detected"
              elsif circ_group_id[0]['CIRC_GROUP_ID'] == 5
                ## skip annex next time
                # logger.debug "sk274_log: Annex detected, skipping"
                location_seen[location] = exclude_location_list
                holding[:exclude_location_id] = exclude_location_list
                next
              elsif circ_group_id[0]['CIRC_GROUP_ID'] == 14 
                ## skip law library next time
                # logger.debug "sk274_log: Library detected, skipping"
                location_seen[location] = exclude_location_list
                holding[:exclude_location_id] = exclude_location_list
                next
              end
              # logger.debug "sk274_log: circ group id: " + circ_group_id.inspect
              locs = Circ_policy_locs.select('location_id').where( :circ_group_id =>  circ_group_id, :pickup_location => 'Y' )
              locs.each do |loc|
                exclude_location_list.push loc['location_id']
              end
              location_seen[location] = exclude_location_list
            end
          else
            exclude_location_list = location_seen[location]
          end
          holding[:exclude_location_id] = exclude_location_list
          # Rails.logger.info "sk274_log: #{holding[:item_id].inspect}, #{holding[:exclude_location_id].inspect}"
        end
      end
      
      #Rails.logger.debug "es287_log: #{__FILE__} #{__LINE__} #{holdings.inspect}"
      holdings

    end

    def loan_type(type_code)

      return 'nocirc' if nocirc_loan? type_code
      return 'day'    if day_loan? type_code
      return 'minute' if minute_loan? type_code
      return 'regular'

    end

    # Check whether a loan type is a "day" loan
    def day_loan?(loan_code)
      [1, 5, 6, 7, 8, 10, 11, 13, 14, 15, 17, 18, 19, 20, 21, 23, 24, 25, 28, 33].include? loan_code.to_i
    end

    # Check whether a loan type is a "minute" loan
    def minute_loan?(loan_code)
      [12, 16, 22, 26, 27, 29, 30, 31, 32, 34, 35, 36, 37].include? loan_code.to_i
    end

    # Return an array of day loan types with a loan period of 1-2 days (that cannot use L2L)
    def self.no_l2l_day_loan_types
      [10, 17, 23, 24]
    end
    
    def no_l2l_day_loan_types?(loan_code)
      [10, 17, 23, 24].include? loan_code.to_i
    end

    # Check whether a loan type is non-circulating
    def nocirc_loan?(loan_code)
      [9].include? loan_code.to_i
    end

    # There is a specific nocirc loan typecode (9), but there could also be
    # a note in the holdings record that the item doesn't circulate (even
    # with a different typecode)
    def noncirculating?(item)
      # If item is in a temp location, concentrate on that
      if item.key?('temp_location_id') and item['temp_location_id'] > 0
        return (item.key?('temp_location_display_name') and
               (item['temp_location_display_name'].include? 'Reserve' or
                item['temp_location_display_name'].include? 'reserve'))
      else
        return (item.key?('perm_location') and
                item['perm_location'].key?('name') and
                item['perm_location']['name'].include? 'Non-Circulating')
      end
    end

    # Locate and translate the actual item status 
    # from the text string in the holdings data
    def item_status item_status

      case item_status
        when DISCHARGED,
             CATALOG_REVIEW,
             CIRCULATION_REVIEW,
             IN_TRANSIT,
             IN_TRANSIT_DISCHARGED
          return NOT_CHARGED

        when RENEWED,
             CALL_SLIP_REQUEST,
             RECALL_REQUEST,
             HOLD_REQUEST,
             IN_TRANSIT_ON_HOLD,
             OVERDUE,
             CLAIMS_RETURNED,
             DAMAGED,
             WITHDRAWN,
             ON_HOLD
          return CHARGED

        when LOST_LIBRARY_APPLIED,
             LOST_SYSTEM_APPLIED
          return LOST

        else
          # covers self-returning statuses 
          # like LOST, MISSING, AT_BINDERY, CHARGED, NOT_CHARGED
          return item_status
      end

    end

    ############  Return eligible delivery services for request #################
    def delivery_services
      [L2L, BD, HOLD, RECALL, PURCHASE, PDA, ILL, ASK_LIBRARIAN, ASK_CIRCULATION, DOCUMENT_DELIVERY]
    end

    # Main entry point for determining which delivery services are available for a given item
    # Returns an array of hashes with the following structure:
    # { :service => SERVICE NAME, :estimate => ESTIMATED DELIVERY TIME }
    # The array is sorted by delivery time estimate, so the first array item should be 
    # the fastest (i.e., the "best") delivery option.
    def get_delivery_options item

      #Rails.logger.debug "es287_log :#{__FILE__}:#{__LINE__} start of deliv options (#{item.inspect})"+ Time.new.inspect
      patron_type = get_patron_type self.netid
      Rails.logger.info "es287_debug: " + "#{__FILE__}:#{__LINE__} netid=#{self.netid}, patron_type=#{patron_type}"
      if patron_type == 'cornell'
        #Rails.logger.debug "es287_log :#{__FILE__}:#{__LINE__} get_cornell_delivery_options."+ Time.new.inspect
        options = get_cornell_delivery_options item
      else
        # Rails.logger.info "sk274_debug: get guest options"
        options = get_guest_delivery_options item
      end

      # Get delivery time estimates for each option
      options.each do |option|
        #Rails.logger.debug "es287_log :#{__FILE__}:#{__LINE__} get_option_time.."+ Time.new.inspect
        option[:estimate] = get_delivery_time(option[:service], option)
        option[:iid] = item
      end
      
      # Rails.logger.info "sk274_log: #{options.inspect}"
      #Rails.logger.debug "es287_log :#{__FILE__}:#{__LINE__} end of deliv options (#{options.inspect})"+ Time.new.inspect

      #return sort_request_options options
      return options

    end

    # Determine delivery options for a single item if the patron is a Cornell affiliate
    def get_cornell_delivery_options item

      typeCode = (item[:temp_item_type_id].blank? or item[:temp_item_type_id] == '0') ? item[:item_type_id] : item[:temp_item_type_id]
      item_loan_type = loan_type typeCode
      request_options = []

      # Borrow direct check where appropriate:
      #   item type is noncirculating,
      #   item is not at bindery
      #   item status is charged, lost, or missing
      if (item_loan_type == 'nocirc' or noncirculating? item) or
        (! [AT_BINDERY, NOT_CHARGED].include?(item[:status]))
        #if available_in_bd? self.netid, params
        if self.in_borrow_direct
          request_options.push( {:service => BD, :location => item[:location] } )
        end
      end

      # Document delivery should be available for all items - see DISCOVERYACCESS-1149
      # But with a few exceptions!
      if docdel_eligible? item
        request_options.push( {:service => DOCUMENT_DELIVERY })
      end

      # Check the rest of the cases
      if item_loan_type == 'nocirc' or noncirculating? item
        return request_options.push({:service => ILL, 
                                     :location => item[:location]})
      elsif item_loan_type == 'regular' and item[:status] == NOT_CHARGED
        return request_options.push({:service => L2L, 
                                     :location => item[:location] } )
      elsif item_loan_type == 'regular' and item[:status] ==  CHARGED
        return request_options.push({:service => ILL, 
                                     :location => item[:location]},
                                    {:service => RECALL,
                                     :location => item[:location]},
                                    {:service => HOLD, 
                                     :location => item[:location], 
                                     :status => item[:status]})
      elsif (['regular','day'].include? item_loan_type) and 
            ([MISSING, LOST].include? item[:status])
        return request_options.push({:service => PURCHASE, 
                                     :location => item[:location]},
                                    {:service => ILL,
                                     :location => item[:location]})
      elsif item_loan_type == 'day' and item[:status] == CHARGED
        return request_options.push({:service => ILL, 
                                     :location => item[:location] },
                                    {:service => HOLD, 
                                     :location => item[:location], 
                                     :status => item[:status] } )
      elsif item_loan_type == 'day' and item[:status] == NOT_CHARGED
        if Request.no_l2l_day_loan_types.include? typeCode
          return request_options
        else
          return request_options.push( {:service => L2L, 
                                        :location => item[:location] } )
        end
      elsif item_loan_type == 'minute'
        return request_options.push( {:service => ASK_CIRCULATION, 
                                      :location => item[:location] } )
      elsif item[:status] == AT_BINDERY
        return request_options.push( {:service => ILL, 
                                      :location => item[:location] } )
      else
        return request_options
      end

    end

    # Determine delivery options for a single item if the patron is a guest (non-Cornell)
    def get_guest_delivery_options item
      typeCode = (item[:temp_item_type_id].blank? or item[:temp_item_type_id] == '0') ? item[:item_type_id] : item[:temp_item_type_id]
      item_loan_type = loan_type typeCode

      if noncirculating? item 
        []
      elsif item[:status] == NOT_CHARGED and (item_loan_type == 'regular' or item_loan_type == 'day') 
        [ { :service => L2L, :location => item[:location] } ] unless no_l2l_day_loan_types? item_loan_type
      elsif item[:status] == CHARGED and (item_loan_type == 'regular' or item_loan_type == 'day')
        [ { :service => HOLD, :location => item[:location], :status => item[:itemStatus] } ]
      elsif item_loan_type == 'minute' and (item[:status] == NOT_CHARGED or item[:status] == CHARGED)
        [ { :service => ASK_CIRCULATION, :location => item[:location] } ]
      else
        # default case covers:
        # item_loan_type == 'nocirc' 
        # item[:status] == MISSING or item[:status] == LOST
        # anything else
        []
      end

    end

    # Custom sort method: sort by delivery time estimate from a hash
    def sort_request_options request_options
      return request_options.sort_by { |option| option[:estimate][0] }
    end

    # Determine whether document delivery should be available for a given item
    # This is based on library location and item format
    def docdel_eligible? item

      # Specifically exclude based on item_type
      eligible_formats = ['Book', 
                          'Image', 
                          'Journal', 
                          'Manuscript/Archive', 
                          'Musical Recording', 
                          'Musical Score', 
                          'Non-musical Recording', 
                          'Research Guide', 
                          'Thesis']

      item_formats = self.document[:format]
      item_formats.each do |f|
        return true if eligible_formats.include? f
        # microform, is available via the annex but not from other locations
        return true if f == 'Microform' and item[:perm_location][:code].include? 'anx'
      end

      return false

    end

    def get_delivery_time service, item_data, return_range = true

      # Delivery time estimates are kept as ranges (as per requested) instead of single numbers
      range = [9999, 9999]     # default value

      case service 

        when L2L
          if item_data[:location] == LIBRARY_ANNEX
            range = [1, 2]
          else
            range = [2, 2]
          end

        when BD
          range = [3, 5]
        when ILL
          range = [7, 14]

        when HOLD
          ## if it got to this point, it means it is not available and should have Due on xxxx-xx-xx
          # dueDate = /.*Due on (\d\d\d\d-\d\d-\d\d)/.match(item_data[:status])
          # if ! dueDate.nil?
            # dueDate = dueDate[1]
            # estimate = (Date.parse(dueDate) - Date.today).to_i
            # if (estimate < 0)
              # ## this item is overdue
              # ## use default value instead
              # return 180
            # end
            # ## pad for extra days for processing time?
            # ## also padding would allow l2l to be always first option
            # return estimate.to_i + get_hold_padding
          # else
            # ## due date not found... use default
            # return 180
          # end
          range = [180, 180]

        when RECALL
          range = [15, 15]
        when PDA
          range = [5, 5]
        when PURCHASE
          range = [10, 10]
        when DOCUMENT_DELIVERY
          # for others, item_data is a single item
          # for DD, it is the entire holdings data since it matters whether the item is available as a whole or not
          available = false
          self.all_items.each do |item|
            if item[:status] == NOT_CHARGED
              available = true
              break
            end
          end
          if available == true
            range = [2, 2]
          else
            base_time = get_delivery_time ILL, nil
            base_estimate = 2 + base_time[0]
            range = [base_estimate, base_estimate]
          end
        when ASK_LIBRARIAN
          range = [9999, 9999]
        when ASK_CIRCULATION
          range = [9998, 9998]
        else
          range = [9999, 9999]
      end

      if return_range
        return range
      else
        return range[0] # This means that we're using the lower end of the range for calculations. Is that right?
      end

    end
    
    def populate_document_values
      unless self.document.blank?
        self.isbn = self.document[:isbn_display]
        self.ti = self.document[:title_display]
        if !self.document[:author_display].blank?
          self.au = self.document[:author_display].split('|')[0]
        elsif !self.document[:author_addl_display].blank?
          self.au = self.document[:author_addl_display].map { |author| author.split('|')[0] }.join(', ')
        else
          self.au = ''
        end
        create_ill_link
      end
    end
    
    def create_ill_link

      document = self.document
      ill_link = ENV['ILLIAD_URL'] + '?Action=10&Form=30&url_ver=Z39.88-2004&rfr_id=info%3Asid%2Flibrary.cornell.edu'
      if self.isbn.present?
        isbns = self.isbn.join(',')
        ill_link = ill_link + "&rft.isbn=#{isbns}"
        ill_link = ill_link + "&rft_id=urn%3AISBN%3A#{isbns}"
      end
      if !self.ti.blank?
        ill_link = ill_link + "&rft.btitle=#{CGI.escape(self.ti)}"
      end
      if !document[:author_display].blank?
        ill_link = ill_link + "&rft.aulast=#{document[:author_display]}"
      end

      # Populate the publisher data fields. This can be done
      # using pub_info_display, which gloms everything together,
      # or by using the separate pubplace_display, publisher_display
      # and pub_date_display
      pub_info_combo = document[:pub_info_display][0] unless document[:pub_info_display].blank?
      pub_date = (document[:pub_date_display] ? document[:pub_date_display][0] : pub_info_combo)
      pub_info = (document[:publisher_display] ? document[:publisher_display][0] : pub_info_combo)
      pub_place = (document[:pubplace_display] ? document[:pubplace_display][0] : pub_info_combo)
      self.pub_info = pub_info_combo
      ill_link = ill_link + "&rft.place=#{pub_place}"
      ill_link = ill_link + "&rft.pub=#{pub_info}"
      ill_link = ill_link + "&rft.date=#{pub_date}"

      if !document[:format].blank?
        ill_link = ill_link + "&rft.genre=#{document[:format][0]}"
      end
      if document[:lc_callnum_display].present?
        ill_link = ill_link + "&rft.identifier=#{document[:lc_callnum_display][0]}"
      end
      if document[:other_id_display]
        oclc = []
        document[:other_id_display].each do |other_id|
          if match = other_id.match(/\(#{OCLC_TYPE_ID}\)([0-9]+)/)
            id_value = match.captures[0]
            oclc.push id_value
          end
        end
        if oclc.count > 0
          ill_link = ill_link + "&rfe_dat=#{oclc.join(',')}"
        end
      end
      
      self.ill_link = ill_link
    end
    
    def deep_copy(o)
      Marshal.load(Marshal.dump(o)).with_indifferent_access
    end
    
    def parseJSON data
      JSON.parse(data).with_indifferent_access
    end
    
    ###################### Make Voyager requests ################################

    # Handle a request for a Voyager action
    # action: callslip|hold|recall
    # params: { :holding_id (actually item id), :request_action, :library_id, 'latest-date', :reqcomments }
    # Returns a status to be 'flashed' to the user
    def make_voyager_request params

      # Need bibid, netid, itemid to proceed
      if self.bibid.nil?
        return { :error => I18n.t('requests.errors.bibid.blank') }
      elsif netid.nil? 
        return { :error => I18n.t('requests.errors.email.blank') }
      elsif params[:holding_id].nil?
        #return { :error => I18n.t('requests.errors.holding_id.blank') }
        return { :error => 'test' }
      end

      # Use the VoyagerRequest class to submit the request while bypassing the holdings service
      v = VoyagerRequest.new(self.bibid, {:holdings_url => Rails.configuration.voyager_get_holds, :request_url => Rails.configuration.voyager_req_holds,:rest_url => Rails.configuration.voyager_req_holds_rest})
      v.itemid = params[:holding_id]
      v.patron(netid)
      v.libraryid = params[:library_id]
      v.reqnna = params['latest-date']
      v.reqcomments = params[:reqcomments]
      case params[:request_action]
      when 'hold'
         v.itemid.blank? ?  v.place_hold_title!   : v.place_hold_item!
      when 'recall'
         v.itemid.blank? ?  v.place_recall_title_rest! : v.place_recall_item_rest!
      when 'callslip'
         v.itemid.blank? ?  v.place_callslip_title! : v.place_callslip_item!
      end
      #Rails.logger.debug "Response" + v.inspect 
      if v.mtype.strip == 'success'
        return { :success => I18n.t('requests.success') }
      else
        if v.mtype.strip == 'blocked'
          return { :failure => I18n.t('requests.failure'+v.bcode)}
        else
          return { :failure => I18n.t('requests.failure') }
        end
      end


    end


    # def xxborrowDirect_available? params
    #
    #   if !@bd.nil?
    #     return @bd
    #   else
    #     begin
    #       @bd = available_in_bd?(self.netid, params)
    #       return  @bd
    #     rescue => e
    #       Rails.logger.info "Error checking borrow direct availability: exception #{e.class.name} : #{e.message}"
    #       @bd = false
    #       return @bd
    #     end
    #   end
    # end

    # Determine Borrow Direct availability for an ISBN or title
    # params = { :isbn, :title }
    # ISBN is best, but title will work if ISBN isn't available.
    def available_in_bd? netid, params

      # Set up params for BorrowDirect gem
      if Rails.env.production?
        # if this isn't specified, defaults to BD test database
        BorrowDirect::Defaults.api_base = BorrowDirect::Defaults::PRODUCTION_API_BASE
      end
      BorrowDirect::Defaults.library_symbol = "CORNELL"
      BorrowDirect::Defaults.find_item_patron_barcode = patron_barcode(netid)
      BorrowDirect::Defaults.timeout = 30 # (seconds)

      response = nil
      # This block can throw timeout errors if BD takes to long to respond
      begin
        if !params[:isbn].nil?
          # Note: [*<variable>] gives us an array if we don't already have one,
          # which we need for the map.
          response = BorrowDirect::FindItem.new.find(:isbn => ([*params[:isbn]].map!{|i| i.clean_isbn}))
        elsif !params[:title].nil?
          response = BorrowDirect::FindItem.new.find(:phrase => params[:title])
        end

        Rails.logger.debug "es287_log :#{__FILE__}:#{__LINE__} response from bd ."+ response.inspect
        return response.requestable?

      rescue BorrowDirect::HttpTimeoutError => e
        Rails.logger.warn 'Requests: Borrow Direct check timed out'
        Rails.logger.warn e.message
        Rails.logger.warn e.backtrace.inspect
        return false
      rescue BorrowDirect::Error => e
        Rails.logger.warn 'Requests: Borrow Direct gave error.'
        Rails.logger.warn e.message
        Rails.logger.warn e.backtrace.inspect
        Rails.logger.warn response.inspect 
        return false
      end
    end

    # Use the external netid lookup script to figure out the patron's barcode
    # (this might duplicate what's being done in the voyager_request patron method)
    def patron_barcode(netid)

      uri = URI.parse(ENV['NETID_URL'] + "?netid=#{netid}")
      response = Net::HTTP.get_response(uri)

      # Make sure that we got a real result. Unfortunately, the CGI doesn't
      # return a nice error code
      return nil if response.body.include? 'Software error'

      # Return the barcode
      JSON.parse(response.body)['bc']

    end

    
  end
end

class String
def clean_isbn
  return self.gsub! /[^0-9X]*/, ''
end
end

