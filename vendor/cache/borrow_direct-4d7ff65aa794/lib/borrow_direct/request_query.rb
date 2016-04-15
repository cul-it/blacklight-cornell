require 'borrow_direct'
require 'date'

module BorrowDirect
  # Info from Relais/BD on type and status:
  #
  # valid 'type' values for requests:
  #
  #  xdays: Retrieve requests submitted within the last xdays (for example, one would include two parameters: type=xdays&xdays=7 to retrieve requests submitted within the last 7 days)
  #  all: Retrieve all request submitted by the user
  #  open: Retrieve all open requests i.e. requests which haven't been fulfilled yet.
  #  allposttoweb: BD doesn't use the post-to-web application; you can ignore this.
  #  unopenedposttoweb: You can safely ignore this.
  #  onloan: Retrieve requests which are on loan
  #
  # possible RequestStatus values in results:
  #
  #  ENTERED: Request has been entered and yet to be processed.
  #  IN_PROCESS: Request is being processed.
  #  CANCELLED: Request has been cancelled.
  #  UNFILLED: Request can't be filled.
  #  SHIPPED: Item has been shipped.
  #  ARTICLE_SENT: A scanned document or an electronic document has been sent (It doesn't apply to BD)
  #  ON_LOAN: Request is on loan.
  #  OVERDUE: Item is over due.
  #  COMPLETE: Item has been returned and request is completed.
  #  UNKNOWN: You should never see this; this indicates there is probably an inconsistency with the record somewhere. You probably want to flag and report this. 
  class RequestQuery < Request
    attr_reader :patron_barcode, :patron_library_symbol

    @@api_path = "/portal-service/request/query/my"   

    # I'm not exactly sure what these mean either. 
    @@query_types = %w{xdays all open allposttoweb unopenedposttoweb onloan}


    def initialize(patron_barcode,
                   patron_library_symbol = Defaults.library_symbol)
      super(@@api_path)

      @patron_barcode        = patron_barcode
      @patron_library_symbol = patron_library_symbol
      self.http_method = :get
    end

    # Returns raw BD response as a hash. 
    # * type defaults to 'all', but can be BD values of xdays, all
    #   open, allposttoweb, unopenedposttoweb, onloan. 
    #   xdays not really supported yet, cause no way to pass an xdays param yet
    # * full_record can be true or false, defaults to false. 
    def request_query_request(type = "all", full_record = false)
      query_params = {
        "aid"         => need_auth_id(patron_barcode, patron_library_symbol),
        "type"        => type.to_s,
        "fullRecord"  => (full_record ? "1" : "0")
      }

      response = request query_params

      # RequestQuery sometimes returns odd 200 OK response with
      # AuthFailed, at least as of 29 Sep 2015. Catch it and
      # raise it properly. 
      if response["AuthorizationState"] && response["AuthorizationState"]["State"] == false
        raise BorrowDirect::InvalidAidError.new("API returned AuthorizationState.State == false", nil, response["AuthorizationState"]["AuthorizationId"])
      end

      return response
    end

    # Returns an array of BorrowDirect::RequestQuery::Item
    # * type defaults to 'all', but can be BD values of xdays, all
    #   open, allposttoweb, unopenedposttoweb, onloan. 
    #   xdays not really supported yet, cause no way to pass an xdays param yet
    # * full_record can be true or false, defaults to false. 
    def requests(*args)
      response = request_query_request(*args)

      results = []

      response["MyRequestRecords"].each do |item_hash|        
        results << BorrowDirect::RequestQuery::Item.new(item_hash)
      end

      return results
    end

    class Item
      # fullRecord == 0 values
      attr_reader :request_number, :title, :date_submitted, :allow_renew, 
                  :allow_cancel, :request_status, :request_status_date
      # fullRecord == 1 values, not all are applicable for BorrowDirect,
      # and many may be nil. 
      attr_reader :publication_type, :publication_date, :publication_place, 
                  :volume, :issue, :edition, :issn, :issn2, :isbn, :isbn2,
                  :ismn, :pages_requested, :delivery_date

      def initialize(hash)
        # basic record values
        @request_number = hash["RequestNumber"]
        @title          = hash["Title"]
        if hash["ISO8601DateSubmitted"]
          @date_submitted = DateTime.iso8601 hash["ISO8601DateSubmitted"]
        end
        @allow_renew    = hash["AllowRenew"]
        @allow_cancel   = hash["AllowCancel"]
        @request_status = hash["RequestStatus"]

        if hash["ISO8601RequestStatusDate"]
          @request_status_date = DateTime.iso8601 hash["ISO8601RequestStatusDate"]
        end

        # full record values
        @publicaition_type  = hash["PublicationType"]
        @publication_date   = hash["PublicationDate"] # BD just gives us a string
        @publication_place  = hash["PublicationPlace"]
        @volume             = hash["Volume"]
        @issue              = hash["Issue"]
        @edition            = hash["Edition"]
        @issn               = hash["Issn"]
        @issn2              = hash["Issn2"]
        @isbn               = hash["Isbn"]
        @isbn2              = hash["Isbn2"]
        @ismn               = hash["Ismn"]
        @pages_requested    = hash["PagesRequested"]
        if hash["ISO8601DeliveryDate"]
          @delivery_date      = DateTime.iso8601 hash["ISO8601DeliveryDate"]
        end
      end
    end

  end






end