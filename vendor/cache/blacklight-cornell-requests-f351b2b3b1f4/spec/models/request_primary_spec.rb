require 'spec_helper'
#require 'blacklight_cornell_requests/request'
require 'blacklight_cornell_requests/borrow_direct'

describe BlacklightCornellRequests::Request do

  describe "Primary functions" do

    describe "get_cornell_delivery_options" do

      let (:request)  { FactoryGirl.create(:request) }

      context "noncirculating item" do
        context "available through borrow direct" do

          before(:each) {
            request.in_borrow_direct = true
            request.stub(:docdel_eligible?).and_return(false);
          }

          it "returns ILL and BD for 'nocirc' items" do
            item = { :item_type_id => 9 }
            options = request.get_cornell_delivery_options(item)
            expect(options.count).to eq(2)
            expect(contains?(options, ['bd','ill'])).to be true
          end

          it "return ILL and BD for other noncirculating items" do
            item = { :item_type_id => 2, :status => 1 }
            request.stub(:noncirculating?).and_return(true)
            options = request.get_cornell_delivery_options(item)
            expect(options.count).to eq(2)
            expect(contains?(options, ['bd','ill'])).to be true
          end

        end #context available through BD

        context "not available through borrow direct" do

          before(:each) {
            request.in_borrow_direct = false
            request.stub(:docdel_eligible?).and_return(false);
          }

          it "returns ILL for 'nocirc' items" do
            item = { :item_type_id => 9 }
            options = request.get_cornell_delivery_options(item)
            expect(options.count).to eq(1)
            expect(contains?(options, ['ill'])).to be true
          end

          it "return ILL for other noncirculating items" do
            item = { :item_type_id => 2, :status => 1 }
            request.stub(:noncirculating?).and_return(true)
            options = request.get_cornell_delivery_options(item)
            expect(options.count).to eq(1)
            expect(contains?(options, ['ill'])).to be true
          end

        end #context not available through BD

      end  # context noncirculating item

      context "regular loan item" do

        before(:each) {
          request.stub(:docdel_eligible?).and_return(false);
        }

        it "returns L2L if item is not charged" do
          item = { :item_type_id => 2, :status => 1 }
          options = request.get_cornell_delivery_options(item)
          expect(contains?(options, ['l2l'])).to be true
          expect(options.count).to eq(1)
        end
        
        it "returns RECALL, HOLD if item is in transit" do
          item = { :item_type_id => 2, :status => 9 }
          options = request.get_cornell_delivery_options(item)
          expect(contains?(options, ['recall', 'hold'])).to be true
          expect(options.count).to eq(2)
        end

        context "available through borrow direct" do

          before(:each) {
            request.in_borrow_direct = true
          }

          it "returns BD, ILL, RECALL, HOLD if item is charged" do
            item = { :item_type_id => 2, :status => 2 }
            options = request.get_cornell_delivery_options(item)
            expect(contains?(options, ['bd', 'ill', 'recall', 'hold'])).to be true
            expect(options.count).to eq(4)
          end

          it "returns BD, ILL, PURCHASE if item is missing" do
            item = { :item_type_id => 2, :status => 12 }
            options = request.get_cornell_delivery_options(item)
            expect(contains?(options, ['bd','ill','purchase'])).to be true
            expect(options.count).to eq(3)
          end

          it "returns BD, ILL, PURCHASE if item is lost" do
            item = { :item_type_id => 2, :status => 26 }
            options = request.get_cornell_delivery_options(item)
            expect(contains?(options, ['bd','ill','purchase'])).to be true
            expect(options.count).to eq(3)
          end

        end # context available through BD

        context "not available through borrow direct" do

          before(:each) {
            request.in_borrow_direct = false
          }

          it "returns ILL, RECALL, HOLD if item is charged" do
            item = { :item_type_id => 2, :status => 2 }
            options = request.get_cornell_delivery_options(item)
            expect(contains?(options, ['ill', 'recall', 'hold'])).to be true
            expect(options.count).to eq(3)
          end

          it "returns ILL, PURCHASE if item is missing" do
            item = { :item_type_id => 2, :status => 12 }
            options = request.get_cornell_delivery_options(item)
            expect(contains?(options, ['ill','purchase'])).to be true
            expect(options.count).to eq(2)
          end

          it "returns ILL, PURCHASE if item is lost" do
            item = { :item_type_id => 2, :status => 26 }
            options = request.get_cornell_delivery_options(item)
            expect(contains?(options, ['ill','purchase'])).to be true
            expect(options.count).to eq(2)
          end

        end # context not available through BD

      end # context regular loan item

      context "day loan item" do

        before(:each) {
          request.stub(:docdel_eligible?).and_return(false);
        }

        context "loan type excludes L2L delivery" do
          it "returns an empty set if the item is available" do
            item = { :item_type_id => 10, :status => 1 }
            options = request.get_cornell_delivery_options(item)
            expect(options).to eq([])
          end
        end
        context "loan type allows L2L delivery" do
          it "returns L2L if the item is available" do
            item = { :item_type_id => 5, :status => 1 }
            options = request.get_cornell_delivery_options(item)
            expect(contains?(options, ['l2l'])).to be true
            expect(options.count).to eq(1)
          end
        end

        context "available through BD" do

          before(:each) {
            request.in_borrow_direct = true
          }

          it "returns BD, ILL, HOLD if item is charged" do
            item = { :item_type_id => 5, :status => 2 }
            options = request.get_cornell_delivery_options(item)
            expect(contains?(options, ['bd','ill','hold'])).to be true
            expect(options.count).to eq(3)
          end

          it "returns BD, ILL, PURCHASE if item is missing" do
            item = { :item_type_id => 5, :status => 12 }
            options = request.get_cornell_delivery_options(item)
            expect(contains?(options, ['bd','ill','purchase'])).to be true
            expect(options.count).to eq(3)
          end
          it "returns BD, ILL, PURCHASE if item is lost" do
            item = { :item_type_id => 5, :status => 26 }
            options = request.get_cornell_delivery_options(item)
            expect(contains?(options, ['bd','ill','purchase'])).to be true
            expect(options.count).to eq(3)
          end
        end # not available through BD
        context "not available through BD" do

          before(:each) {
            request.in_borrow_direct = false
          }

          it "returns ILL, HOLD if item is charged" do
            item = { :item_type_id => 5, :status => 2 }
            options = request.get_cornell_delivery_options(item)
            expect(contains?(options, ['ill','hold'])).to be true
            expect(options.count).to eq(2)
          end
          it "returns ILL, PURCHASE if item is missing" do
            item = { :item_type_id => 5, :status => 12 }
            options = request.get_cornell_delivery_options(item)
            expect(contains?(options, ['ill','purchase'])).to be true
            expect(options.count).to eq(2)
          end
          it "returns ILL, PURCHASE if item is lost" do
            item = { :item_type_id => 5, :status => 26 }
            options = request.get_cornell_delivery_options(item)
            expect(contains?(options, ['ill','purchase'])).to be true
            expect(options.count).to eq(2)
          end
        end # not available through BD

      end # context day loan item

      context "minute loan item" do

        before(:each) {
          request.stub(:docdel_eligible?).and_return(false);
        }

        it "returns BD and ASK_CIRCULATION if available through borrow direct" do
          item = { :item_type_id => 12 }
          request.in_borrow_direct = true
          options = request.get_cornell_delivery_options(item)
          expect(contains?(options, ['bd', 'circ'])).to be true
          expect(options.count).to eq(2)
        end
        it "returns ASK_CIRCULATION if not available through borrow direct" do
          item = { :item_type_id => 12 }
          request.in_borrow_direct = false
          options = request.get_cornell_delivery_options(item)
          expect(contains?(options, ['circ'])).to be true
          expect(options.count).to eq(1)
        end

      end #context minute loan item

      context "item is at bindery" do

        it "returns ILL" do # why no BD?
          request.stub(:docdel_eligible?).and_return(false);
          item = { :status => 18 }
          options = request.get_cornell_delivery_options(item)
          expect(contains?(options, ['ill'])).to be true
          expect(options.count).to eq(1)
        end

      end #context item at bindery

      context "item is eligible for document delivery" do
        it "includes document delivery as an option" do
          request.stub(:docdel_eligible?).and_return(true)
          request.in_borrow_direct = true
          item = { :item_type_id => 5, :status => 2 }
          options = request.get_cornell_delivery_options(item)
          expect(contains?(options, ['document_delivery'])).to be true
        end
      end

      context "item is not eligible for document delivery" do
        it "does not include document delivery as an option" do
          request.stub(:docdel_eligible?).and_return(false);
          request.in_borrow_direct = true
          item = { :item_type_id => 5, :status => 2 }
          options = request.get_cornell_delivery_options(item)
          expect(contains?(options, ['document_delivery'])).to be false
        end
      end

    end #describe get cornell delivery options

    describe "get_guest_delivery_options" do

      let (:request)  { FactoryGirl.create(:request) }

      context "noncirculating item" do
        it "returns an empty set for 'nocirc' items" do
          item = { :item_type_id => 9 }
          options = request.get_guest_delivery_options(item)
          expect(options).to eq([])
        end
        it "return an empty set for other noncirculating items" do
          item = { :item_type_id => 2, :status => 1 }
          request.stub(:noncirculating?).and_return(true)
          options = request.get_guest_delivery_options(item)
          expect(options).to eq([])
        end
      end  # context noncirculating item

      context "regular loan item" do
        it "returns L2L if item is not charged" do
          item = { :item_type_id => 2, :status => 1 }
          options = request.get_guest_delivery_options(item)
          expect(contains?(options, ['l2l'])).to be true
          expect(options.count).to eq(1)
        end
        it "returns HOLD if item is charged" do
          item = { :item_type_id => 2, :status => 2 }
          options = request.get_guest_delivery_options(item)
          expect(contains?(options, ['hold'])).to be true
          expect(options.count).to eq(1)
        end
        it "returns an empty set if the item is missing" do
          item = { :item_type_id => 2, :status => 12 }
          options = request.get_guest_delivery_options(item)
          expect(options).to eq([])
        end
        it "returns an empty set if the item is lost" do
          item = { :item_type_id => 2, :status => 26 }
          options = request.get_guest_delivery_options(item)
          expect(options).to eq([])
        end
      end # context regular loan item

      context "day loan item" do
        it "returns L2L if item is not charged" do
          item = { :item_type_id => 5, :status => 1 }
          options = request.get_guest_delivery_options(item)
          expect(contains?(options, ['l2l'])).to be true
          expect(options.count).to eq(1)
        end
        it "returns HOLD if item is charged" do
          item = { :item_type_id => 5, :status => 2 }
          options = request.get_guest_delivery_options(item)
          expect(contains?(options, ['hold'])).to be true
          expect(options.count).to eq(1)
        end
        it "returns an empty set if the item is missing" do
          item = { :item_type_id => 5, :status => 12 }
          options = request.get_guest_delivery_options(item)
          expect(options).to eq([])
        end
        it "returns an empty set if the item is lost" do
          item = { :item_type_id => 5, :status => 26 }
          options = request.get_guest_delivery_options(item)
          expect(options).to eq([])
        end
      end # context day loan item

      context "minute loan item" do
        it "returns ask at circulation if item is not charged" do
          item = { :item_type_id => 12, :status => 1 }
          options = request.get_guest_delivery_options(item)
          expect(contains?(options, ['circ'])).to be true
          expect(options.count).to eq(1)
        end
        it "returns ask at circulation if item is charged" do
          item = { :item_type_id => 12, :status => 2 }
          options = request.get_guest_delivery_options(item)
          expect(contains?(options, ['circ'])).to be true
          expect(options.count).to eq(1)
        end
        it "returns an empty set if the item is missing" do
          item = { :item_type_id => 12, :status => 12 }
          options = request.get_guest_delivery_options(item)
          expect(options).to eq([])
        end
        it "returns an empty set if the item is lost" do
          item = { :item_type_id => 12, :status => 26 }
          options = request.get_guest_delivery_options(item)
          expect(options).to eq([])
        end
      end # context day loan item

    end #describe get guest delivery options

  end #describe primary functions

end


private

  # Helper function for detecting options. options the parameter
  # should be an array of option hashes. services is an array
  # of service identifiers (e.g., ['bd', 'ill'])
  def contains?(options, services)
    services.each do |service|
      result = options.any? { |option| option[:service] == service }
      return false unless result == true
    end
    return true
  end
