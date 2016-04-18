require 'test_helper'
require 'borrow_direct/request'




describe "Request", :vcr => {:tag => :bd_request } do
  before do
    @successful_item_isbn = "9810743734"

    @aid = BorrowDirect::Authentication.new(VCRFilter[:bd_patron], VCRFilter[:bd_library_symbol]).get_auth_id
  end


  it "raises on bad path"  do
    assert_raises(BorrowDirect::HttpError) do
      response = BorrowDirect::Request.new("/no/such/path").request( "foo" => "bar" )
    end
  end

  it "raises on bad request hash" do
    assert_raises(BorrowDirect::Error) do
      response = BorrowDirect::Request.new("/dws/item/available").request( {"foo" => "bar"},  @aid )
    end
  end

  it "gets BD error info" do
    request = {
        "PartnershipId" => "BAD_ID",
        "Credentials" => {
            "LibrarySymbol" => "librarySymbol",
            "Barcode" => "barcode/patronId"
        },
        "ExactSearch" => [
            {
                "Type" => "type",
                "Value" => "value"
            }
        ]
    }

    e = assert_raises(BorrowDirect::Error) do
      response = BorrowDirect::Request.new("/dws/item/available").request( request )      
    end

    refute_nil e
    refute_nil e.message
    refute_nil e.bd_code
  end

  it "gets BD error info from a bad AID" do
    request = {
        "PartnershipId" => "BD",
        "ExactSearch" => [
            {
                "Type" => "ISBN",
                "Value" => @successful_item_isbn
            }
        ]
    }

    e = assert_raises(BorrowDirect::InvalidAidError) do
      response = BorrowDirect::Request.new("/dws/item/available").request( request, "bad_aid" )      
    end

    refute_nil e
    assert_equal "PUBFI003", e.bd_code
  end

  it "can make a succesful request with AID" do
      request = {
          "PartnershipId" => "BD",
          "ExactSearch" => [
              {
                  "Type" => "ISBN",
                  "Value" => @successful_item_isbn
              }
          ]
      }

      
    response = BorrowDirect::Request.new("/dws/item/available").request( request, @aid )      
  end

  it "uses timeout for HttpClient" do
    request = BorrowDirect::Request.new("/some/path")
    request.timeout = 5

    http_client = request.http_client

    assert_equal 5, http_client.send_timeout
    assert_equal 5, http_client.receive_timeout
    assert_equal 5, http_client.connect_timeout
  end

  
  it "raises exception on timeout, live" do
    skip "Can't get this to work with VCR and new API"

    request = {
      "PartnershipId" => "BD",
      "ExactSearch" => [
          {
              "Type" => "ISBN",
              "Value" => @successful_item_isbn
          }
        ]
      }
    # Using a Bad URI here keeps VCR from interfering with us too much. 
    bd = BorrowDirect::Request.new("/dws/item/available_bad_uri")
    # tiny timeout, it'll def timeout, and on connect no less
    bd.timeout = 0.00000001
    timeout_error = assert_raises(BorrowDirect::HttpTimeoutError) do 
      response = bd.request( request, @aid )     
    end
    assert_equal bd.timeout, timeout_error.timeout 

    # little bit longer to get maybe a receive timeout instead
    bd = BorrowDirect::Request.new("/dws/item/available_bad_uri")
    bd.timeout = 0.10
    timeout_error = assert_raises(BorrowDirect::HttpTimeoutError) do 
      response = bd.request( request, @aid )     
    end
    assert_equal bd.timeout, timeout_error.timeout 
  end

  describe "with expected errors" do
    it "still returns result" do
      request = {
          "PartnershipId" => "BD",
          "ExactSearch" => [
              {
                  "Type" => "BADBAD",
                  "Value" => "2292389283928392382938"
              }
          ]
      }

      bd = BorrowDirect::Request.new("/dws/item/available")
      bd.expected_error_codes << "PRIFI001"
      response = bd.request( request, @aid )      

      assert_present response
    
    end
  end

  describe "authentication id" do
    it "starts out nil" do
      assert_nil BorrowDirect::Request.new("/").auth_id
    end

    it "manually set one will be used without fetch" do
      r = BorrowDirect::Request.new("/")
      r.auth_id = "OUR_AUTH_ID"

      assert_equal "OUR_AUTH_ID", r.need_auth_id("wont_use_this", "or_this")
    end

    it "automatically fetches one when needed" do
      r = BorrowDirect::Request.new("/")
      auth_id = r.need_auth_id(VCRFilter[:bd_patron], VCRFilter[:bd_library_symbol])

      assert_present auth_id
      assert_equal auth_id, r.auth_id
    end

    it "can refetch when instructed" do
      r = BorrowDirect::Request.new("/")

      r.auth_id = "OLD_BAD_AUTH_ID"
      fetched = r.fetch_auth_id!(VCRFilter[:bd_patron], VCRFilter[:bd_library_symbol])

      assert_present r.auth_id
      assert_equal fetched, r.auth_id
      refute_equal "OLD_BAD_AUTH_ID", r.auth_id
    end

    it "takes with_auth_id" do
      r = BorrowDirect::Request.new("/").with_auth_id("OUR_AUTH_ID")
      assert_equal "OUR_AUTH_ID", r.auth_id
    end
  end

end