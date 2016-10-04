require 'test_helper'
require 'json'
require 'httpclient'


describe "Authentication", :vcr => {:tag => :bd_auth} do
  describe "raw request to verify HTTP api" do
    it "works" do
      uri = BorrowDirect::Defaults.api_base.chomp("/") + "/portal-service/user/authentication"


      request_hash = {
        "ApiKey"        => VCRFilter[:bd_api_key],
        "PartnershipId" => BorrowDirect::Defaults.partnership_id,
        "UserGroup"     => "patron",
        "LibrarySymbol" => VCRFilter[:bd_library_symbol],
        "PatronId"      => VCRFilter[:bd_patron]
      } 

      http = HTTPClient.new
      response = http.post uri, JSON.generate(request_hash), {"Content-Type" => "application/json", "User-Agent" => "ruby borrow_direct gem (#{BorrowDirect::VERSION}) https://github.com/jrochkind/borrow_direct", "Accept-Language" => "en"}

      assert_equal 200, response.code
      assert_present response.body

      response_hash = JSON.parse response.body

      assert_present response_hash

      assert_present response_hash["AuthorizationId"]
    end
  end

  it "Makes a request succesfully" do
    bd = BorrowDirect::Authentication.new(VCRFilter[:bd_patron] , VCRFilter[:bd_library_symbol], VCRFilter[:bd_api_key])
    response = bd.authentication_request

    assert_present response
    assert_present response["AuthorizationId"]
  end



  it "Raises for bad library symbol" do
    bd = BorrowDirect::Authentication.new(VCRFilter[:bd_patron] , "BAD_SYMBOL", VCRFilter[:bd_api_key])
    assert_raises(BorrowDirect::Error) do
      bd.authentication_request
    end
  end

  it "Raises for bad patron barcode" do
    bd = BorrowDirect::Authentication.new("BAD_BARCODE", VCRFilter[:bd_library_symbol], VCRFilter[:bd_api_key])
    assert_raises(BorrowDirect::Error) do
      bd.authentication_request
    end
  end

  it "Raises with no api_key" do
    begin
      orig_api_key = BorrowDirect::Defaults.api_key 
      BorrowDirect::Defaults.api_key = nil

      assert_raises(ArgumentError) do
        bd = BorrowDirect::Authentication.new(VCRFilter[:bd_patron] , VCRFilter[:bd_library_symbol])
      end
    ensure
      BorrowDirect::Defaults.api_key = orig_api_key      
    end
  end


  describe "get_auth_id" do
    it "returns an auth_id for a good request" do
      bd = BorrowDirect::Authentication.new(VCRFilter[:bd_patron] , VCRFilter[:bd_library_symbol], VCRFilter[:bd_api_key])
      assert_present bd.get_auth_id
    end

    it "returns auth_id with API key from defaults" do
      bd = BorrowDirect::Authentication.new(VCRFilter[:bd_patron] , VCRFilter[:bd_library_symbol])
      assert_present bd.get_auth_id
    end

    it "Raises for bad api_key" do
      assert_raises(BorrowDirect::Error) do
        bd = BorrowDirect::Authentication.new(VCRFilter[:bd_patron] , VCRFilter[:bd_library_symbol], "BAD_API_KEY").get_auth_id
      end
    end

    it "raises for a bad library symbol" do
      bd = BorrowDirect::Authentication.new(VCRFilter[:bd_patron] , "BAD_SYMBOL", VCRFilter[:bd_api_key])
      assert_raises(BorrowDirect::Error) do
        bd.get_auth_id
      end
    end

    it "raises for a bad patron barcode" do
      bd = BorrowDirect::Authentication.new("BAD_BARCODE", VCRFilter[:bd_library_symbol], VCRFilter[:bd_api_key])
      assert_raises(BorrowDirect::Error) do
        bd.get_auth_id
      end
    end

  end



end