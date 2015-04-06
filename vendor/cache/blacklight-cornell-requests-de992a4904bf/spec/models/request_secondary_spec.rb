require 'spec_helper'
#require 'blacklight_cornell_requests/request'
require 'blacklight_cornell_requests/borrow_direct'

describe BlacklightCornellRequests::Request do

  ############################### Basic class tests ##############################


  ################### Functions outside the main routine #######################
  describe "Secondary request functions" do

    # make_voyager_request
    # create_ill_link

    describe "populate_document_values" do

      let (:request)  { FactoryGirl.create(:request) }
      let (:document) { { :isbn_display => ['12345'],
                          :title_display => 'Test',
                          :author_display => ['Mr. Testcase']
                       } }
      before (:each) do
        request.document = document
        request.populate_document_values
      end

      it "sets the request ISBN" do
        expect(request.isbn).to equal(document[:isbn_display])
      end

      it "sets the request title" do
        expect(request.ti).to equal(document[:title_display])
      end

      context 'when there is an author_display field' do
        it 'sets the request author' do
          expect(request.au).to eq(document[:author_display])
        end
      end

      context 'when there is an author_addl_display field' do
        it 'sets the request author' do
          request.document[:author_display] = nil
          request.document[:author_addl_display] = ['Mr. Testcase']
          request.populate_document_values
          expect(request.au).to eq(document[:author_addl_display][0])
        end
      end

      context 'when there is no author field' do
        it 'does not set the request author' do
          request.document[:author_display] = nil
          request.populate_document_values
          expect(request.au).to eq('')
        end
      end

    end #describe populate document values

    describe 'get_delivery_time' do

      let (:request)  { FactoryGirl.create(:request) }

      context 'requesting L2L' do

        context 'item is in annex' do

          it 'returns a range of [1,2]' do
            result = request.get_delivery_time 'l2l', { :location => 'Library Annex' }, true
            expect(result).to eq([1,2])
          end

          it 'returns a single value of 1' do
            result = request.get_delivery_time 'l2l', { :location => 'Library Annex' }, false
            expect(result).to equal(1)
          end
        end

        context 'item not in annex' do

          it 'returns a range of [1,2]' do
            result = request.get_delivery_time 'l2l', {  }, true
            expect(result).to eq([2,2])
          end

          it 'returns a single value of 1' do
            result = request.get_delivery_time 'l2l', {  }, false
            expect(result).to equal(2)
          end

        end

      end

      context 'requesting BD' do

          it 'returns a range of [3,5]' do
            result = request.get_delivery_time 'bd', {  }, true
            expect(result).to eq([3,5])
          end

          it 'returns a single value of 3' do
            result = request.get_delivery_time 'bd', {  }, false
            expect(result).to equal(3)
          end

      end

      context 'requesting ILL' do

          it 'returns a range of [7,14]' do
            result = request.get_delivery_time 'ill', {  }, true
            expect(result).to eq([7,14])
          end

          it 'returns a single value of 7' do
            result = request.get_delivery_time 'ill', {  }, false
            expect(result).to equal(7)
          end

      end

      context 'requesting hold' do

          it 'returns a range of [180,180]' do
            result = request.get_delivery_time 'hold', {  }, true
            expect(result).to eq([180,180])
          end

          it 'returns a single value of 180' do
            result = request.get_delivery_time 'hold', {  }, false
            expect(result).to equal(180)
          end

      end

      context 'requesting recall' do

          it 'returns a range of [15,15]' do
            result = request.get_delivery_time 'recall', {  }, true
            expect(result).to eq([15,15])
          end

          it 'returns a single value of 15' do
            result = request.get_delivery_time 'recall', {  }, false
            expect(result).to equal(15)
          end

      end

      context 'requesting PDA' do

          it 'returns a range of [5,5]' do
            result = request.get_delivery_time 'pda', {  }, true
            expect(result).to eq([5,5])
          end

          it 'returns a single value of 5' do
            result = request.get_delivery_time 'pda', {  }, false
            expect(result).to equal(5)
          end

      end

      context 'requesting purchase' do

          it 'returns a range of [10,10]' do
            result = request.get_delivery_time 'purchase', {  }, true
            expect(result).to eq([10,10])
          end

          it 'returns a single value of 10' do
            result = request.get_delivery_time 'purchase', {  }, false
            expect(result).to equal(10)
          end

      end

      context 'requesting document delivery' do

        let(:items) { [{:status => 'Charged'}, {:status => 'Charged'} ] }

        context 'at least one item is available' do

          before {
            #items << { :status => 'Not Charged' }
            items << { :status => 1 }
            request.all_items = items
          }
          it 'returns a range of [2,2]' do
            result = request.get_delivery_time 'document_delivery', {  }, true
            expect(result).to eq([2,2])
          end

          it 'returns a single value of 2' do
            result = request.get_delivery_time 'document_delivery', {  }, false
            expect(result).to eq(2)
          end

        end

        context 'no items are available' do

          before { request.all_items = items }
          it 'returns a range of [9,9]' do
            result = request.get_delivery_time 'document_delivery', {  }, true
            expect(result).to eq([9,9])
          end

          it 'returns a single value of 9' do
            result = request.get_delivery_time 'document_delivery', {  }, false
            expect(result).to equal(9)
          end

        end

      end

      context 'ask a librarian' do

          it 'returns a range of [9999,9999]' do
            result = request.get_delivery_time 'ask', {  }, true
            expect(result).to eq([9999,9999])
          end

          it 'returns a single value of 9999' do
            result = request.get_delivery_time 'ask', {  }, false
            expect(result).to equal(9999)
          end

      end

      context 'ask at circulation' do

          it 'returns a range of [9998,9998]' do
            result = request.get_delivery_time 'circ', {  }, true
            expect(result).to eq([9998,9998])
          end

          it 'returns a single value of 9998' do
            result = request.get_delivery_time 'circ', {  }, false
            expect(result).to equal(9998)
          end

      end

      context 'the request type is unknown' do

          it 'returns a range of [9999,9999]' do
            result = request.get_delivery_time '?', {  }, true
            expect(result).to eq([9999,9999])
          end

          it 'returns a single value of 9999' do
            result = request.get_delivery_time '?', {  }, false
            expect(result).to equal(9999)
          end

      end

    end #describe get delivery time

    describe 'sort_request_options' do

      let(:options) { [ {:estimate => [3,5]}, {:estimate => [1,1]}, {:estimate => [4,6] }]}

      it 'puts requests in order by delivery times' do
        request = FactoryGirl.create(:request)
        sorted_options = request.sort_request_options options
        expect(sorted_options).to eq([{:estimate=>[1, 1]}, {:estimate=>[3, 5]}, {:estimate=>[4, 6]}])
      end

    end #describe sort request options

    describe "item_status" do

      let (:request)  { FactoryGirl.create(:request) }
      R = BlacklightCornellRequests::Request

      it "returns NOT_CHARGED for not-charged items" do
        expect(request.item_status(R::NOT_CHARGED)).to eq(R::NOT_CHARGED)
        expect(request.item_status(R::DISCHARGED)).to eq(R::NOT_CHARGED)
        expect(request.item_status(R::CATALOG_REVIEW)).to eq(R::NOT_CHARGED)
        expect(request.item_status(R::CIRCULATION_REVIEW)).to eq(R::NOT_CHARGED)
        expect(request.item_status(R::IN_TRANSIT)).to eq(R::NOT_CHARGED)
        expect(request.item_status(R::IN_TRANSIT_DISCHARGED)).to eq(R::NOT_CHARGED)
      end

      it "returns CHARGED for charged items" do
        expect(request.item_status(R::CHARGED)).to eq(R::CHARGED)
        expect(request.item_status(R::RENEWED)).to eq(R::CHARGED)
        expect(request.item_status(R::CALL_SLIP_REQUEST)).to eq(R::CHARGED)
        expect(request.item_status(R::RECALL_REQUEST)).to eq(R::CHARGED)
        expect(request.item_status(R::HOLD_REQUEST)).to eq(R::CHARGED)
        expect(request.item_status(R::IN_TRANSIT_ON_HOLD)).to eq(R::CHARGED)
        expect(request.item_status(R::OVERDUE)).to eq(R::CHARGED)
        expect(request.item_status(R::CLAIMS_RETURNED)).to eq(R::CHARGED)
        expect(request.item_status(R::DAMAGED)).to eq(R::CHARGED)
        expect(request.item_status(R::WITHDRAWN)).to eq(R::CHARGED)
        expect(request.item_status(R::ON_HOLD)).to eq(R::CHARGED)

      end

      it "returns MISSING for missing items" do
        expect(request.item_status(R::MISSING)).to eq(R::MISSING)
      end

      it "returns LOST for lost items" do
        expect(request.item_status(R::LOST_LIBRARY_APPLIED)).to eq(R::LOST)
        expect(request.item_status(R::LOST_SYSTEM_APPLIED)).to eq(R::LOST)
        expect(request.item_status(R::LOST)).to eq(R::LOST)
      end

      it "returns AT_BINDERY for items at bindery" do
        expect(request.item_status(R::AT_BINDERY)).to eq(R::AT_BINDERY)
      end

      it "echoes an unidentifiable status" do
        expect(request.item_status('asdfasdf')).to eq('asdfasdf')
      end

    end #describe item status

    describe "sort_request_options" do

      let (:request)  { FactoryGirl.create(:request) }

      it "sorts options from slowest to fastest delivery time" do
        options = [{:estimate => [7]}, {:estimate => [3]},
                   {:estimate => [10]}, {:estimate => [5]}]
        sorted_options = request.sort_request_options options
        expect(sorted_options[0][:estimate][0]).to eq(3)
        expect(sorted_options[3][:estimate][0]).to eq(10)
      end
    end

    describe "#noncirculating?" do

      let (:request)  { FactoryGirl.create(:request) }


      it "returns true if an item is noncirculating in a permanent location" do
          item = { 'perm_location' => { 'name' => 'Test Place Non-Circulating' } }
          expect(request.noncirculating?(item)).to be true
      end

      it "returns false if an item is circulating in a permanent location" do
        item = { 'perm_location' => { 'name' => 'Test Place' } }
        expect(request.noncirculating?(item)).to be false
      end

      it "returns true if an item is noncirculating in a temporary location" do
        item = { 'perm_location' => { 'name' => 'Test Place Non-Circulating' },
                 'temp_location_display_name' => 'Temporary Test Place Reserve' }
        expect(request.noncirculating?(item)).to be true
      end

      it "returns true if an item is circulating in a temporary location" do
        item = { 'perm_location' => { 'name' => 'Test Place' },
                 'temp_location_display_name' => 'Temporary Test Place' }
        expect(request.noncirculating?(item)).to be false
      end

    end

    describe "#available_in_bd?" do

      let (:request)  { FactoryGirl.create(:request) }

      it "returns true for an available ISBN" do
        request.stub(:patron_barcode).and_return(ENV['TEST_USER_BARCODE'])
        VCR.use_cassette('bd_isbn_success') do
          response = request.available_in_bd?('abcde', {:isbn => '9781590174470'})
          expect(response).to be true
        end
      end

      it "returns false for an unavailable ISBN" do
        request.stub(:patron_barcode).and_return(ENV['TEST_USER_BARCODE'])
        VCR.use_cassette('bd_isbn_failure') do
          response = request.available_in_bd?('abcde', {:isbn =>'1'})
          expect(response).to be false
        end
      end

      it "returns true for an available title (phrase search)" do
        request.stub(:patron_barcode).and_return(ENV['TEST_USER_BARCODE'])
        VCR.use_cassette('bd_title_success') do
          response = request.available_in_bd?('abcde', {:title =>'Masscult and Midcult'})
          expect(response).to be true
        end
      end

      it "returns false for an unavailable title (phrase search)" do
        request.stub(:patron_barcode).and_return(ENV['TEST_USER_BARCODE'])
        VCR.use_cassette('bd_title_failure') do
          response = request.available_in_bd?('abcde', {:title =>'ZVBXRPL'})
          expect(response).to be false
        end
      end

    end

    describe "#patron_barcode" do

      let (:request)  { FactoryGirl.create(:request) }

      it "returns nil for an invalid netid" do
        VCR.use_cassette('netid_invalid') do
          response = request.patron_barcode 'abcde'
          expect(response).to be nil
        end
      end

      it "returns the barcode for a valid netid" do
        VCR.use_cassette('netid_valid') do
          response = request.patron_barcode ENV['TEST_NETID']
          expect(response).to eq(ENV['TEST_USER_BARCODE'])
        end
      end

    end

  end # describe secondary functions



end #describe request
