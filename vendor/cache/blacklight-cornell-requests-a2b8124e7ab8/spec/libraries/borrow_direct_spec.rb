require 'spec_helper'
require 'vcr'
require 'blacklight_cornell_requests/borrow_direct'

describe BlacklightCornellRequests::CULBorrowDirect do

  # describe ".available_in_bd?" do
  #
  #   let(:bd) { BlacklightCornellRequests::CULBorrowDirect }
  #
  #   it "returns true for an available ISBN" do
  #     bd.stub(:patron_barcode).and_return(ENV['TEST_USER_BARCODE'])
  #     VCR.use_cassette('bd_isbn_success') do
  #       response = bd.available_in_bd?('abcde', {:isbn => '9781590174470'})
  #       expect(response).to be true
  #     end
  #   end
  #
  #   it "returns false for an unavailable ISBN" do
  #     bd.stub(:patron_barcode).and_return(ENV['TEST_USER_BARCODE'])
  #     VCR.use_cassette('bd_isbn_failure') do
  #       response = bd.available_in_bd?('abcde', {:isbn =>'1'})
  #       expect(response).to be false
  #     end
  #   end
  #
  #   it "returns true for an available title (phrase search)" do
  #     bd.stub(:patron_barcode).and_return(ENV['TEST_USER_BARCODE'])
  #     VCR.use_cassette('bd_title_success') do
  #       response = bd.available_in_bd?('abcde', {:title =>'Masscult and Midcult'})
  #       expect(response).to be true
  #     end
  #   end
  #
  #   it "returns false for an unavailable title (phrase search)" do
  #     bd.stub(:patron_barcode).and_return(ENV['TEST_USER_BARCODE'])
  #     VCR.use_cassette('bd_title_failure') do
  #       response = bd.available_in_bd?('abcde', {:title =>'ZVBXRPL'})
  #       expect(response).to be false
  #     end
  #   end
  #
  # end
  #
  # describe ".patron_barcode" do
  #
  #   it "returns nil for an invalid netid" do
  #     VCR.use_cassette('netid_invalid') do
  #       response = BlacklightCornellRequests::CULBorrowDirect.patron_barcode 'abcde'
  #       expect(response).to be nil
  #     end
  #   end
  #
  #   it "returns the barcode for a valid netid" do
  #     VCR.use_cassette('netid_valid') do
  #       response = BlacklightCornellRequests::CULBorrowDirect.patron_barcode ENV['TEST_NETID']
  #       expect(response).to eq(ENV['TEST_USER_BARCODE'])
  #     end
  #   end
  #
  # end


end
