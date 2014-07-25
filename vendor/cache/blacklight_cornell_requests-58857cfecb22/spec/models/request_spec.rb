require 'spec_helper'
require 'blacklight_cornell_requests/request'
require 'blacklight_cornell_requests/borrow_direct'

describe BlacklightCornellRequests::Request do

  ############################### Basic class tests ##############################


  ################### Functions outside the main routine #######################
  describe "Secondary functions" do

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

    end

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

    end

    describe 'sort_request_options' do 

      let(:options) { [ {:estimate => [3,5]}, {:estimate => [1,1]}, {:estimate => [4,6] }]}

      it 'puts requests in order by delivery times' do
        request = FactoryGirl.create(:request)
        sorted_options = request.sort_request_options options
        puts "sorted: #{sorted_options}"
        expect(sorted_options).to eq([{:estimate=>[1, 1]}, {:estimate=>[3, 5]}, {:estimate=>[4, 6]}])
      end

    end




  end



end
