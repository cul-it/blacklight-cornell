require 'test_helper'
require 'httpclient'




describe "RequestQuery", :vcr => {:tag => :bd_request_query} do
  before do 
    @requestable_item_isbn     = "9797994864" # item is in BD, and can be requested
  end

  it "raw request to verify the BD HTTP API" do

    # Get the auth code
    auth_id = BorrowDirect::Authentication.new(VCRFilter[:bd_patron], VCRFilter[:bd_library_symbol]).get_auth_id
    
    # Now use it to make a RequestQuery request. Note, BD API requires
    # you to use the same User-Agent you used to receive the auth id. 

      query = {
        "aid" => auth_id,
        "type" => "open",
        "fullRecord" => "0"
      }

      headers = { "Content-Type" => "application/json",
        "User-Agent" => "ruby borrow_direct gem #{BorrowDirect::VERSION} (HTTPClient #{HTTPClient::VERSION}) https://github.com/jrochkind/borrow_direct",
        "Accept-Language" => "en"
      }

      uri = BorrowDirect::Defaults.api_base.chomp("/") + "/portal-service/request/query/my"            

      http = HTTPClient.new
      http_response = http.get uri, query, headers

      assert_equal 200, http_response.code
      assert_present http_response.body

      response_hash = JSON.parse http_response.body

      assert_present response_hash
      assert_kind_of Array, response_hash["MyRequestRecords"]
  end

  it "raises proper error on bad AID" do
    e = assert_raises(BorrowDirect::InvalidAidError) do
      BorrowDirect::RequestQuery.new(VCRFilter[:bd_patron]).with_auth_id("bad_expired_id").request_query_request
    end
    assert_present e.message
    assert_present e.aid
  end

  describe "raw request_query_request" do
    it "returns results" do
      request_query = BorrowDirect::RequestQuery.new(VCRFilter[:bd_patron], VCRFilter[:bd_library_symbol])
      response = request_query.request_query_request

      assert_present response      
      assert_kind_of Hash, response
      assert_present response["MyRequestRecords"]
      assert_kind_of Array, response["MyRequestRecords"]
    end
  end

  describe "requests" do
    it "fetches default records" do
      request_query = BorrowDirect::RequestQuery.new(VCRFilter[:bd_patron], VCRFilter[:bd_library_symbol])
      results = request_query.requests

      assert_kind_of Array, results

      item = results.sample

      [ :request_number, :title, :request_status].each do |key|
        assert_present item.send key
      end

      [:allow_renew, :allow_cancel].each do |key|
        assert_includes [true, false], item.send(key)
      end

      # Huh, records don't seem to reliably have these, so we
      # can't test for them, bah. 
      #[:request_status_date, :date_submitted].each do |key|
      #  assert_present item.send(key)
      #  assert_kind_of DateTime, item.send(key)
      #end
    end

    it "fetches full records" do
      request_query = BorrowDirect::RequestQuery.new(VCRFilter[:bd_patron], VCRFilter[:bd_library_symbol])
      results = request_query.requests("all", true)

      assert_kind_of Array, results
      # too hard to test presence of each attributes, as not every item has every
      # attribute and too hard to find examples to test. 
    end

  end






end



