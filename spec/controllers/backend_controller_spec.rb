require 'spec_helper'
require 'backend_controller'

module Blacklight

	describe BackendController, "requesting an item" do

		def holdings_json_helper status

			holdings_hash = Hash.new

			if status == 'available'
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
      elsif status == 'charged'
      	holdings_hash = {
  "1419" =>  {
    "condensed_holdings_full" => [ {
      "location_name" =>  "Olin", "call_number" =>  "qx1", "status" =>  "charged", "holding_id" => [ "6181953"], "copies" => [ {
        "items" =>  {
          "Charged" =>  {
            "status" =>  "charged", "count" =>  1
          }
        },
        "notes" =>  "Notes: For holdings, check resource."
      }], "services" => []
    }]
  }
}
     	elsif status == 'missing'
     		holdings_hash = {
  "1419" =>  {
    "condensed_holdings_full" => [ {
      "location_name" =>  "Olin", "call_number" =>  "qx1", "status" =>  "missing", "holding_id" => [ "6181953"], "copies" => [ {
        "items" =>  {
          "Missing" =>  {
            "status" =>  "missing", "count" =>  1
          }
        },
        "notes" =>  "Notes: For holdings, check resource."
      }], "services" => []
    }]
  }
}
			end
			holdings_hash
		end

		describe "request_item" do

			context "item status is available" do

				before {
					@bc = BackendController.new
					@bc.stub(:get_patron_type => 'cornell')
					@bc.stub(:get_holdings).and_return(holdings_json_helper 'available')
				}

				context "loan type is regular" do
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

				context "loan type is day" do
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

				context "loan type is minute" do
					before {
						@bc.stub(:get_item_type   => 'minute')
						@result = @bc._request_item('1419', 'gid-silterrae')
					}

					it "returns ask for service" do
						@result[:service].should eq('ask')
					end
				end
			end

			context "item status is charged" do
				before {
					@bc = BackendController.new
					@bc.stub(:get_holdings).and_return(holdings_json_helper 'charged')
				}

				context "item type is regular" do
					before {
						@bc.stub(:get_item_type   => 'regular')
					}

					context "patron type is student/faculty" do
						before {
							@bc.stub(:get_patron_type   => 'cornell')
							@result = @bc._request_item('1419', 'gid-silterrae')
						}

						it "returns bd for service" do
	  					@result[:service].should eq('bd')
  					end
					end

					context "patron type is guest" do
						before {
							@bc.stub(:get_patron_type   => 'guest')
							@result = @bc._request_item('1419', 'gid-silterrae')
						}

						it "returns hold for service" do
	  					@result[:service].should eq('hold')
  					end
					end
				end

				context "item type is day" do
					before {
						@bc.stub(:get_item_type   => 'day')
						@result = @bc._request_item('1419', 'gid-silterrae')
					}

					it "returns hold for service" do
						@result[:service].should eq('hold')
					end
				end

				context "item type is minute" do
					before {
						@bc.stub(:get_item_type   => 'minute')
						@result = @bc._request_item('1419', 'gid-silterrae')
					}

					it "returns ask for service" do
						@result[:service].should eq('ask')
					end
				end
			end

			context "item status is missing/lost" do
				before {
					@bc = BackendController.new
					@bc.stub(:get_holdings).and_return(holdings_json_helper 'missing')
				}

				context "patron type is student/faculty" do
					before {
						@bc.stub(:get_patron_type   => 'cornell')
						@result = @bc._request_item('1419', 'gid-silterrae')
					}

					it "returns BD for service" do
						@result[:service].should eq('bd')
					end
				end

				context "patron type is guest" do
					before {
						@bc.stub(:get_patron_type => 'guest')
						@result = @bc._request_item('1419', 'gid-silterrae')
					}

					it "returns ask for service" do
						@result[:service].should eq('ask')
					end
				end

			end

		end

		describe "patron lookup" do

			before {
				@bc = BackendController.new
			}

			it "returns nil when passed a nil parameter" do
				result = @bc.get_patron_type nil
				result. should eq(nil)
			end

			it "returns 'cornell' when patron class is faculty/staff/student" do
				result = @bc.get_patron_type 'mjc12'
				result.should eq('cornell')
			end

			it "returns 'guest' when patron class is guest" do
				result = @bc.get_patron_type 'gid-silterrae'
				result.should eq('guest')
			end

		end

	end
end