require 'spec_helper'
require 'blacklight_cornell_requests/voyager_request'
require 'vcr'
require 'james_monkeys'

describe BlacklightCornellRequests::VoyagerRequest do
 VOYAGER_GET_HOLDS = ENV['DUMMY_GET_HOLDS']
 VOYAGER_REQ_HOLDS = ENV['TEST_REQ_HOLDS']
 MYACC_URL  = ENV['MY_ACCOUNT_URL']
  it "has a valid factory" do
    FactoryGirl.create(:request).should be_valid
  end

  it "is invalid without a bibid" do
    FactoryGirl.build(:request, bibid: nil).should_not be_valid
  end

  it "has a valid initializer" do
    request = BlacklightCornellRequests::Request.new(12345)
    FactoryGirl.build(:request, bibid: 12345).bibid.should == request.bibid
  end
  it "fills in patron data correctly" do 
    @bibid, @mfhdid , @itemid, @libraryid , @reqnna , @netid  = callslipper
    req =  BlacklightCornellRequests::VoyagerRequest.new(@bibid,{:request_url => VOYAGER_REQ_HOLDS})
    req.netid = @netid
    VCR.use_cassette("patron_data_#{@netid}") do
      req.patron(@netid)
    end
    expect( req.lastname).to eq(ENV['TEST_LASTNAME']) 
  end
  def munch
  context "When the global global mode is not rest"  do
  it "switches to rest mode properly" do 
    was = BlacklightCornellRequests::VoyagerRequest.use_rest(true)
    expect( was).to eq false 
    expect( BlacklightCornellRequests::VoyagerRequest.use_rest(true)).to eq true 
  end 
  end
  end

  context "When making a hold request for a title" do
    let(:req) {
      was = BlacklightCornellRequests::VoyagerRequest.use_rest(false)
      @bibid, @mfhdid , @itemid, @libraryid , @reqnna , @netid  =  requestholder_title
      areq =  BlacklightCornellRequests::VoyagerRequest.new(@bibid,{:request_url => VOYAGER_REQ_HOLDS})
      areq.netid = @netid
      VCR.use_cassette("patron_data_#{@netid}") do
        areq.patron(@netid)
      end
      areq
    }
    it "reports success properly" do
      expect( req.lastname).to eq(ENV['TEST_LASTNAME'])
      was = BlacklightCornellRequests::VoyagerRequest.use_rest(false)
      cassette = "hold_title_response_data_#{@bibid}"
      if (BlacklightCornellRequests::VoyagerRequest.rest())
       cassette = 'rest_' + cassette
      end
      VCR.use_cassette(cassette) do
        req.itemid = '';
        req.mfhdid = '';
        req.libraryid = @libraryid;
        req.reqnna = @reqnna
        req.place_hold_title!
      end
      expect( req.mtype).to eq 'success'
      was = BlacklightCornellRequests::VoyagerRequest.use_rest(false)
    end
  end

  context "When making a hold request for an item," do
  let(:req) {
    was = BlacklightCornellRequests::VoyagerRequest.use_rest(false)
    @bibid, @mfhdid , @itemid, @libraryid , @reqnna , @netid  =  requestholder
    areq =  BlacklightCornellRequests::VoyagerRequest.new(@bibid,{:request_url => VOYAGER_REQ_HOLDS})
    areq.netid = @netid
    VCR.use_cassette("patron_data_#{@netid}") do
      areq.patron(@netid)
    end
    areq
  }
  let(:adpreq) {
    @bibid, @mfhdid , @itemid, @libraryid , @reqnna , @xnetid  =  requestholder
    @xnetid = "xxxxadp78";
    areq =  BlacklightCornellRequests::VoyagerRequest.new(@bibid,{:request_url => VOYAGER_REQ_HOLDS})
    areq.netid = @xnetid
    VCR.use_cassette("patron_data_#{@xnetid}") do
      areq.patron(@xnetid)
    end
    areq
  }
  it "reports success properly" do 
    expect( req.lastname).to eq(ENV['TEST_LASTNAME']) 
    was = BlacklightCornellRequests::VoyagerRequest.use_rest(false)
    cassette = "hold_response_data_#{@itemid}"
    if (BlacklightCornellRequests::VoyagerRequest.rest()) 
       cassette = 'rest_' + cassette
    end
    VCR.use_cassette(cassette) do
      req.itemid = @itemid;
      req.mfhdid = @mfhdid;
      req.libraryid = @libraryid;
      req.reqnna = @reqnna
      req.place_hold_item!
    end
    expect( req.mtype).to eq 'success' 
    was = BlacklightCornellRequests::VoyagerRequest.use_rest(false)
  end
  it "reports error properly" do
    expect( req.lastname).to eq(ENV['TEST_LASTNAME'])
    VCR.use_cassette("hold_response_data_fail_#{@itemid}") do
      req.itemid = @itemid
      req.mfhdid = @mfhdid
      req.libraryid = @libraryid
      req.reqnna = @reqnna
      req.place_hold_item!
    end
    expect( req.mtype).to eq 'blocked'
  end

  it "reports error properly for an invalid item id" do 
    expect( req.lastname).to eq(ENV['TEST_LASTNAME']) 
    VCR.use_cassette("hold_response_data_fail_#{@itemid}") do
      req.itemid = @itemid + "xxx"
      req.mfhdid = @mfhdid
      req.libraryid = @libraryid
      req.reqnna = @reqnna
      req.place_hold_item!
    end
    expect( req.mtype).to eq 'blocked' 
  end

  it "reports error properly for an invalid user"   do
    @netid = "xxxxadp78";
    VCR.use_cassette("hold_response_data_fail_#{@netid}_#{@itemid}") do
      adpreq.itemid = @itemid
      adpreq.mfhdid = @mfhdid
      adpreq.libraryid = @libraryid
      adpreq.reqnna = @reqnna
      adpreq.place_hold_item!
    end
    expect( adpreq.mtype).to eq 'system' 
    expect( adpreq.bcode).to eq '' 
  end
  end

  context "When making a hold request,with rest api" do
  let(:req) {
    #was = BlacklightCornellRequests::VoyagerRequest.use_rest(true)
    @bibid, @mfhdid , @itemid, @libraryid , @reqnna , @netid  =  requestholder_rest
    areq =  BlacklightCornellRequests::VoyagerRequest.new(@bibid,{:request_url => VOYAGER_REQ_HOLDS})
    areq.netid = @netid
    VCR.use_cassette("patron_data_#{@netid}") do
      areq.patron(@netid)
    end
    areq
  }
  let(:adpreq) {
    #was = BlacklightCornellRequests::VoyagerRequest.use_rest(false)
    @bibid, @mfhdid , @itemid, @libraryid , @reqnna , @xnetid  =  requestholder_rest
    @xnetid = "xxxxadp78";
    areq =  BlacklightCornellRequests::VoyagerRequest.new(@bibid,{:request_url => VOYAGER_REQ_HOLDS})
    areq.netid = @xnetid
    VCR.use_cassette("patron_data_#{@xnetid}") do
      areq.patron(@xnetid)
    end
    areq
  }
  it "reports success properly" do 
    expect( req.lastname).to eq(ENV['TEST_LASTNAME']) 
    was = BlacklightCornellRequests::VoyagerRequest.use_rest(true)
    VCR.use_cassette("rest_hold_response_data_#{@itemid}") do
      req.itemid = @itemid;
      req.mfhdid = @mfhdid;
      req.libraryid = @libraryid;
      req.reqnna = @reqnna
      #req.place_hold_item_rest!
      req.place_hold_item!
    end
    expect( req.mtype).to eq 'success' 
    was = BlacklightCornellRequests::VoyagerRequest.use_rest(was)
  end
  it "reports error properly" do
    expect( req.lastname).to eq(ENV['TEST_LASTNAME'])
    was = BlacklightCornellRequests::VoyagerRequest.use_rest(true)
    VCR.use_cassette("rest_hold_response_data_fail_#{@itemid}") do
      req.itemid = @itemid
      req.mfhdid = @mfhdid
      req.libraryid = @libraryid
      req.reqnna = @reqnna
      #req.place_hold_item_rest!
      req.place_hold_item!
    end
    expect( req.mtype).to_not eq 'success'
    expect( req.bcode).to eq '25' 
    was = BlacklightCornellRequests::VoyagerRequest.use_rest(was)
  end

  it "reports error properly for an invalid item id" do 
    expect( req.lastname).to eq(ENV['TEST_LASTNAME']) 
    req.itemid = @itemid + "xxx"
    was = BlacklightCornellRequests::VoyagerRequest.use_rest(true)
    VCR.use_cassette("rest_hold_response_data_fail_#{req.itemid}") do
      req.mfhdid = @mfhdid
      req.libraryid = @libraryid
      req.reqnna = @reqnna
      #req.place_hold_item_rest!
      req.place_hold_item!
    end
    expect( req.mtype).to_not eq 'success' 
    was = BlacklightCornellRequests::VoyagerRequest.use_rest(false)
  end

  it "reports error properly for an invalid user"   do
    @netid = "xxxxadp78";
    adpreq.itemid = @itemid
    was = BlacklightCornellRequests::VoyagerRequest.use_rest(true)
    VCR.use_cassette("rest_hold_response_data_fail_#{@netid}_#{adpreq.itemid}") do
      adpreq.mfhdid = @mfhdid
      adpreq.libraryid = @libraryid
      adpreq.reqnna = @reqnna
      adpreq.place_hold_item_rest!
    end
    expect( adpreq.mtype).to_not eq 'success' 
    was = BlacklightCornellRequests::VoyagerRequest.use_rest(false)
    expect( adpreq.bcode).to_not eq '' 
  end
  end

  context "When making a recall request for a title" do
    let(:req) {
      was = BlacklightCornellRequests::VoyagerRequest.use_rest(true)
      @bibid, @mfhdid , @itemid, @libraryid , @reqnna , @netid  =  requestholder_title
      areq =  BlacklightCornellRequests::VoyagerRequest.new(@bibid,{:request_url => VOYAGER_REQ_HOLDS})
      areq.netid = @netid
      VCR.use_cassette("patron_data_#{@netid}") do
        areq.patron(@netid)
      end
      areq
    }
    it "reports success properly" do
      expect( req.lastname).to eq(ENV['TEST_LASTNAME'])
      was = BlacklightCornellRequests::VoyagerRequest.use_rest(true)
      cassette = "recall_title_response_data_#{@bibid}"
      if (BlacklightCornellRequests::VoyagerRequest.rest())
       cassette = 'rest_' + cassette
      end
      VCR.use_cassette(cassette) do
        req.itemid = '';
        req.mfhdid = '';
        req.libraryid = @libraryid;
        req.reqnna = @reqnna
        req.place_recall_title_rest!
      end
      expect( req.mtype).to eq 'success'
      was = BlacklightCornellRequests::VoyagerRequest.use_rest(false)
    end
  end

  context "When making a recall request" do
  let(:req) {
    @bibid, @mfhdid , @itemid, @libraryid , @reqnna , @netid  =  requestholder
    areq =  BlacklightCornellRequests::VoyagerRequest.new(@bibid,{:request_url => VOYAGER_REQ_HOLDS})
    areq.netid = @netid
    VCR.use_cassette("patron_data_#{@netid}") do
      areq.patron(@netid)
    end
    areq
  }
  let(:adpreq) {
    @bibid, @mfhdid , @itemid, @libraryid , @reqnna , @xnetid  =  requestholder
    @xnetid = "xxxxadp78";
    areq =  BlacklightCornellRequests::VoyagerRequest.new(@bibid,{:request_url => VOYAGER_REQ_HOLDS})
    areq.netid = @xnetid
    VCR.use_cassette("patron_data_#{@xnetid}") do
      areq.patron(@xnetid)
    end
    areq
  }

  it "reports success properly" do 
    expect( req.lastname).to eq(ENV['TEST_LASTNAME']) 
    VCR.use_cassette("recall_response_data_#{@itemid}") do
      req.itemid = @itemid
      req.mfhdid = @mfhdid
      req.libraryid = @libraryid
      req.reqnna = @reqnna
      req.place_recall_item!
    end
    expect( req.mtype).to eq 'success' 
  end

  it "reports error properly" do 
    expect( req.lastname).to eq(ENV['TEST_LASTNAME']) 
    VCR.use_cassette("recall_response_data_fail_#{@itemid}") do
      req.itemid = @itemid
      req.mfhdid = @mfhdid
      req.libraryid = @libraryid
      req.reqnna = @reqnna
      req.place_recall_item!
    end
    expect( req.mtype).to eq 'blocked' 
  end
  it "reports error properly for a invalid item id" do 
    expect( req.lastname).to eq(ENV['TEST_LASTNAME']) 
    VCR.use_cassette("recall_response_data_fail_#{@itemid}") do
      req.itemid = @itemid + "xxx"
      req.mfhdid = @mfhdid
      req.libraryid = @libraryid
      req.reqnna = @reqnna
      req.place_recall_item!
    end
    expect( req.mtype).to eq 'blocked' 
  end
  it "reports error properly for an invalid user"   do
    @netid = "xxxxadp78";
    adpreq.netid = @netid
    VCR.use_cassette("recall_response_data_fail_#{@netid}_#{@itemid}") do
      adpreq.itemid = @itemid
      adpreq.mfhdid = @mfhdid
      adpreq.libraryid = @libraryid
      adpreq.reqnna = @reqnna
      adpreq.place_recall_item!
    end
    expect( adpreq.mtype).to eq 'system' 
    expect( adpreq.bcode).to eq '' 
  end
  end

  context "When making a recall request, with rest api" do
  let(:req) {
    @bibid, @mfhdid , @itemid, @libraryid , @reqnna , @netid  =  requestholder
    areq =  BlacklightCornellRequests::VoyagerRequest.new(@bibid,{:request_url => VOYAGER_REQ_HOLDS})
    areq.netid = @netid
    VCR.use_cassette("patron_data_#{@netid}") do
      areq.patron(@netid)
    end
    areq
  }
  let(:adpreq) {
    @bibid, @mfhdid , @itemid, @libraryid , @reqnna , @xnetid  =  requestholder
    @xnetid = "xxxxadp78";
    areq =  BlacklightCornellRequests::VoyagerRequest.new(@bibid,{:request_url => VOYAGER_REQ_HOLDS})
    areq.netid = @xnetid
    VCR.use_cassette("patron_data_#{@xnetid}") do
      areq.patron(@xnetid)
    end
    areq
  }

  it "reports success properly" do 
    expect( req.lastname).to eq(ENV['TEST_LASTNAME']) 
    was = BlacklightCornellRequests::VoyagerRequest.use_rest(false)
    cassette = "recall_response_data_#{@itemid}"
    if (BlacklightCornellRequests::VoyagerRequest.rest()) 
       cassette = 'rest_' + cassette
    end
    VCR.use_cassette(cassette) do
      req.itemid = @itemid
      req.mfhdid = @mfhdid
      req.libraryid = @libraryid
      req.reqnna = @reqnna
      req.place_recall_item!
    end
    expect( req.mtype).to eq 'success' 
    was = BlacklightCornellRequests::VoyagerRequest.use_rest(false)
  end

  it "reports error properly" do 
    expect( req.lastname).to eq(ENV['TEST_LASTNAME']) 
    was = BlacklightCornellRequests::VoyagerRequest.use_rest(true)
    VCR.use_cassette("rest_recall_response_data_fail_#{@itemid}") do
      req.itemid = @itemid
      req.mfhdid = @mfhdid
      req.libraryid = @libraryid
      req.reqnna = @reqnna
      req.place_recall_item!
    end
    expect( req.mtype).to_not eq 'success' 
    was = BlacklightCornellRequests::VoyagerRequest.use_rest(false)
  end
  it "reports error properly for a invalid item id" do 
    expect( req.lastname).to eq(ENV['TEST_LASTNAME']) 
    req.itemid = '9999999' + @itemid
    VCR.use_cassette("rest_recall_response_data_fail_#{req.itemid}") do
      req.mfhdid = @mfhdid
      req.libraryid = @libraryid
      req.reqnna = @reqnna
      req.place_recall_item_rest!
    end
    expect( req.mtype).to_not eq 'success' 
  end
  it "reports error properly for an invalid user"   do
    @netid = "xxxxadp78";
    adpreq.netid = @netid
    VCR.use_cassette("rest_recall_response_data_fail_#{@netid}_#{@itemid}") do
      adpreq.itemid = @itemid
      adpreq.mfhdid = @mfhdid
      adpreq.libraryid = @libraryid
      adpreq.reqnna = @reqnna
      adpreq.place_recall_item_rest!
    end
    expect( adpreq.mtype).to_not eq 'success' 
    expect( adpreq.bcode).to eq '51' 
  end
  end
 # Evidently callslips for titles are disabled in the configuration for our voyager.
 def disabled_callslip_title
  context "When making a call slip request for a title" do
  was = BlacklightCornellRequests::VoyagerRequest.use_rest(false)
  let(:req) {
    @bibid, @mfhdid , @itemid, @libraryid , @reqnna , @netid  =  callslipper
    areq =  BlacklightCornellRequests::VoyagerRequest.new(@bibid,{:request_url => VOYAGER_REQ_HOLDS})
    areq.netid = @netid
    VCR.use_cassette("patron_data_#{@netid}") do
      areq.patron(@netid)
    end
    areq
  }
  it "reports success properly"   do
    expect( req.lastname).to eq(ENV['TEST_LASTNAME']) 
    VCR.use_cassette("callslip_title_response_data_#{@bibid}") do
      req.itemid = '';
      req.mfhdid = '';
      req.libraryid = @libraryid
      req.reqnna = @reqnna
      req.place_callslip_title!
    end
    expect( req.mtype).to eq 'success' 
  end
  end
  end

  context "When making a call slip request" do
  was = BlacklightCornellRequests::VoyagerRequest.use_rest(false)
  let(:req) {
    @bibid, @mfhdid , @itemid, @libraryid , @reqnna , @netid  =  callslipper
    areq =  BlacklightCornellRequests::VoyagerRequest.new(@bibid,{:request_url => VOYAGER_REQ_HOLDS})
    areq.netid = @netid
    VCR.use_cassette("patron_data_#{@netid}") do
      areq.patron(@netid)
    end
    areq
  }
  let(:adpreq) {
    was = BlacklightCornellRequests::VoyagerRequest.use_rest(false)
    @bibid, @mfhdid , @itemid, @libraryid , @reqnna , @xnetid  =  callslipper
    @xnetid = "xxxxadp78";
    areq =  BlacklightCornellRequests::VoyagerRequest.new(@bibid,{:request_url => VOYAGER_REQ_HOLDS})
    areq.netid = @xnetid
    VCR.use_cassette("patron_data_#{@xnetid}") do
      areq.patron(@xnetid)
    end
    areq
  }
  it "reports success properly"   do
    expect( req.lastname).to eq(ENV['TEST_LASTNAME']) 
    VCR.use_cassette("callslip_response_data_#{@itemid}") do
      req.itemid = @itemid
      req.mfhdid = @mfhdid
      req.libraryid = @libraryid
      req.reqnna = @reqnna
      req.place_callslip_item!
    end
    expect( req.mtype).to eq 'success' 
  end

  it "reports error properly"   do
    expect( req.lastname).to eq(ENV['TEST_LASTNAME']) 
    VCR.use_cassette("callslip_response_data_fail_#{@itemid}") do
      req.itemid = @itemid
      req.mfhdid = @mfhdid
      req.libraryid = @libraryid
      req.reqnna = @reqnna
      req.place_callslip_item!
    end
    expect( req.mtype).to_not eq 'success' 
  end
  it "reports error properly for an invalid item id" do 
    expect( req.lastname).to eq(ENV['TEST_LASTNAME']) 
    VCR.use_cassette("callslip_response_data_fail_#{@itemid}") do
      req.itemid = @itemid + "xxx"
      req.mfhdid = @mfhdid
      req.libraryid = @libraryid
      req.reqnna = @reqnna
      req.place_callslip_item!
    end
    expect( req.mtype).to eq 'blocked' 
  end

  it "reports error properly for an invalid user"   do
    @netid = "xxxxadp78";
    adpreq.netid = @netid
    VCR.use_cassette("callslip_response_data_fail_#{@netid}_#{@itemid}") do
      adpreq.itemid = @itemid
      adpreq.mfhdid = @mfhdid
      adpreq.libraryid = @libraryid
      adpreq.reqnna = @reqnna
      adpreq.place_callslip_item!
    end
    expect( adpreq.mtype).to_not eq 'success' 
    #expect( adpreq.bcode).to_not eq '' 
  end
  end

  context "When making a call slip request, with rest api" do
  let(:req) {
    @bibid, @mfhdid , @itemid, @libraryid , @reqnna , @netid  =  callslipper_rest
    areq =  BlacklightCornellRequests::VoyagerRequest.new(@bibid,{:request_url => VOYAGER_REQ_HOLDS})
    areq.netid = @netid
    VCR.use_cassette("patron_data_#{@netid}") do
      areq.patron(@netid)
    end
    areq
  }
  let(:adpreq) {
    @bibid, @mfhdid , @itemid, @libraryid , @reqnna , @xnetid  =  callslipper_rest
    @xnetid = "xxxxadp78";
    areq =  BlacklightCornellRequests::VoyagerRequest.new(@bibid,{:request_url => VOYAGER_REQ_HOLDS})
    areq.netid = @xnetid
    VCR.use_cassette("patron_data_#{@xnetid}") do
      areq.patron(@xnetid)
    end
    areq
  }
  it "reports success properly"   do
    expect( req.lastname).to eq(ENV['TEST_LASTNAME']) 
    was = BlacklightCornellRequests::VoyagerRequest.use_rest(true)
    cassette =  "callslip_response_data_#{@itemid}"
    if (BlacklightCornellRequests::VoyagerRequest.rest()) 
       cassette = 'rest_' + cassette
    end
    VCR.use_cassette(cassette) do
      req.itemid = @itemid
      req.mfhdid = @mfhdid
      req.libraryid = @libraryid
      req.reqnna = @reqnna
      #req.place_callslip_item_rest!
      req.place_callslip_item!
    end
    expect( req.mtype).to eq 'success' 
    was = BlacklightCornellRequests::VoyagerRequest.use_rest(false)
  end

  it "reports error properly"   do
    expect( req.lastname).to eq(ENV['TEST_LASTNAME']) 
    VCR.use_cassette("rest_callslip_response_data_fail_#{@itemid}") do
      req.itemid = @itemid
      req.mfhdid = @mfhdid
      req.libraryid = @libraryid
      req.reqnna = @reqnna
      req.place_callslip_item_rest!
    end
    expect( req.mtype).to_not eq 'success' 
  end
  it "reports error properly for an invalid item id" do 
    expect( req.lastname).to eq(ENV['TEST_LASTNAME']) 
    req.itemid = "1"  
    VCR.use_cassette("rest_callslip_response_data_fail_#{req.itemid}") do
      req.mfhdid = @mfhdid
      req.libraryid = @libraryid
      req.reqnna = @reqnna
      req.place_callslip_item_rest!
    end
    expect( req.mtype).to_not eq 'success' 
  end

  it "reports error properly for an invalid user"   do
    @netid = "xxxxadp78";
    adpreq.netid = @netid
    VCR.use_cassette("rest_callslip_response_data_fail_#{@netid}_#{@itemid}") do
      adpreq.itemid = @itemid
      adpreq.mfhdid = @mfhdid
      adpreq.libraryid = @libraryid
      adpreq.reqnna = @reqnna
      adpreq.place_callslip_item_rest!
    end
    expect( adpreq.mtype).to_not eq 'success' 
    expect( adpreq.bcode).to eq '51' 
  end
  end

  context "Having made a call slip request" do 
  it "appears in the user account data and can be cancelled" do
    @bibid, @mfhdid , @itemid, @libraryid , @reqnna , @netid  = callslipper
    req =  BlacklightCornellRequests::VoyagerRequest.new(@bibid,{:request_url => VOYAGER_REQ_HOLDS})
    req.netid = @netid
    VCR.use_cassette("patron_data_#{@netid}") do
      req.patron(@netid)
    end
    expect( req.lastname).to eq(ENV['TEST_LASTNAME']) 
    # Generate a callslip
    VCR.use_cassette("callslip_xy3response_data_to_cancel_#{@itemid}") do
      req.itemid = @itemid
      req.mfhdid = @mfhdid
      req.libraryid = @libraryid
      req.reqnna = @reqnna
      req.place_callslip_item!
    end
    expect(req.mtype).to eq 'success' 
    # Fetch the user account data to cancel the request 
    req2 =  BlacklightCornellRequests::VoyagerRequest.new(@bibid,{:request_url => MYACC_URL})
    req2.netid = @netid
    VCR.use_cassette("patron_data_#{@netid}") do
      req2.patron(@netid)
    end
    VCR.use_cassette("user_account_xy3response_to_cancel_data_#{@netid}") do
      req2.itemid = @itemid
      req2.mfhdid = @mfhdid
      req2.libraryid = @libraryid
      req2.reqnna = @reqnna
      req2.user_account
    end
    tocancel  = req2.requests.select{|h| h[:itemid] ==  req.itemid ? true : false  }
    expect(tocancel[0]).not_to be_nil, "There should be a matching item to cancel the hold on (bib,item)(b=#{@bibid},i=#{@itemid})"
    expect(tocancel[0]).not_to be_empty, "There should be a matching item to cancel the hold on (bib,item)(b=#{@bibid},i=#{@itemid})"
    expect(tocancel[0][:itemid]).to eq(@itemid)

    req.netid = @netid
    VCR.use_cassette("patron_data_#{@netid}") do
      req.patron(@netid)
    end
    expect( req.lastname).to eq(ENV['TEST_LASTNAME']) 
    VCR.use_cassette("callslip_cancel_xy3response_data_#{@netid}_#{@itemid}") do
      req.itemid = @itemid
      req.mfhdid = @mfhdid
      req.libraryid = @libraryid
      req.reqnna = @reqnna
      req.cancel_callslip_item!(tocancel[0][:holdrecallid])
    end
    expect(req.mtype).to eq 'success' 
    expect(req.bcode).to eq '0' 
  end
  end

 context "Having made a hold request" do
 it "appears in the user account data and can be cancelled successfully" do
    @bibid, @mfhdid , @itemid, @libraryid , @reqnna , @netid  = requestholder
    req =  BlacklightCornellRequests::VoyagerRequest.new(@bibid,{:request_url => VOYAGER_REQ_HOLDS})
    req.netid = @netid
    VCR.use_cassette("patron_data_#{@netid}") do
      req.patron(@netid)
    end
    expect( req.lastname).to eq(ENV['TEST_LASTNAME']) 
    # Generate a hold 
    VCR.use_cassette("hold_xyresponse_data_#{@itemid}") do
      req.itemid = @itemid
      req.mfhdid = @mfhdid
      req.libraryid = @libraryid
      req.reqnna = @reqnna
      req.place_hold_item!
    end
    expect(req.mtype).to eq 'success' 
    # Fetch the user account data to cancel the request 
    req2 =  BlacklightCornellRequests::VoyagerRequest.new(@bibid,{:request_url => MYACC_URL})
    req2.netid = @netid
    VCR.use_cassette("patron_data_#{@netid}") do
      req2.patron(@netid)
    end
    VCR.use_cassette("hold_cancel_xyresponse_data_#{@netid}_#{@itemid}") do
      req2.itemid = @itemid
      req2.mfhdid = @mfhdid
      req2.libraryid = @libraryid
      req2.reqnna = @reqnna
      req2.user_account
    end
    # find the request for THIS item.
    tocancel  = req2.requests.select{|h| h[:itemid] ==  req.itemid ? true : false  }
    expect(tocancel[0]).not_to be_nil, "There should be a matching item to cancel the hold on (bib,item)(b=#{@bibid},i=#{@itemid})"
    expect(tocancel[0]).not_to be_empty, "There should be a matching item to cancel the hold on (bib,item)(b=#{@bibid},i=#{@itemid})"
    expect(tocancel[0][:itemid]).to eq(@itemid)
    # Fetch the user account data to cancel the request 
    #req3 =  BlacklightCornellRequests::VoyagerRequest.new(@bibid,{:request_url => VOYAGER_REQ_HOLDS})
    req.netid = @netid
    VCR.use_cassette("patron_data_#{@netid}") do
      req.patron(@netid)
    end
    expect( req.lastname).to eq(ENV['TEST_LASTNAME']) 
    VCR.use_cassette("hold_cancel_xy2response_data_#{@netid}_#{@itemid}") do
      req.itemid = @itemid
      req.mfhdid = @mfhdid
      req.libraryid = @libraryid
      req.reqnna = @reqnna
      req.cancel_hold_item!(tocancel[0][:holdrecallid])
    end
    expect(req.mtype).to eq 'success' 
    expect(req.bcode).to eq '0' 
  end
  end

 context "Having made a recall request" do
 it "appears in the user account data and can be cancelled successfully" do
    @bibid, @mfhdid , @itemid, @libraryid , @reqnna , @netid  = requestholder
    req =  BlacklightCornellRequests::VoyagerRequest.new(@bibid,{:request_url => VOYAGER_REQ_HOLDS})
    req.netid = @netid
    VCR.use_cassette("patron_data_#{@netid}") do
      req.patron(@netid)
    end
    expect( req.lastname).to eq(ENV['TEST_LASTNAME']) 
    # Generate a hold 
    VCR.use_cassette("recall_xyresponse_data_#{@itemid}") do
      req.itemid = @itemid
      req.mfhdid = @mfhdid
      req.libraryid = @libraryid
      req.reqnna = @reqnna
      req.place_hold_item!
    end
    expect(req.mtype).to eq 'success' 
    # Fetch the user account data to cancel the request 
    req2 =  BlacklightCornellRequests::VoyagerRequest.new(@bibid,{:request_url => MYACC_URL})
    req2.netid = @netid
    VCR.use_cassette("patron_data_#{@netid}") do
      req2.patron(@netid)
    end
    VCR.use_cassette("recall_cancel_xyresponse_data_#{@netid}_#{@itemid}") do
      req2.itemid = @itemid
      req2.mfhdid = @mfhdid
      req2.libraryid = @libraryid
      req2.reqnna = @reqnna
      req2.user_account
    end
    # find the request for THIS item.
    tocancel  = req2.requests.select{|h| h[:itemid] ==  req.itemid ? true : false  }
    expect(tocancel[0]).not_to be_nil, "There should be a matching item to cancel the hold on (bib,item)(b=#{@bibid},i=#{@itemid})"
    expect(tocancel[0]).not_to be_empty, "There should be a matching item to cancel the hold on (bib,item)(b=#{@bibid},i=#{@itemid})"
    expect(tocancel[0][:itemid]).to eq(@itemid)
    # Fetch the user account data to cancel the request 
    #req3 =  BlacklightCornellRequests::VoyagerRequest.new(@bibid,{:request_url => VOYAGER_REQ_HOLDS})
    req.netid = @netid
    VCR.use_cassette("patron_data_#{@netid}") do
      req.patron(@netid)
    end
    expect( req.lastname).to eq(ENV['TEST_LASTNAME']) 
    VCR.use_cassette("recall_cancel_xy2response_data_#{@netid}_#{@itemid}") do
      req.itemid = @itemid
      req.mfhdid = @mfhdid
      req.libraryid = @libraryid
      req.reqnna = @reqnna
      req.cancel_hold_item!(tocancel[0][:holdrecallid])
    end
    expect(req.mtype).to eq 'success' 
    expect(req.bcode).to eq '0' 
  end
  end




private

  # bibid,mfhdid,itemid, libraryid,date,netid
  # you can put a call slip on this one
  def callslipper
  [
     "1001",
     "5195",
     "21352",
     "189",
     "2014-09-27",
     "#{ENV['TEST_NETID']}"]
  end
  def callslipper_rest
  [
     "3623453",
     "4192460",
     "5641078",
     "181",
     "20140927",
     "#{ENV['TEST_NETID']}"]
  end

  # bibid,mfhdid,itemid, libraryid,date,netid
  # you can put a hold, or recall on this one
  # 3792882,4367276,5811637
  #
  def requestholder
   [ "6873904", "7315768", "8751586",
     "189", "2013-12-27", "#{ENV['TEST_NETID']}" ]
  end

  def requestholder_title
# 8073079 when the emperor was divine
#   [ "5476547", "", "", # Freakonomics
   [ "8073079", "", "", # when the emperor was divine
     "189", "2013-12-29", "#{ENV['TEST_NETID']}" ]
  end

  def requestholder_rest
   [ "6873904", "7315768", "8751586",
     "189", "20131227", "#{ENV['TEST_NETID']}" ]
  end

  @odd = 0

  def many_requestholder
   @odd = @odd==1 ? 0 : 1
   @odd==0 ?  [ "6873904", "7315768", "8751586",
            "189", "2013-12-27", "#{ENV['TEST_NETID']}" ]
   :       [ "3792882", "4367276", "5811637",
           "189", "2013-12-27", "#{ENV['TEST_NETID_2']}" ]
  end


end
