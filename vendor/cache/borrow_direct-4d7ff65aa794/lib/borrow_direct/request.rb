require 'json'
require 'httpclient'
require 'ostruct'

require 'borrow_direct'

module BorrowDirect
  # Generic abstract BD request, put in a Hash request body, get
  # back a Hash answer. 
  #  
  #    response_hash = Request.new("/path/to/endpoint").request(request_hash)
  #
  # Typically, clients will use various sub-classes of Request implementing
  # calling of individual BD API's
  # 
  # ## AuthenticationID's
  #
  # Some API endpoints require an "AId"/"AuthencationID". BorrowDirect::Request
  # provides some facilities for managing obtaining such (using Authentication API),
  # usually will be used under the hood by Request subclasses. 
  #
  #     # fetch new auth ID using Authentication API, store it
  #     # in self.auth_id
  #     request.fetch_auth_id!(barcode, library_symbol)  
  #
  #     # return the existing value in self.auth_id, or if
  #     # nil run fetch_auth_id! to fill it out. 
  #     request.need_auth_id(barcode, library_symbol)
  #     
  #     request.auth_id # cached or nil
  class Request
    attr_writer :http_client
    attr_accessor :timeout
    attr_accessor :auth_id
    # default :post, but can be set to :get, usually by a subclass
    attr_accessor :http_method
    attr_reader :last_request_uri, :last_request_json, :last_request_response, :last_request_time

    # Usually an error code from the server will be turned into an exception. 
    # But if there are error codes you expect (usually fixed in a subclass of Request),
    # fill them in this array, and the responses will be returned anyway -- warning,
    # REGARDLESS of HTTP response status code, as these are often non-200 but we want
    # to catch em anyway. 
    attr_accessor :expected_error_codes

    def initialize(path)
      @api_base = Defaults.api_base
      @api_path = path

      @api_uri = @api_base.chomp("/") + @api_path

      @expected_error_codes = []

      @timeout = Defaults.timeout
      @http_method = :post
    end

    # First param is request hash, will be query param for GET or JSON body for POST
    # Second param is optional AuthenticationID used by BD system -- if given,
    # will be added to URI as "?aid=$AID", even for POST. Yep, that's Relais
    # documented protocol eg https://relais.atlassian.net/wiki/display/ILL/Find+Item
    def request(hash, aid = nil)
      http = http_client
      
      uri = @api_uri
      if aid
        uri += "?aid=#{CGI.escape aid}"
      end

      # Mostly for debugging, store these
      @last_request_uri = uri

      start_time = Time.now

      if self.http_method == :post
        @last_request_json = json_request = JSON.generate(hash)        
        http_response = http.post uri, json_request, self.request_headers
      elsif self.http_method == :get
        @last_request_query_params = hash
        http_response = http.get uri, hash, self.request_headers
      else
        raise ArgumentError.new("BorrowDirect::Request only understands http_method :get and :post, not `#{self.http_method}`")
      end

      @last_request_response = http_response
      @last_request_time     = Time.now - start_time

      response_hash = begin
        JSON.parse(http_response.body)
      rescue JSON::ParserError => json_parse_exception
        nil
      end

      # will be nil if we have none
      einfo = error_info(response_hash)
      expected_error = (einfo && self.expected_error_codes.include?(einfo.number))


      if einfo && (! expected_error)
        if BorrowDirect::Error.invalid_aid_code?(einfo.number)
          raise BorrowDirect::InvalidAidError.new(einfo.message, einfo.number, aid)
        else
          raise BorrowDirect::Error.new(einfo.message, einfo.number)      
        end
      elsif http_response.code != 200 && (! expected_error)
        raise BorrowDirect::HttpError.new("HTTP Error: #{http_response.code}: #{http_response.body}")
      elsif response_hash.nil?
        raise BorrowDirect::Error.new("Could not parse expected JSON response: #{http_response.code} #{json_parse_exception}: #{http_response.body}")
      end

      

      return response_hash
    rescue HTTPClient::ReceiveTimeoutError, HTTPClient::ConnectTimeoutError, HTTPClient::SendTimeoutError => e
      elapsed = Time.now - start_time
      raise BorrowDirect::HttpTimeoutError.new("Timeout after #{elapsed.round(1)}s connecting to BorrowDirect server at #{@api_base}", self.timeout)
    end

    def http_client
      @http_client ||= make_http_client!
    end

    # For now, we can send same request headers for all requests. May have to
    # make parameterized later. 
    # Note SOME but not all BD API endpoints REQUIRE User-Agent and 
    # Accept-Language (for no discernable reason)
    #
    # NOTE WELL: API sometimes requires User-Agent _not to change_ when using
    # an AuthorizationID, or it will revoke your authorization. Need to use the
    # same User-Agent when using an auth_id as you used when receiving it. 
    def request_headers
      { "Content-Type" => "application/json", 
        "User-Agent" => "ruby borrow_direct gem #{BorrowDirect::VERSION} (HTTPClient #{HTTPClient::VERSION}) https://github.com/jrochkind/borrow_direct", 
        "Accept-Language" => "en"
      }
    end

    # Fetches new authID, stores it in self.auth_id, overwriting
    # any previous value there. Will raise BorrowDirect::Error if no auth
    # could be fetched. 
    #
    # returns auth_id too. 
    def fetch_auth_id!(barcode, library_symbol)
      auth = Authentication.new(barcode, library_symbol)
      # use the same HTTPClient so we use the same HTTP connection, perhaps
      # slightly more performance worth a shot. 
      auth.http_client = http_client
      self.auth_id = auth.get_auth_id
    end

    # Will use value in self.auth_id, or if nil will
    # fetch a value with fetch_auth_id! and return that. 
    def need_auth_id(barcode, library_symbol)
      self.auth_id || fetch_auth_id!(barcode, library_symbol)
    end

    # Can be used to set an already existing AuthID to be used. 
    # Beware, we have no facility for rescuing from escpired auth ids
    # at the moment. 
    def with_auth_id(aid)
      self.auth_id = aid
      return self
    end




    protected

    def make_http_client!
      http = HTTPClient.new
      if self.timeout
        http.send_timeout    = self.timeout
        http.connect_timeout = self.timeout
        http.receive_timeout    = self.timeout
      end

      return http
    end

    # returns an OpenStruct with #message and #number, 
    # or nil if error info can not be extracted
    def error_info(hash)      
      if hash && (e = hash["Error"]) && (e["ErrorNumber"] || e["ErrorMessage"])
        return OpenStruct.new(:number => e["ErrorNumber"], :message => e["ErrorMessage"])
      end

      # Or wait! Some API's have a totally different way of reporting errors, great!
      if hash && (e = hash["Authentication"]) && e["Problem"] 
        return OpenStruct.new(:number => e["Problem"]["Code"], :message => e["Problem"]["Message"])
      end

      # And one more for Auth errors! With no error number, hooray. 
      if hash && (e = hash["AuthorizationState"]) && e["State"] == "failed"
        return OpenStruct.new(:number => nil, :message => "AuthorizationState: State: failed")
      end

      # And yet another way!
      if hash && (e = hash["Problem"])
        # Code/Message appear unpredictably at different keys? 
        return OpenStruct.new(:number => e["ErrorCode"] || e["Code"], :message => e["ErrorMessage"] || e["Message"])
      end

      return nil    
    end
  end
end