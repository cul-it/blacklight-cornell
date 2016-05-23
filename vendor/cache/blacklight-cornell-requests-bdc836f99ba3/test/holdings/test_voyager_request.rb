require "helper_request"
require "minitest/autorun"

class TestRequest < VoyagerRequestTestCase
  def test_patron_data
    @bibid, @mfhdid , @itemid, @libraryid , @reqnna , @netid  = callslipper 
    req =  BlacklightCornellRequests::VoyagerRequest.new(@bibid,{:request_url => VOYAGER_REQ_HOLDS})
    req.netid = @netid
    VCR.use_cassette("patron_data_#{@netid}") do
      req.patron(@netid)
    end
    assert_equal ENV['TEST_LASTNAME'], req.lastname
  end

  def test_hold_request
    @bibid, @mfhdid , @itemid, @libraryid , @reqnna , @netid  =  requestholder
    req =  BlacklightCornellRequests::VoyagerRequest.new(@bibid,{:request_url => VOYAGER_REQ_HOLDS})
    req.netid = @netid
    VCR.use_cassette("patron_data_#{@netid}") do
      req.patron(@netid)
    end
    assert_equal ENV['TEST_LASTNAME'], req.lastname
    VCR.use_cassette("hold_response_data_#{@itemid}") do
      req.itemid = @itemid;
      req.mfhdid = @mfhdid;
      req.libraryid = @libraryid;
      req.reqnna = @reqnna
      req.place_hold_item!
    end
    assert_equal 'success', req.mtype
  end

  def test_hold_request_should_fail
    @bibid, @mfhdid , @itemid, @libraryid , @reqnna , @netid  =  requestholder
    req =  BlacklightCornellRequests::VoyagerRequest.new(@bibid,{:request_url => VOYAGER_REQ_HOLDS})
    req.netid = @netid
    VCR.use_cassette("patron_data_#{@netid}") do
      req.patron(@netid)
    end
    assert_equal ENV['TEST_LASTNAME'], req.lastname
    VCR.use_cassette("hold_response_data_fail_#{@itemid}") do
      req.itemid = @itemid + "xxx"
      req.mfhdid = @mfhdid
      req.libraryid = @libraryid
      req.reqnna = @reqnna
      req.place_hold_item!
    end
    assert_equal 'blocked', req.mtype
  end

  def test_recall_request
    @bibid, @mfhdid , @itemid, @libraryid , @reqnna , @netid  =  requestholder
    req =  BlacklightCornellRequests::VoyagerRequest.new(@bibid,{:request_url => VOYAGER_REQ_HOLDS})
    req.netid = @netid
    VCR.use_cassette("patron_data_#{@netid}") do
      req.patron(@netid)
    end
    assert_equal ENV['TEST_LASTNAME'], req.lastname
    VCR.use_cassette("recall_response_data_#{@itemid}") do
      req.itemid = @itemid
      req.mfhdid = @mfhdid
      req.libraryid = @libraryid
      req.reqnna = @reqnna
      req.place_recall_item!
    end
    assert_equal 'success', req.mtype
  end

  def test_recall_request_should_fail
    @bibid, @mfhdid , @itemid, @libraryid , @reqnna , @netid  =  requestholder
    req =  BlacklightCornellRequests::VoyagerRequest.new(@bibid,{:request_url => VOYAGER_REQ_HOLDS})
    req.netid = @netid
    VCR.use_cassette("patron_data_#{@netid}") do
      req.patron(@netid)
    end
    assert_equal ENV['TEST_LASTNAME'], req.lastname
    VCR.use_cassette("recall_response_data_fail_#{@itemid}") do
      req.itemid = @itemid
      req.mfhdid = @mfhdid
      req.libraryid = @libraryid
      req.reqnna = @reqnna
      req.place_recall_item!
    end
    assert_equal 'blocked', req.mtype
  end

  def test_callslip_request
    @bibid, @mfhdid , @itemid, @libraryid , @reqnna , @netid  = callslipper
    req =  BlacklightCornellRequests::VoyagerRequest.new(@bibid,{:request_url => VOYAGER_REQ_HOLDS})
    req.netid = @netid
    VCR.use_cassette("patron_data_#{@netid}") do
      req.patron(@netid)
    end
    assert_equal ENV['TEST_LASTNAME'], req.lastname
    VCR.use_cassette("callslip_response_data_#{@itemid}") do
      req.itemid = @itemid
      req.mfhdid = @mfhdid
      req.libraryid = @libraryid
      req.reqnna = @reqnna
      req.place_callslip_item!
    end
    assert_equal 'success', req.mtype
  end

  def test_callslip_request_should_fail
    @bibid, @mfhdid , @itemid, @libraryid , @reqnna , @netid  = callslipper
    req =  BlacklightCornellRequests::VoyagerRequest.new(@bibid,{:request_url => VOYAGER_REQ_HOLDS})
    req.netid = @netid
    VCR.use_cassette("patron_data_#{@netid}") do
      req.patron(@netid)
    end
    assert_equal ENV['TEST_LASTNAME'], req.lastname
    VCR.use_cassette("callslip_response_data_fail_#{@itemid}") do
      req.itemid = @itemid
      req.mfhdid = @mfhdid
      req.libraryid = @libraryid
      req.reqnna = @reqnna
      req.place_callslip_item!
    end
    assert_equal 'blocked', req.mtype
  end

  def test_callslip_request_should_fail_because_of_bad_user
    @bibid, @mfhdid , @itemid, @libraryid , @reqnna , @netid  = callslipper
    @netid = "xxxxadp78";
    req =  BlacklightCornellRequests::VoyagerRequest.new(@bibid,{:request_url => VOYAGER_REQ_HOLDS})
    req.netid = @netid
    VCR.use_cassette("patron_data_#{@netid}") do
      req.patron(@netid)
    end
    VCR.use_cassette("callslip_response_data_fail_#{@netid}_#{@itemid}") do
      req.itemid = @itemid
      req.mfhdid = @mfhdid
      req.libraryid = @libraryid
      req.reqnna = @reqnna
      req.place_callslip_item!
    end
    assert_equal 'system', req.mtype
    assert_equal '', req.bcode
  end

  def test_user_account
    @bibid, @mfhdid , @itemid, @libraryid , @reqnna , @netid  = callslipper
    req =  BlacklightCornellRequests::VoyagerRequest.new(@bibid,{:request_url => VOYAGER_REQ_HOLDS})
    req.netid = @netid
    VCR.use_cassette("patron_data_#{@netid}") do
      req.patron(@netid)
    end
    assert_equal ENV['TEST_LASTNAME'], req.lastname
    # Generate a callslip
    VCR.use_cassette("callslip_response_data_#{@itemid}") do
      req.itemid = @itemid
      req.mfhdid = @mfhdid
      req.libraryid = @libraryid
      req.reqnna = @reqnna
      req.place_callslip_item!
    end
    assert_equal 'success', req.mtype
    # Fetch the user account data to cancel the request 
    req2 =  BlacklightCornellRequests::VoyagerRequest.new(@bibid,{:request_url => MYACC_URL})
    req2.netid = @netid
    VCR.use_cassette("patron_data_#{@netid}") do
      req2.patron(@netid)
    end
    VCR.use_cassette("user_account_response_data_#{@netid}") do
      req2.itemid = @itemid
      req2.mfhdid = @mfhdid
      req2.libraryid = @libraryid
      req2.reqnna = @reqnna
      req2.user_account
    end
    tocancel  = req2.requests.select{|h| h[:itemid] ==  req.itemid ? true : false  }
    assert_equal tocancel[0][:itemid],@itemid
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
     "#{ENV['TEST_NETID']}"
  end

  # bibid,mfhdid,itemid, libraryid,date,netid
  # you can put a hold, or recall on this one
  # 3792882,4367276,5811637
  #
  def requestholder
   [ "6873904", "7315768", "8751586",
     "189", "2013-09-27", "#{ENV['TEST_NETID']}" ]
  end

  @odd = 0

  def many_requestholder
   @odd = @odd==1 ? 0 : 1
   @odd==0 ?  [ "6873904", "7315768", "8751586",
            "189", "2013-09-27", "#{ENV['TEST_NETID']}" ]
   :       [ "3792882", "4367276", "5811637",
           "189", "2013-09-27", "#{ENV['TEST_NETID_2']}" ]
  end

end
