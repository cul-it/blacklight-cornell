require 'test_helper'

require 'borrow_direct/find_item'



describe "FindItem", :vcr => {:tag => :bd_finditem }do
  before do
    @requestable_item_isbn     = "9810743734" # item is in BD, and can be requested
    @locally_avail_item_isbn   = "0061052434"  # item is in BD, but is avail locally so not BD-requestable
    @not_requestable_item_isbn = "1444367072" # in BD, and we don't have it, but no libraries let us borrow (in this case, it's an ebook)
    @returns_PUBFI002_ISBN     = "0109836413" # BD returns an error PUBFI002 for this one, which we want to treat as simply not available. 
    @not_in_BD_at_all_isbn     = "1898989898" # Not in BD at all, made up ISBN, invalid. 
  end
  


  describe "with defaults" do
    before do
      @original_symbol = BorrowDirect::Defaults.library_symbol
      @original_bar    = BorrowDirect::Defaults.find_item_patron_barcode
      BorrowDirect::Defaults.library_symbol = "OUR_SYMBOL"      
      BorrowDirect::Defaults.find_item_patron_barcode = "OUR_BARCODE"      
    end
    after do 
      BorrowDirect::Defaults.library_symbol = @original_symbol    
      BorrowDirect::Defaults.find_item_patron_barcode = @original_bar
    end

    it "uses defaults" do
      finder = BorrowDirect::FindItem.new

      assert_equal "OUR_SYMBOL",  finder.patron_library_symbol
      assert_equal "OUR_BARCODE", finder.patron_barcode
    end
  end

  describe "query production" do
    it "exact search works" do
      finder = BorrowDirect::FindItem.new("barcodeX", "libraryX")
      hash   = finder.send(:exact_search_request_hash, :isbn, "2")


      assert_equal BorrowDirect::Defaults.partnership_id, hash["PartnershipId"]
      
      # These aren't there anymore. 
      #assert_equal "barcodeX", hash["Credentials"]["Barcode"]
      #assert_equal "libraryX", hash["Credentials"]["LibrarySymbol"]

      assert_equal "ISBN", hash["ExactSearch"].first["Type"]
      assert_equal "2", hash["ExactSearch"].first["Value"]
    end

    it "works with multiple values" do
      finder = BorrowDirect::FindItem.new("barcodeX", "libraryX")
      hash   = finder.send(:exact_search_request_hash, :isbn, ["2", "3"])

      exact_searches = hash["ExactSearch"]

      assert_length 2, exact_searches

      assert_include exact_searches, {"Type"=>"ISBN", "Value"=>"2"}
      assert_include exact_searches, {"Type"=>"ISBN", "Value"=>"3"}
    end
  end

  describe "#find_item_request" do

    it "raises on no search critera" do
      assert_raises(ArgumentError) do
        BorrowDirect::FindItem.new("whatever", "whatever").find_item_request
      end
    end

    it "raises on multiple search critera" do
      assert_raises(ArgumentError) do
        BorrowDirect::FindItem.new("whatever", "whatever").find_item_request(:isbn => "1", :issn => "1")
      end
    end

    it "raises on unrecognized search criteria" do
      assert_raises(ArgumentError) do
        BorrowDirect::FindItem.new("whatever", "whatever").find_item_request(:whoknows => "1")
      end
    end

    it "raises proper error on bad AID" do
      e = assert_raises(BorrowDirect::InvalidAidError) do
        BorrowDirect::FindItem.new(VCRFilter[:bd_patron] , VCRFilter[:bd_library_symbol]).with_auth_id("bad_expired_aid").find_item_request(:isbn => @requestable_item_isbn)  
      end
      assert_present e.message
      assert_present e.bd_code
      assert_present e.aid
    end

    it "Raises with bad api_key" do
      begin
        orig_api_key = BorrowDirect::Defaults.api_key 
        BorrowDirect::Defaults.api_key = "BADAPIKEY"

        assert_raises(BorrowDirect::Error) do
          BorrowDirect::FindItem.new(VCRFilter[:bd_patron] , VCRFilter[:bd_library_symbol]).find_item_request(:isbn => @requestable_item_isbn)  
        end
      ensure
        BorrowDirect::Defaults.api_key = orig_api_key      
      end
    end


    it "finds a requestable item" do
      assert_present BorrowDirect::FindItem.new(VCRFilter[:bd_patron] , VCRFilter[:bd_library_symbol]).find_item_request(:isbn => @requestable_item_isbn)    
    end

    it "uses manually set auth_id" do
      auth_id     = BorrowDirect::Authentication.new(VCRFilter[:bd_patron] , VCRFilter[:bd_library_symbol]).get_auth_id  
      bd          = BorrowDirect::FindItem.new("bad_patron" , "bad_symbol").with_auth_id(auth_id)
      resp        = bd.find_item_request(:isbn => @requestable_item_isbn)

      assert_present resp
      assert_equal true, resp["Available"]
    end

    it "finds a locally available item" do
      assert_present BorrowDirect::FindItem.new(VCRFilter[:bd_patron] , VCRFilter[:bd_library_symbol]).find_item_request(:isbn => @locally_avail_item_isbn)    
    end

    it "finds an item that does not exist in BD" do
      assert_present BorrowDirect::FindItem.new(VCRFilter[:bd_patron] , VCRFilter[:bd_library_symbol]).find_item_request(:isbn => "NO_SUCH_THING")
    end

    it "works with multiple values" do
      assert_present BorrowDirect::FindItem.new(VCRFilter[:bd_patron] , VCRFilter[:bd_library_symbol]).find_item_request(:isbn => [@requestable_item_isbn, @locally_avail_item_isbn])
    end

    describe "with expected error PUBFI002" do
      it "returns result" do
        assert_present BorrowDirect::FindItem.new(VCRFilter[:bd_patron] , VCRFilter[:bd_library_symbol]).find_item_request(:isbn => @returns_PUBFI002_ISBN )
      end
    end
  end

  describe "find with Response" do
    before do
      @find_item = BorrowDirect::FindItem.new(VCRFilter[:bd_patron] , VCRFilter[:bd_library_symbol])
    end

    it "requestable for requestable item" do
      assert_equal true, @find_item.find(:isbn => @requestable_item_isbn).requestable?
    end



    it "requestable with multiple items if at least one is requestable" do
      assert_equal true, @find_item.find(:isbn => [@requestable_item_isbn, @not_in_BD_at_all_isbn]).requestable?
    end

    it "not requestable for locally available item" do
      assert_equal false, @find_item.find(:isbn => @locally_avail_item_isbn).requestable?
    end

    it "knows locally_available?" do
      assert_equal true, @find_item.find(:isbn => @locally_avail_item_isbn).locally_available?
    end

    it "not requestable for item that does not exist in BD" do
      assert_equal false, @find_item.find(:isbn => @not_in_BD_at_all_isbn).requestable?
    end

    it "not requestable for item that no libraries will lend" do
      assert_equal false, @find_item.find(:isbn => @not_requestable_item_isbn).requestable?
    end

    it "not requestable for item that BD returns PUBFI002" do
      assert_equal false, @find_item.find(:isbn => @returns_PUBFI002_ISBN).requestable?
    end

    it "has an auth_id" do
      assert @find_item.auth_id.nil?
      assert_present @find_item.find(:isbn => @requestable_item_isbn).auth_id
      assert_present @find_item.auth_id
    end    

    it "has pickup locations" do
      pickup_locations = @find_item.find(:isbn => @requestable_item_isbn).pickup_locations

      assert_present pickup_locations
      assert_kind_of Array, pickup_locations
      pickup_locations.each do |location|
        assert_kind_of String, location
      end
    end

    describe "#pickup_location_data" do
      it "returns array of PickupLocations" do
        pickup_locations = @find_item.find(:isbn => @requestable_item_isbn).pickup_location_data

        assert_present pickup_locations
        assert_kind_of Array, pickup_locations
        pickup_locations.each do |location|
          assert_kind_of BorrowDirect::PickupLocation, location
          assert_present location.code
          assert_present location.description

          assert_equal [location.description, location.code], location.to_a
          assert_equal( {"PickupLocationCode" => location.code, "PickupLocationDescription" => location.description}, location.to_h )
        end
      end
    end

    it "has nil pickup locations when BD doesn't want to give us them" do
      assert_nil @find_item.find(:isbn => @returns_PUBFI002_ISBN).pickup_locations
    end

  end



end