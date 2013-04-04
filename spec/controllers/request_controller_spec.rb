require 'spec_helper'
require 'request_controller'

describe RequestController do

		before :all do
			@rc = RequestController.new
		end

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

		end

		describe "_get_item_type" do

		end

		describe "get_item_types" do

		end

		describe "request_item" do

		end

		describe "get_item_status" do

		end

		describe "delivery times" do

			describe "get_l2l_delivery_time" do

			end

			describe "get_hold_delivery_time" do

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

				it "returns nil when passed a nil parameter" do
					result = @rc.get_patron_type nil
					result. should eq(nil)
				end

				it "returns 'cornell' when patron class is faculty/staff/student" do
					result = @rc.get_patron_type 'mjc12'
					result.should eq('cornell')
				end

				it "returns 'guest' when patron class is guest" do
					result = @rc.get_patron_type 'gid-silterrae'
					result.should eq('guest')
				end

			end

		end


end