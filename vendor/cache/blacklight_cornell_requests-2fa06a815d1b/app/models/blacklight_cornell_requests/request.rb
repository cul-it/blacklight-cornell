require 'blacklight_cornell_requests/cornell'
require 'blacklight_cornell_requests/borrow_direct'

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
    HOLD_PADDING_TIME = 3
    OCLC_TYPE_ID = 'OCoLC'

    # attr_accessible :title, :body
    include ActiveModel::Validations
    include Cornell::LDAP
    include BorrowDirect

    attr_accessor :bibid, :holdings_data, :service, :document, :request_options, :alternate_options
    attr_accessor :au, :ti, :isbn, :document, :ill_link, :pub_info, :netid, :estimate, :items, :volumes, :all_items
    attr_accessor :L2L, :BD, :HOLD, :RECALL, :PURCHASE, :PDA, :ILL, :ASK_CIRCULATION, :ASK_LIBRARIAN, :DOCUMENT_DELIVERY
    validates_presence_of :bibid
    def save(validate = true)
      validate ? valid? : true
    end

    def initialize(bibid)
      self.bibid = bibid
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
      get_holdings 'retrieve_detail_raw' unless self.holdings_data

      # Get item status and location for each item in each holdings record; store in working_items
      # We now have two item arrays! working_items (which eventually gets set in self.items) is a 
      # list of all 'active' items, e.g., those for a particular volume or other set. 
      # self.all_items includes *all* the items in the holdings data for the bibid, so that we can
      # use that list to, for example, obtain a list of all the volumes in the bibid.
      working_items = []
      self.all_items = []
      item_status = 'Charged'
      holdings = self.holdings_data[self.bibid.to_s][:records]
      holdings.each do |h|
        items = h[:item_status][:itemdata]
        items.each do |i|
          iid = deep_copy(i)
          iid[:id] = iid[:itemid]
          iid[:status] = item_status iid[:itemStatus]

          self.all_items.push(iid) # Everything goes into all_items

          # If volume is specified, only populate items with matching enum/chron/year values

          # Unpack volume if necessary
          if volume.present?
            parts = volume.split '|'
            e = parts[1] || ''
            c = parts[2] || ''
            y = parts[3] || ''

            # Require a match on all three iterator values to determine a match
            next if ( y != i[:year] or c != i[:chron] or e != i[:enumeration])
          end
          
          # Only a subset of all_items gets put into working_items
          working_items.push(iid)

        end
      end

      self.items = working_items
      self.document = document

      unless document.nil?

        # Iterate through all items and get list of delivery methods
        bd_params = { :isbn => document[:isbn_display], :title => document[:title_display], :env_http_host => env_http_host }
        working_items.each do |item|
          services = get_delivery_options item, bd_params
          item[:services] = services
        end
        populate_document_values
        
        
        # handle pda
        patron_type = get_patron_type self.netid
        if patron_type == 'cornell' && !document['url_pda_display'].blank?
          self.document = document
          
          pda_url = document['url_pda_display'][0]
          pda_url, note = pda_url.split('|')
          iids = { :itemid => 'pda', :url => pda_url, :note => note }
          pda_entry = { :service => PDA, :iid => iids, :estimate => get_delivery_time(PDA, nil) }
          
          bd_entry = nil
          if borrowDirect_available? bd_params
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
          
          return
        end

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
  
      if !target.blank?
        self.service = target
      elsif request_options.present?
        self.service = request_options[0][:service]
      else
        self.service = ASK_LIBRARIAN
      end

      request_options.push ( { :service => ASK_LIBRARIAN, :estimate => get_delivery_time( ASK_LIBRARIAN, nil ) } )
      populate_options self.service, request_options unless self.service == ASK_LIBRARIAN

      if document[:format].present? and document[:format].include? 'Journal'
        if self.alternate_options.nil?
          self.alternate_options = []
        end
        # this article form cannot be prepopulated...
        dd_link = 'https://cornell.hosts.atlas-sys.com/illiad/illiad.dll?Action=10&Form=22'
        dd_estimate = get_delivery_time DOCUMENT_DELIVERY, nil
        if self.service != DOCUMENT_DELIVERY
          dd_iids = { :itemid => 'document_delivery', :url => dd_link }
          self.alternate_options.unshift ( { :service => DOCUMENT_DELIVERY, :iid => dd_iids, :estimate => dd_estimate } )
        else
          dd_iids = { :itemid => 'document_delivery', :url => dd_link }
          if !self.request_options.nil?
            self.alternate_options.unshift *self.request_options
          end
          self.request_options = [ { :service => DOCUMENT_DELIVERY, :iid => dd_iids, :estimate => dd_estimate } ]
        end
      end

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
        item[:numeric_enumeration] = item[:enumeration][/\d+/]
        item[:enumeration] = item[:enumeration]
        if !item[:numeric_enumeration].blank?
          item[:numeric_enumeration] = item[:numeric_enumeration].to_i
          num_enum = num_enum + 1
        else
          item[:numeric_enumeration] = 999999999
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
        
        if item[:chron].blank?
          item[:chron_compare] = 'z'
        else
          item[:chron_compare] = item[:chron]
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
          sorted_items = items.sort_by {|h| [ h[:numeric_year],h[:year_compare],h[:numeric_enumeration],h[:numeric_chron],h[:chron_compare] ]}
        else
          sorted_items = items.sort_by {|h| [ h[:numeric_year],h[:year_compare],h[:numeric_chron],h[:chron_compare],h[:numeric_enumeration] ]}
        end
      elsif num_enum >= num_chron and num_enum >= num_year
        if num_year >= num_chron
          sorted_items = items.sort_by {|h| [ h[:numeric_enumeration],h[:numeric_year],h[:year_compare],h[:numeric_chron],h[:chron_compare] ]}
        else
          sorted_items = items.sort_by {|h| [ h[:numeric_enumeration],h[:numeric_chron],h[:chron_compare],h[:numeric_year],h[:year_compare] ]}
        end
      else
        if num_year >= num_enum
          sorted_items = items.sort_by {|h| [ h[:numeric_chron],h[:chron_compare],h[:numeric_year],h[:year_compare],h[:numeric_enumeration] ]}
        else
          sorted_items = items.sort_by {|h| [ h[:numeric_chron],h[:chron_compare],h[:numeric_enumeration],h[:numeric_year],h[:year_compare] ]}
        end
      end
      
      ## as of ruby 1.9, hash preserves insertion order
      sorted_items.each do |item|
        e = item[:enumeration]
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

    # Sort volumes in their logical order for display.
    # Volume strings typically look like 'v.1', 'v21-22', 'index v.1-10', etc.
    # def sort_volumes(volumes)

    #   Rails.logger.debug "mjc12test: v1: #{volumes}"
    #   volumes = volumes.sort_by do |v|

    #     if v.is_a? Integer
    #       [Integer(v)]
    #     else
    #       a, b, c = v.split(/[\.\-,]/) 
    #       b = b.gsub(/[^0-9]/,'') unless b.nil?
    #       if b.blank? or b !~ /\d+/
    #         [a]
    #       else
    #         [a, Integer(b)] # Note: This forces whatever is left into an integer!
    #       end
    #     end
    #   end
    #   Rails.logger.debug "mjc12test: v2: #{volumes}"

    #   volumes

    # end

    ##################### Manipulate holdings data #####################

    # Set holdings data from the Voyager service configured in the
    # environments file.
    # holdings_param = { :bibid => <bibid>, :type => retrieve|retrieve_detail_raw}
    def get_holdings(type = 'retrieve')

      return nil unless self.bibid

      response = JSON.parse(HTTPClient.get_content(Rails.configuration.voyager_holdings + "/holdings/#{type}/#{self.bibid}"))

      # return nil if there is no meaningful response (e.g., invalid bibid)
      return nil if response[self.bibid.to_s].nil?
      
      self.holdings_data = response.with_indifferent_access

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

    # Locate and translate the actual item status from the text string in the holdings data
    def item_status item_status
      if item_status.include? 'Not Charged'
        'Not Charged'
      elsif item_status.include? 'Discharged'
        'Not Charged'
      elsif item_status.include? 'Cataloging Review'
        return 'Not Charged'
      elsif item_status.include? 'Circulation Review'
        return 'Not Charged'
      elsif item_status.include? 'Charged'
        'Charged'
      elsif item_status.include? 'Renewed'
        'Charged'
      elsif item_status.include? 'Requested'
        'Requested'
      elsif item_status.include? 'Missing'
        'Missing'
      elsif item_status.include? 'Lost'
        'Lost'
      elsif item_status =~ /In transit to(.*)\./
        return 'Charged'
      elsif item_status.include? 'In transit'
        return 'Not Charged'
      elsif item_status.include? 'Hold'
        return 'Charged'
      elsif item_status.include? 'Overdue'
        return 'Charged'
      elsif item_status.include? 'Recall'
        return 'Charged'
      elsif item_status.include? 'Claims'
        return 'Charged'
      elsif item_status.include? 'Damaged'
        return 'Charged'
      elsif item_status.include? 'Withdrawn'
        return 'Charged'
      elsif item_status.include? 'Call Slip Request'
        return 'Charged'
      elsif item_status.include? 'At Bindery'
        return 'At Bindery'
      else
        item_status
      end
    end

    ############  Return eligible delivery services for request #################
    def delivery_services
      [L2L, BD, HOLD, RECALL, PURCHASE, PDA, ILL, ASK_LIBRARIAN, ASK_CIRCULATION]
    end

    # Main entry point for determining which delivery services are available for a given item
    # Returns an array of hashes with the following structure:
    # { :service => SERVICE NAME, :estimate => ESTIMATED DELIVERY TIME }
    # The array is sorted by delivery time estimate, so the first array item should be 
    # the fastest (i.e., the "best") delivery option.
    def get_delivery_options item, bd_params = {}

      patron_type = get_patron_type self.netid
      # Rails.logger.info "sk274_debug: " + "#{self.netid}, #{patron_type}"

      if patron_type == 'cornell'
        # Rails.logger.info "sk274_debug: get cornell options"
        options = get_cornell_delivery_options item, bd_params
      else
        # Rails.logger.info "sk274_debug: get guest options"
        options = get_guest_delivery_options item
      end

      # Get delivery time estimates for each option
      options.each do |option|
        option[:estimate] = get_delivery_time(option[:service], option)
        option[:iid] = item
      end

      #return sort_request_options options
      return options

    end

    # Determine delivery options for a single item if the patron is a Cornell affiliate
    def get_cornell_delivery_options item, params

      item_loan_type = loan_type item[:typeCode]

      request_options = []
      if item_loan_type == 'nocirc'
        # if borrowDirect_available? bdParams
          # request_options.push({ :service => BD, :iid => [], :estimate => get_bd_delivery_time })
          # if target.blank?
            # target = BD
          # end
        # end
        # request_options.push({ :service => ILL, :iid => [], :estimate => get_ill_delivery_time })
        if borrowDirect_available? params
          request_options.push( {:service => BD, :location => item[:location] } )
        end
        request_options.push({:service => ILL, :location => item[:location]})
      elsif item_loan_type == 'regular' and item[:status] == 'Not Charged'

        request_options.push({:service => L2L, :location => item[:location] } )

      elsif ((item_loan_type == 'regular' and item[:status] == 'Charged') or
             (item_loan_type == 'regular' and item[:status] == 'Requested'))
        # TODO: Test and fix BD check with real params
        if borrowDirect_available? params
          request_options.push( {:service => BD, :location => item[:location] } )
        end
        request_options.push({:service => ILL, :location => item[:location]},
                             {:service => RECALL,:location => item[:location]},
                             {:service => HOLD, :location => item[:location], :status => item[:itemStatus]})

      elsif ((item_loan_type == 'regular' and item[:status] == 'Missing') or
             (item_loan_type == 'regular' and item[:status] == 'Lost') or
             (item_loan_type == 'day' and item[:status] == 'Missing') or
             (item_loan_type == 'day' and item[:status] == 'Lost'))

         # TODO: Test and fix BD check with real params
        if borrowDirect_available? params
          request_options.push( {:service => BD, :location => item[:location] } )
        end
        request_options.push({:service => PURCHASE, :location => item[:location]},
                             {:service => ILL,:location => item[:location]})

      elsif ((item_loan_type == 'day' and item[:status] == 'Charged') or
             (item_loan_type == 'day' and item[:status] == 'Requested'))

         # TODO: Test and fix BD check with real params
        if borrowDirect_available? params
          request_options.push( {:service => BD, :location => item[:location] } )
        end
        request_options.push( {:service => ILL, :location => item[:location] } )
        request_options.push( {:service => HOLD, :location => item[:location], :status => item[:itemStatus] } )

      elsif (item_loan_type == 'day' and item[:status] == 'Not Charged')

        unless Request.no_l2l_day_loan_types.include? item[:typeCode]
          request_options.push( {:service => L2L, :location => item[:location] } )
        end

      elsif item_loan_type == 'minute'

        # TODO: Test and fix BD check with real params
        if borrowDirect_available? params
          request_options.push( {:service => BD, :location => item[:location] } )
        end
        request_options.push( {:service => ASK_CIRCULATION, :location => item[:location] } )
        
      elsif item[:status] == 'At Bindery'
        request_options.push( {:service => ILL, :location => item[:location] } )
      end

      return request_options
    end

    # Determine delivery options for a single item if the patron is a guest (non-Cornell)
    def get_guest_delivery_options item
      item_loan_type = loan_type item[:typeCode]
      request_options = []

      if item_loan_type == 'nocirc'
        # do nothing
      elsif item_loan_type == 'regular' and item[:status] == 'Not Charged'
        request_options = [ { :service => L2L, :location => item[:location] } ] unless no_l2l_day_loan_types? item_loan_type
      elsif item_loan_type == 'regular' and item[:status] == 'Charged'
        request_options = [ { :service => HOLD, :location => item[:location], :status => item[:itemStatus] } ]
      elsif item_loan_type == 'regular' and item[:status] == 'Requested'
        request_options = [ { :service => HOLD, :location => item[:location], :status => item[:itemStatus] } ]
      elsif item_loan_type == 'regular' and item[:status] == 'Missing'
        ## do nothing
      elsif item_loan_type == 'regular' and item[:status] == 'Lost'
        ## do nothing
      elsif item_loan_type == 'day' and item[:status] == 'Not Charged'
        request_options = [ { :service => L2L, :location => item[:location] } ] unless no_l2l_day_loan_types? item_loan_type
      elsif item_loan_type == 'day' and item[:status] == 'Charged'
        request_options = [ { :service => HOLD, :location => item[:location], :status => item[:itemStatus] } ]
      elsif item_loan_type == 'day' and item[:status] == 'Requested'
        request_options = [ { :service => HOLD, :location => item[:location], :status => item[:itemStatus] } ]
      elsif item_loan_type == 'day' and item[:status] == 'Missing'
        ## do nothing
      elsif item_loan_type == 'day' and item[:status] == 'Lost'
        ## do nothing
      elsif item_loan_type == 'minute' and item[:status] == 'Not Charged'
        request_options = [ { :service => ASK_CIRCULATION, :location => item[:location] } ]
      elsif item_loan_type == 'minute' and item[:status] == 'Charged'
        request_options = [ { :service => ASK_CIRCULATION, :location => item[:location] } ]
      elsif item_loan_type == 'minute' and item[:status] == 'Requested'
        request_options = [ { :service => ASK_CIRCULATION, :location => item[:location] } ]
      elsif item_loan_type == 'minute' and item[:status] == 'Missing'
        ## do nothing
      elsif item_loan_type == 'minute' and item[:status] == 'Lost'
        ## do nothing
      end

      return request_options
    end

    # Custom sort method: sort by delivery time estimate from a hash
    def sort_request_options request_options
      return request_options.sort_by { |option| option[:estimate] }
    end

    def get_delivery_time service, item_data
      case service 

        when L2L
          if item_data[:location] == LIBRARY_ANNEX
            1
          else
            2
          end

        when BD
          6
        when ILL
          14

        when HOLD
          ## if it got to this point, it means it is not available and should have Due on xxxx-xx-xx
          dueDate = /.*Due on (\d\d\d\d-\d\d-\d\d)/.match(item_data[:status])
          if ! dueDate.nil?
            dueDate = dueDate[1]
            estimate = (Date.parse(dueDate) - Date.today).to_i
            if (estimate < 0)
              ## this item is overdue
              ## use default value instead
              return 180
            end
            ## pad for extra days for processing time?
            ## also padding would allow l2l to be always first option
            return estimate.to_i + get_hold_padding
          else
            ## due date not found... use default
            return 180
          end

        when RECALL
          15
        when PDA
          5
        when PURCHASE
          10
        when DOCUMENT_DELIVERY
          # for others, item_data is a single item
          # for DD, it is the entire holdings data since it matters whether the item is available as a whole or not
          available = false
          self.all_items.each do |item|
            if item[:status] == 'Not Charged'
              available = true
              break
            end
          end
          if available == true
            2
          else
            2 + ( get_delivery_time ILL, nil )
          end
        when ASK_LIBRARIAN
          9999
        when ASK_CIRCULATION
          9998
        else
          9999
      end

    end
    
    def populate_document_values
      unless self.document.nil?
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
      ill_link = 'https://cornell.hosts.atlas-sys.com/illiad/illiad.dll?Action=10&Form=30&url_ver=Z39.88-2004&rfr_id=info%3Asid%2Flibrary.cornell.edu'
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
      if document[:pub_info_display].present?
        pub_info_display = document[:pub_info_display][0]
        self.pub_info = pub_info_display
        ill_link = ill_link + "&rft.place=#{pub_info_display}"
        ill_link = ill_link + "&rft.pub=#{pub_info_display}"
        ill_link = ill_link + "&rft.date=#{pub_info_display}"
      end
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
      v = VoyagerRequest.new(self.bibid, {:holdings_url => Rails.configuration.voyager_get_holds, :request_url => Rails.configuration.voyager_req_holds})
      v.itemid = params[:holding_id]
      v.patron(netid)
      v.libraryid = params[:library_id]
      v.reqnna = params['latest-date']
      v.reqcomments = params[:reqcomments]
      case params[:request_action]
      when 'hold'
        v.place_hold_item!
      when 'recall'
        v.place_recall_item!
      when 'callslip'
        v.place_callslip_item!
      end

      if v.mtype.strip == 'success'
        return { :success => I18n.t('requests.success') }
      else
        return { :failure => I18n.t('requests.failure') }
      end

      # Set up Voyager request URL string
      # voyager_request_handler_url = Rails.configuration.voyager_request_handler_host
      # voyager_request_handler_url ||= request.env['HTTP_HOST']
      # unless voyager_request_handler_url.starts_with?('http')
      #   voyager_request_handler_url = "http://#{voyager_request_handler_url}"
      # end
      # unless Rails.configuration.voyager_request_handler_port.blank?
      #   voyager_request_handler_url += ":" + Rails.configuration.voyager_request_handler_port.to_s
      # end

      # # Assemble complete request URL
      # voyager_request_handler_url += "/holdings/#{params[:request_action]}/#{self.netid}/#{self.bibid}/#{params[:library_id]}"
      # unless params[:holding_id].nil?
      #   voyager_request_handler_url += "/#{params[:holding_id]}" # holding_id is actually item id!
      # end

      # # Send the request
      # # puts voyager_request_handler_url
      # body = { 'reqnna' => params['latest-date'], 'reqcomments' => params[:reqcomments] }
      # result = HTTPClient.post(voyager_request_handler_url, body)
      #response = JSON.parse(result.content)

      # if response['status'] == 'failed'
      #   return { :failure => I18n.t('requests.failure') }
      # else
      #   return { :success => I18n.t('requests.success') }
      # end

    end

  end

end
