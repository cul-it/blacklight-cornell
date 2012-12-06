require 'spec_helper'
require 'backend_controller'

module Blacklight

	describe BackendController, "requesting an item" do

		def holdings_json_helper

			holdings_hash = Hash.new

			holdings_hash = { '1419' => 
								{ :condensed_holdings_full => [
									{ 	:location_name => '*Networked Resource',
										:call_number   => 'No call number',
										:status        => 'none',
										:holding_id    => '6181953',
										:copies        => [
											{ :items => {
												'Status unknown' => {
													:status => 'none',
													:count  => 1
												}
											},
											:notes => 'Notes: For holdings, check resource.'
										}],
										:services => []
									}, 
									{ 	:location_name => 'Law Library (Myron Taylor Hall)',
										:call_number   => 'KF4627 .S43 1962',
										:status        => 'available',
										:holding_id    => ['5777'],
										:copies        => [
											{ :items => {
												'Available' => {
													:status => 'available',
													:count  => 1
												}
											},
											:summary_holdings => 'Library has: v.1-2'
										}],
										:services => []
									},
									{ 	:location_name => 'Library Annex)',
										:call_number   => 'QB281 .S39',
										:status        => 'available',
										:holding_id    => ['5778'],
										:copies        => [
											{ :items => {
												'Available' => {
													:status => 'available',
													:count  => 1
												}
											},
											:summary_holdings => 'Library has: v.2'
										}],
										:services => []
									},
									{ 	:location_name => 'Olin Library)',
										:call_number   => 'Oversize HD205 1962 .S52 +',
										:status        => 'available',
										:holding_id    => ["5248430","5248433"],
										:copies        => [
											{ :items => {
												'Available' => {
													:status => 'available',
													:count  => 1
												}
											},
											:summary_holdings => 'Library has: v.1-2'
										},
										{ :items => {
												'Available' => {
													:status => 'available',
													:count  => 1
												}
											},
											:summary_holdings => 'Library has: v.1-2'
										}
										],
										:services => []
									}
								]
								}

							}.to_json
			holdings_hash
		end

		describe "request_item" do

			context "item status is available and loan type is regular or day" do

				before {
					@bc = BackendController.new
					@bc.stub(:get_patron_type => 'cornell')
					@bc.stub(:get_item_type   => 'regular')
					@bc.stub(:get_holdings    => holdings_json_helper)
				}

				it "returns L2L for service" do
					@bc._request_item(11234, 'mjc12')['service'].should eq('l2l')
				end

				it "returns the holdings ID for the available item" do
					pending
				end

				it "returns the location for the availble item" do
					pending
				end

			end

		end
			

	end
end