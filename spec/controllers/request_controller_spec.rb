require 'spec_helper'
require 'request_controller'

describe RequestController do

		describe "xhold" do

			it "tests something" do
				pending
			end

		end

		describe "xrecall" do

			it "tests something" do
				pending
			end

		end		

		describe "callslip" do

			it "tests something" do
				pending
			end

		end

		describe "make_request" do

			context "callslip request" do
				it "tests something" do
					pending
				end
			end

			context "BD request" do
				it "tests something" do
					pending
				end
			end

			context "hold request" do
				it "tests something" do
					pending
				end
			end

			context "ILL request" do
				it "tests something" do
					pending
				end
			end

			context "purchase request" do
				it "tests something" do
					pending
				end
			end

			context "recall request" do
				it "tests something" do
					pending
				end
			end

			context "invalid request" do 
				it "tests something" do
					pending
				end
			end

		end

		# TODO: why are there three 'item_type' functions?
		describe "get_item_type" do

			it "tests something" do
					pending
			end

		end

		describe "_get_item_type" do

			it "tests something" do
					pending
			end

		end

		describe "get_item_types" do

			it "tests something" do
					pending
			end

		end

		describe "request_item" do
			
			let(:rc) { RequestController.new }

			context "patron is Cornell-affiliated" do

				context "loan type is regular" do

					it "uses BD RECALL ILL HOLD when the item is CHARGED" do

						# stub_request(:any, 'www.example.com').to_return(body: "<p>test</p>")
						# uri = URI('http://www.example.com')
						# res = Net::HTTP.get_response(uri)
						# res.body.should == '<p>test</p>'

						# request.env['REMOTE_USER'] = 'mjc12'
						# get :request_item, id: '12345', isbn: '12342342', title: 'hi there'
					end

					it "uses BD RECALL ILL HOLD when the item is REQUESTED"
					it "uses LTL when the item is NOT CHARGED"
					it "uses BD PURCHASE ILL when the item is MISSING or LOST"

				end

				context "loan type is day" do 

				end

				context "loan type is minute" do

				end

			end

			context "patron is not Cornell-affiliated" do

				context "loan type is regular" do

				end

				context "loan type is day" do 

				end

				context "loan type is minute" do

				end

			end

		end

		describe "get_item_status" do

			let(:rc) { RequestController.new }

			it "returns 'Not Charged' if item status includes 'Not Charged'" do
				result = rc.get_item_status 'status is Not Charged in this case'
				result.should == 'Not Charged'
			end

			it "returns 'Charged' if item status includes a left-anchored 'Charged'" do
				result = rc.get_item_status 'status is Charged in this case'
				result.should_not == 'Charged'
			end

			it "returns 'Charged' if item status includes a left-anchored 'Charged'" do
				result = rc.get_item_status 'Charged in this case'
				result.should == 'Charged'
			end

			it "returns 'Charged' if item status includes 'Renewed'" do
				result = rc.get_item_status 'status is Renewed in this case'
				result.should == 'Charged'
			end

			it "returns 'Requested' if item status includes 'Requested'" do
				result = rc.get_item_status 'status is Requested in this case'
				result.should == 'Requested'
			end

			it "returns 'Missing' if item status includes 'Missing'" do
				result = rc.get_item_status 'status is Missing in this case'
				result.should == 'Missing'
			end

			it "returns 'Lost' if item status includes 'Lost'" do
				result = rc.get_item_status 'status is Lost in this case'
				result.should == 'Lost'
			end

			it "returns the passed parameter if the status isn't recognized" do
				result = rc.get_item_status 'status is Leaving on a Jet Plane in this case'
				result.should == 'status is Leaving on a Jet Plane in this case'
			end

		end

		describe "delivery times" do

			describe "get_l2l_delivery_time" do

				let(:rc) { RequestController.new }

				it "returns 1 if the location is Library Annex" do
					result = rc.get_l2l_delivery_time 'location' => 'Library Annex' 
					result.should == 1
				end

				it "returns 2 if the location is not the Library Annex" do
					result = rc.get_l2l_delivery_time 'location' => 'Trans-Iberian Spain' 
					result.should == 2					
				end

			end

			describe "get_hold_delivery_time" do

				let(:rc) { RequestController.new }				

				it "returns 180 when passed an invalid date" do
					result = rc.get_hold_delivery_time 'itemStatus' => 'This item Due on March 50th'
					result.should == 180
				end

				it "returns 180 when a due date is in the past (overdue item)" do
					result = rc.get_hold_delivery_time 'itemStatus' => 'This item Due on 2000-01-01'
					result.should == 180					
				end
				it "returns remaining charge time + 3 when due date is in the future" do
					returnDate = Date.today + 14
					result = rc.get_hold_delivery_time 'itemStatus' => "This item Due on #{returnDate}"
					result.should == 17	
				end
			end

		end

		describe "sort_request_options" do

		end

		describe "_display" do

		end

		describe "borrowDirect_available?" do

		end

		describe "_borrowDirect_available?" do

		end

		describe "_determine_availability?" do

		end

		describe "get_holdings" do

		end

		describe "_handle_l2l" do

		end

		describe "_handle_bd" do

		end

		describe "_handle_hold" do

		end

		describe "_handle_recall" do

		end

		describe "_handle_purchase" do

		end

		describe "_handle_pda" do

		end

		describe "_handle_ill" do

		end

		describe "_handle_ask_circulation" do

		end

		describe "_handle_ask_librarian" do

		end

		describe "request_aeon" do

		end

		describe "handle_aeon" do

		end

		describe "LDAP services" do

			describe "get_ldap_dn" do

			end

			describe "patron lookup" do

				let(:rc) { RequestController.new }

				it "returns nil when passed a nil parameter" do
					result = rc.get_patron_type nil
					result. should eq(nil)
				end

				it "returns 'cornell' when patron class is faculty/staff/student" do
					result = rc.get_patron_type 'mjc12'
					result.should eq('cornell')
				end

				it "returns 'guest' when patron class is guest" do
					result = rc.get_patron_type 'gid-silterrae'
					result.should eq('guest')
				end

			end

		end


end