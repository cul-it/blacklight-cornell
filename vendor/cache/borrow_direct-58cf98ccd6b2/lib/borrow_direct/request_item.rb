require 'borrow_direct'
require 'borrow_direct/request'

module BorrowDirect
  # The BorrowDirect RequestItem service, for placing a request
  # http://borrowdirect.pbworks.com/w/file/86126056/RequestItem.docx
  #
  # You can also use #find_item_request to get the raw BD response as a ruby hash
  class RequestItem < Request
    attr_reader :patron_barcode, :patron_library_symbol
    attr_reader :authorization_id

    @@api_path = "/dws/item/add"
    @@valid_search_types = %w{ISBN ISSN LCCN OCLC Control }


    
    def initialize(patron_barcode,
                   patron_library_symbol = Defaults.library_symbol)
      super(@@api_path)

      @patron_barcode        = patron_barcode
      @patron_library_symbol = patron_library_symbol

      # BD sometimes unpredictably returns one of these errors when it means
      # "no results", other times it doesn't. We don't want to raise on it. 
      self.expected_error_codes << "PUBRI004"
      self.expected_error_codes << "PUBRI003"
    end

    # need to send a key and value for a valid exact_search type
    # type can be string or symbol, lowercase or uppercase. 
    #
    # Also a pickup_location -- can pass in nil, and we'll send no
    # PickupLocation to BD, which it seems to accept, not sure what it
    # does with it. 
    #
    # pickup_location can be a BorrowDirect::PickupLocation object,
    # or a string. If a string, BD recommends it be a CODE returned
    # from FindItem, rather than DESCRIPTION as in the past, but we
    # think description still works? 
    #
    # Returns the actual complete BD response hash. You may want
    # #make_request instead
    #
    #    finder.request_item_request(pickup_location, :isbn => "12345545456")
    #    finder.request_item_request(pickup_location, :lccn => "12345545456")
    #    finder.request_item_request(pickup_location, :oclc => "12345545456")
    def request_item_request(pickup_location, options)
      search_type, search_value = nil, nil
      options.each_pair do |key, value|
        if @@valid_search_types.include? key.to_s.upcase
          if search_type || search_value
            raise ArgumentError.new("Only one search criteria at a time is allowed: '#{options}'")
          end

          search_type, search_value = key, value
        end
      end
      unless search_type && search_value
        raise ArgumentError.new("Missing valid search type and value: '#{options}'")
      end

      if pickup_location.kind_of?(BorrowDirect::PickupLocation)
        pickup_location = pickup_location.code
      end

      request exact_search_request_hash(pickup_location, search_type, search_value), need_auth_id(self.patron_barcode, self.patron_library_symbol)
    end

    # Pass in a BD exact search and pickup location eg
    #     make_request(pickup_location, :isbn => isbn)
    #
    # Pass in nil for pickup_location if... not sure exactly what
    # BD will do, but it does allow it. 
    #
    # Returns the BD RequestNumber, or nil if a request could
    # not be made
    #
    # See also make_request! to raise if request can not be made
    def make_request(pickup_location, options)
      resp = request_item_request(pickup_location, options)

      return extract_request_number(resp)
    end

    # Like make_request, but will raise a BorrowDirect::Error if
    # item can't be requested. 
    def make_request!(pickup_location, options)
      resp = request_item_request(pickup_location, options)

      number = extract_request_number(resp)

      if number.nil?
        raise BorrowDirect::Error.new("Can not request for: #{options.inspect}: #{resp.inspect}")
      end

      return number
    end

    protected

    def extract_request_number(resp)
      return resp["RequestNumber"]
    end

    def exact_search_request_hash(pickup_location, type, value)
      hash = {
          "PartnershipId" => Defaults.partnership_id,
          "ExactSearch" => [
              {
                  "Type" => type.to_s.upcase,
                  "Value" => value
              }
          ]
      }

      if pickup_location
        hash["PickupLocation"] = pickup_location
      end

      return hash
    end


  end
end