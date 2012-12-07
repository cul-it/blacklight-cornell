require 'spec_helper'
require 'backend_controller'

module Blacklight

	describe BackendController, "requesting an item" do

		def holdings_json_helper

			holdings_hash = Hash.new

			holdings_hash = {
  "1419" =>  {
    "condensed_holdings_full" => [ {
      "location_name" =>  "*Networked Resource", "call_number" =>  "No call number", "status" =>  "none", "holding_id" => [ "6181953"], "copies" => [ {
        "items" =>  {
          "Status unknown" =>  {
            "status" =>  "none", "count" =>  1
          }
        },
        "notes" =>  "Notes: For holdings, check resource."
      }], "services" => []
    }, {
      "location_name" =>  "Law Library (Myron Taylor Hall)", "call_number" =>  "KF4627 .S43 1962", "status" =>  "available", "holding_id" => [ "5777"], "copies" => [ {
        "items" =>  {
          "Available" =>  {
            "status" =>  "available", "count" =>  1
          }
        },
        "summary_holdings" =>  "Library has: v.1-2"
      }], "services" => []
    }, {
      "location_name" =>  "Library Annex", "call_number" =>  "QB281 .S39", "status" =>  "available", "holding_id" => [ "5778"], "copies" => [ {
        "items" =>  {
          "Available" =>  {
            "status" =>  "available", "count" =>  1
          }
        },
        "summary_holdings" =>  "Library has: v.2"
      }], "services" => []
    }, {
      "location_name" =>  "Olin Library", "call_number" =>  "Oversize HD205 1962 .S52 +", "status" =>  "available", "holding_id" => [ "5248430", "5248433"], "copies" => [ {
        "items" =>  {
          "Available" =>  {
            "status" =>  "available", "count" =>  1
          }
        },
        "summary_holdings" =>  "Library has: v.1-2"
      }, {
        "items" =>  {
          "Available" =>  {
            "status" =>  "available", "count" =>  1
          }
        },
        "summary_holdings" =>  "Library has: v.1-2"
      }], "services" => []
    }]
  }
}
			holdings_hash
		end

		describe "request_item" do

			context "item status is available" do

				before {
					@bc = BackendController.new
					@bc.stub(:get_patron_type => 'cornell')
					@bc.stub(:get_holdings    => holdings_json_helper)
				}

				describe "loan type is regular" do
					before {
						@bc.stub(:get_item_type   => 'regular')
						@result = @bc._request_item('1419', 'gid-silterrae')
					}

					it "returns L2L for service" do
						@result[:service].should eq('l2l')
					end

					it "returns the holdings ID for the available item" do
					  @result[:holding_id].should eq('5777')
					end

  				it "returns the location for the availble item" do
				  	@result[:location].should eq('Law Library (Myron Taylor Hall)')
				  end
				end

				describe "loan type is day" do
					before {
						@bc.stub(:get_item_type   => 'day')
						@result = @bc._request_item('1419', 'gid-silterrae')
					}

					it "returns L2L for service" do
						@result[:service].should eq('l2l')
					end

					it "returns the holdings ID for the available item" do
					  @result[:holding_id].should eq('5777')
					end

  				it "returns the location for the availble item" do
				  	@result[:location].should eq('Law Library (Myron Taylor Hall)')
				  end
				end

				describe "loan type is minute" do
					before {
						@bc.stub(:get_item_type   => 'minute')
						@result = @bc._request_item('1419', 'gid-silterrae')
					}

					it "returns ask for service" do
						@result[:service].should eq('ask')
					end
				end

			end

		end
			

	end
end