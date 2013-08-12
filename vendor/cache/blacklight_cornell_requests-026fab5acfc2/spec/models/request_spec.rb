require 'spec_helper'
require 'blacklight_cornell_requests/request'
require 'blacklight_cornell_requests/borrow_direct'
 
describe BlacklightCornellRequests::Request do

 	it "has a valid factory" do
 		FactoryGirl.create(:request).should be_valid
 	end

	it "is invalid without a bibid" do 
		FactoryGirl.build(:request, bibid: nil).should_not be_valid
	end

	it "has a valid initializer" do 
		request = BlacklightCornellRequests::Request.new(12345)
		FactoryGirl.build(:request, bibid: 12345).bibid.should == request.bibid 
	end

	context "Main request function" do
	  
	  let(:multivol_b) { { :multivol_b => 1 } }
    let(:multivol_c) { { :multivol_b => 0 } }
    let(:env_http_host) { 'http://localhost' }
    let(:request_controller) { BlacklightCornellRequests::RequestController.new() }

		it "returns the request options array, service, and Solr document" do
			req = FactoryGirl.build(:request, bibid: nil)
			req.magic_request nil, env_http_host
			
			req.request_options.class.name.should == "Array"
			req.service[:service].should == "ask"
			req.document.should == nil
		end

		# context "Patron is a guest" do
		# end

		context "Testing delivery_options functions" do

			let(:req) { FactoryGirl.build(:request, bibid: nil) }
			# before(:each) { 
				# req.stub(:get_cornell_delivery_options).and_return([{:service => 'ill', 'location' => 'Olin'}, {:service => 'l2l', 'location' => 'Library Annex'}])
				# req.stub(:get_guest_delivery_options).and_return([{:service => 'ask', 'location' => 'Mann'}])
			# }
			# This item is regular and charged
			# for cornell request, it should be bd
			# for guest request, it should be hold
			let(:item) {
			  {
          :href => "http://catalog-test.library.cornell.edu/vxws/record/3507363/items/5511982",
          :itemid => "5511982",
          :permLocation => "Olin Library",
          :location_id => "99",
          :tempLocation => "",
          :location => "Olin Library",
          :callNumber => "PR6068.O924 H36 1998",
          :copy => "c. 1",
          :itemBarcode => "31924086342510",
          :enumeration => "",
          :chron => "",
          :year => "",
          :caption => "",
          :freeText => "",
          :typeCode => "3",
          :typeDesc => "book",
          :tempType => "0",
          :itemStatus => "Charged - Due on 2013-06-05",
          :status => req.item_status("Charged - Due on 2013-06-05"),
          :spineLabel => "",
          :itemNote => "0",
          :onReserve => "N",
          :exclude_location_id => [181, 188]
        }
			}
			let(:bd_params) {
			  {
  			  :isbn => ['0747538492'],
          :title => 'Harry Potter and the chamber of secrets',
          :env_http_host => 'http://localhost'
			  }
			}

			it "should use get_cornell_delivery_options if patron is Cornell" do 
				req.netid = 'mjc12' 
				options = req.get_delivery_options(item, bd_params)
				options = req.sort_request_options options
				service = options[0][:service]
				req.populate_options service, options
				req.request_options[0][:service].should == BlacklightCornellRequests::Request::BD
			end

			it "should use get_guest_delivery_options if patron is guest" do 
				req.netid = 'gid-silterrae'
				options = req.get_delivery_options(item, bd_params)
        options = req.sort_request_options options
        service = options[0][:service]
        req.populate_options service, options
        req.request_options[0][:service].should == BlacklightCornellRequests::Request::HOLD
			end

			it "should use get_guest_delivery_options if patron is null" do 
				req.netid = ''
				options = req.get_delivery_options(item, bd_params)
        options = req.sort_request_options options
        service = options[0][:service]
        req.populate_options service, options
        req.request_options[0][:service].should == BlacklightCornellRequests::Request::HOLD
			end

			it "sorts the return array by delivery time" do
				req.netid = 'mjc12' 
				options = req.get_delivery_options(item, bd_params)
        options = req.sort_request_options options
        service = options[0][:service]
        req.populate_options service, options
        req.request_options[0][:service].should == BlacklightCornellRequests::Request::BD
			end

			# Next set of tests act on get_cornell_delivery_options
			context "Patron is Cornell-affiliated" do

				let(:r) { FactoryGirl.build(:request, bibid: nil) }
				before(:all) { r.netid = 'sk274' }

				context "Loan type is regular" do

					context "item status is 'not charged'" do

						before(:all) {
							@services = run_cornell_tests('regular', 'Not Charged', false)
						}

						it "suggests L2L for the service" do
							@services[0][:service].should == 'l2l'
						end

						it "sets request options to 'l2l" do
							b = Set.new ['l2l']
							@services.length.should == b.length
							@services.each do |o|
								b.should include(o[:service])
							end

						end

					end

					context "item status is 'charged'" do

						context "available through Borrow Direct" do

							before(:all) { 
								@services = run_cornell_tests('regular', 'Charged', true)
							}


							it "suggests BD for the service" do
								@services[0][:service].should == 'bd'
							end

							it "sets request options to 'bd, recall, ill, hold'" do
								b = Set.new ['bd', 'recall', 'ill', 'hold']
								@services.length.should == b.length
								@services.each do |o|
									b.should include(o[:service])
								end

							end

						end

						context "not available through Borrow Direct" do

							before(:all) { 
								@services = run_cornell_tests('regular', 'Charged', false)
							}


							it "suggests ILL for the service" do
								@services[0][:service].should == 'ill'
							end

							it "sets request options to 'ill, recall, hold'" do
								item = { 'typeCode' => 'regular', 
								   		 :status => 'Charged'
								 }
								options = r.get_delivery_options item
								b = Set.new ['recall', 'ill', 'hold']
								@services.length.should == b.length
								@services.each do |o|
									b.should include(o[:service])
								end
							end

						end

					end

					context "Item status is 'requested'" do

						context "available through Borrow Direct" do

							before(:all) { 
								@services = run_cornell_tests('regular', 'Requested', true)
							}


							it "suggests BD for the service" do
								@services[0][:service].should == 'bd'
							end

							it "sets request options to 'bd, recall, ill, hold'" do
								b = Set.new ['bd', 'recall', 'ill', 'hold']
								@services.length.should == b.length
								@services.each do |o|
									b.should include(o[:service])
								end

							end

						end

						context "not available through Borrow Direct" do

							before(:all) { 
								@services = run_cornell_tests('regular', 'Requested', false)
							}

							it "suggests ILL for the service" do
								@services[0][:service].should == 'ill'
							end

							it "sets request options to 'ill, recall, hold'" do
								b = Set.new ['recall', 'ill', 'hold']
								@services.length.should == b.length
								@services.each do |o|
									b.should include(o[:service])
								end
							end

						end

					end

					context "Item status is 'missing'" do

						context "available through Borrow Direct" do

							before(:all) { 
								@services = run_cornell_tests('regular', 'Missing', true)
							}

							it "suggests BD for the service" do
								@services[0][:service].should == 'bd'
							end

							it "sets request options to 'bd, purchase, ill'" do
								b = Set.new ['bd', 'purchase', 'ill']
								@services.length.should == b.length
								@services.each do |o|
									b.should include(o[:service])
								end

							end

						end

						context "not available through Borrow Direct" do

							before(:all) { 
								@services = run_cornell_tests('regular', 'Missing', false)
							}

							it "suggests purchase for the service" do
								@services[0][:service].should == 'purchase'
							end

							it "sets request options to 'ill, purchase'" do
								b = Set.new ['purchase', 'ill']
								@services.length.should == b.length
								@services.each do |o|
									b.should include(o[:service])
								end
							end

						end

					end

					context "Item status is 'lost'" do

						context "available through Borrow Direct" do

							before(:all) { 
								@services = run_cornell_tests('regular', 'Lost', true)
							}

							it "suggests BD for the service" do
								@services[0][:service].should == 'bd'
							end

							it "sets request options to 'bd, purchase, ill'" do
								b = Set.new ['bd', 'purchase', 'ill']
								@services.length.should == b.length
								@services.each do |o|
									b.should include(o[:service])
								end

							end

						end

						context "not available through Borrow Direct" do

							before(:all) { 
								@services = run_cornell_tests('regular', 'Lost', false)
							}

							it "suggests purchase for the service" do\
								@services[0][:service].should == 'purchase'
							end

							it "sets request options to 'ill, purchase'" do
								b = Set.new ['purchase', 'ill']
								@services.length.should == b.length
								@services.each do |o|
									b.should include(o[:service])
								end
							end

						end
					end

				end 

				context "Loan type is day" do

					context "item status is 'not charged'" do

						before(:all) { 
							r.stub(:borrowDirect_available?).and_return(true)
						}

						context "one- or two-day loan" do 

							# L2L is not available, so there should be no services listed
							it "has no request options" do
								options = run_cornell_tests('day', 'Not Charged', true, true)
								options.should == []
							end

						end

						context "three- or more-day loan" do

							before(:all) { 
								@options = run_cornell_tests('day', 'Not Charged', true)
										 }

							it "sets request options to 'L2L'" do
								b = Set.new ['l2l']
								@options.length.should == b.length
								@options.each do |o|
									b.should include(o[:service])
								end
							end

							it "suggests L2L for the service" do
								@options[0][:service].should == 'l2l'
							end

						end

					end

					context "item status is 'charged'" do

						context "available through Borrow Direct" do

							before(:all) { 
								@options = run_cornell_tests('day', 'Charged', true)
							}

							it "sets request options to 'BD, ILL, hold'" do
								b = Set.new ['bd', 'ill', 'hold']
								@options.length.should == b.length
								@options.each do |o|
									b.should include(o[:service])
								end
							end

							it "suggests BD for the service" do
								@options[0][:service].should == 'bd'
							end

						end

						context "not available through Borrow Direct" do

							before(:all) { 
								@options = run_cornell_tests('day', 'Charged', false)
							}

							it "sets request options to ILL, hold" do
								b = Set.new ['ill', 'hold']
								@options.length.should == b.length
								@options.each do |o|
									b.should include(o[:service])
								end
							end

							it "suggests ILL for the service" do
								@options[0][:service].should == 'ill'
							end

						end

					end

					context "item status is 'requested'" do

						context "available through Borrow Direct" do

							before(:all) { 
								@options = run_cornell_tests('day', 'Requested', true)
							}

							it "sets request options to 'BD, ILL, hold'" do
								b = Set.new ['bd', 'ill', 'hold']
								@options.length.should == b.length
								@options.each do |o|
									b.should include(o[:service])
								end
							end

							it "suggests BD for the service" do
								@options[0][:service].should == 'bd'
							end

						end

						context "not available through Borrow Direct" do

							before(:all) { 
								@options = run_cornell_tests('day', 'Requested', false)
							}


							it "sets request options to ILL, hold" do
								b = Set.new ['ill', 'hold']
								@options.length.should == b.length
								@options.each do |o|
									b.should include(o[:service])
								end
							end

							it "suggests ILL for the service" do
								@options[0][:service].should == 'ill'
							end

						end

					end

					context "item status is 'missing'" do
						pending
					end

					context "item status is 'lost'" do
						pending
					end

				end

				context "Loan type is minute" do

					context "item status is 'not charged'" do

						context "available through Borrow Direct" do

							before(:all) { 
								@options = run_cornell_tests('minute', 'Not Charged', true)
							}

							it "sets request options to 'BD, ask at circulation'" do
								b = Set.new ['bd', 'circ']
								@options.length.should == b.length
								@options.each do |o|
									b.should include(o[:service])
								end
							end

							it "suggests BD for the service" do
								@options[0][:service].should == 'bd'
							end

						end

						context "not available through Borrow Direct" do

							before(:all) { 
								@options = run_cornell_tests('minute', 'Not Charged', false)
							}

							it "sets request options to 'ask at circulation'" do
								b = Set.new ['circ']
								@options.length.should == b.length
								@options.each do |o|
									b.should include(o[:service])
								end
							end

							it "suggests ask at circ for the service" do
								@options[0][:service].should == 'circ'
							end

						end

					end

					context "item status is 'charged'" do

						context "available through Borrow Direct" do

							before(:all) { 
								@options = run_cornell_tests('minute', 'Charged', true)
							}

							it "sets request options to 'BD, ask at circulation'" do
								b = Set.new ['bd', 'circ']
								@options.length.should == b.length
								@options.each do |o|
									b.should include(o[:service])
								end
							end

							it "suggests BD for the service" do
								@options[0][:service].should == 'bd'
							end

						end

						context "not available through Borrow Direct" do

							before(:all) { 
								@options = run_cornell_tests('minute', 'Charged', false)
							}

							it "sets request options to 'ask at circulation'" do
								b = Set.new ['circ']
								@options.length.should == b.length
								@options.each do |o|
									b.should include(o[:service])
								end
							end

							it "suggests ask at circ for the service" do
								@options[0][:service].should == 'circ'
							end

						end

					end

					context "item status is 'requested'" do

						context "available through Borrow Direct" do

							before(:all) { 
								@options = run_cornell_tests('minute', 'Requested', true)

							}

							it "sets request options to 'BD, ask at circulation'" do
								b = Set.new ['bd', 'circ']
								@options.length.should == b.length
								@options.each do |o|
									b.should include(o[:service])
								end
							end

							it "suggests BD for the service" do
								@options[0][:service].should == 'bd'
							end

						end

						context "not available through Borrow Direct" do

							before(:all) { 
								@options = run_cornell_tests('minute', 'Requested', false)
							}

							it "sets request options to 'ask at circulation'" do
								b = Set.new ['circ']
								@options.length.should == b.length
								@options.each do |o|
									b.should include(o[:service])
								end
							end

							it "suggests ask at circ for the service" do
								@options[0][:service].should == 'circ'
							end

						end
					end

					context "item status is 'missing'" do
						pending
					end

					context "item status is 'lost'" do
						pending
					end

				end
				
				context "Loan type is nocirc" do
				  before(:all) {
				    @options = run_cornell_tests('nocirc', 'Not Charged', false)
				  }
				  it "sets best option as ill" do
  				  @options[0][:service].should == BlacklightCornellRequests::Request::ILL
  				end
				end

			 end

      context "Patron is a guest" do
      
        let(:request) {
          request = FactoryGirl.build(:request, bibid: nil)
          request.netid = 'gid-silterrae'
          request
        }
        
        context "Loan type is regular" do
          
          context "item status is 'not charged'" do
  
            let(:response) {
              req = run_tests(6370407, {}, 'regular', 'Not Charged', 'gid-silterrae')
              req.request_options[0][:service]
            }
  
            it "sets best option as 'l2l'" do
              response.should == BlacklightCornellRequests::Request::L2L
            end
  
          end
  
          context "item status is 'charged'" do
  
            let(:response) {
              req = run_tests(6370407, {}, 'regular', 'Charged', 'gid-silterrae')
              req.request_options[0][:service]
            }
            
            it "sets best option as 'hold'" do
              response.should == BlacklightCornellRequests::Request::HOLD
            end
            
          end
  
          context "Item status is 'requested'" do

            let(:response) {
              req = run_tests(6370407, {}, 'regular', 'Requested', 'gid-silterrae')
              req.request_options[0][:service]
            }
  
            it "sets best option as 'hold'" do
              response.should == BlacklightCornellRequests::Request::HOLD
            end
  
          end
          
          context "Item status is 'missing'" do
            
            let(:response) {
              req = run_tests(6370407, {}, 'regular', 'Missing', 'gid-silterrae')
              req.request_options.size
            }
  
            it "sets no best option" do
              response.should == 0
            end
            
          end
          
          context "Item status is 'lost'" do
            
            let(:response) {
              req = run_tests(6370407, {}, 'regular', 'Lost', 'gid-silterrae')
              req.request_options.size
            }
  
            it "sets no best option" do
              response.should == 0
            end
            
          end
          
        end
        
        context "Loan type is day" do
          
          context "item status is 'not charged'" do

            let(:response) {
              req = run_tests(6370407, {}, 'day', 'Not Charged', 'gid-silterrae')
              req.request_options[0][:service]
            }
  
            it "sets best option as 'l2l'" do
              response.should == BlacklightCornellRequests::Request::L2L
            end
  
          end
  
          context "item status is 'charged'" do

            let(:response) {
              req = run_tests(6370407, {}, 'day', 'Charged', 'gid-silterrae')
              req.request_options[0][:service]
            }
  
            it "sets best option as 'hold'" do
              response.should == BlacklightCornellRequests::Request::HOLD
            end
            
          end
  
          context "Item status is 'requested'" do
 
            let(:response) {
              req = run_tests(6370407, {}, 'day', 'Requested', 'gid-silterrae')
              req.request_options[0][:service]
            }
  
            it "sets best option as 'hold'" do
              response.should == BlacklightCornellRequests::Request::HOLD
            end
  
          end
          
          context "Item status is 'missing'" do
            
            let(:response) {
              req = run_tests(6370407, {}, 'day', 'Missing', 'gid-silterrae')
              req.request_options.size
            }
  
            it "sets no best option" do
              response.should == 0
            end
            
          end
          
          context "Item status is 'lost'" do
            
            let(:response) {
              req = run_tests(6370407, {}, 'day', 'Lost', 'gid-silterrae')
              req.request_options.size
            }
  
            it "sets no best option" do
              response.should == 0
            end
            
          end
          
        end
  
        context "Loan type is minute" do
          
          context "item status is 'not charged'" do
 
            let(:response) {
              req = run_tests(6370407, {}, 'minute', 'Not Charged', 'gid-silterrae')
              req.request_options[0][:service]
            }
  
            it "sets best option as 'circ'" do
              response.should == BlacklightCornellRequests::Request::ASK_CIRCULATION
            end
  
          end
  
          context "item status is 'charged'" do

            let(:response) {
              req = run_tests(6370407, {}, 'minute', 'Charged', 'gid-silterrae')
              req.request_options[0][:service]
            }
  
            it "sets best option as 'circ'" do
              response.should == BlacklightCornellRequests::Request::ASK_CIRCULATION
            end
            
          end
  
          ## no good example
          context "Item status is 'requested'" do
 
            let(:response) {
              req = run_tests(6370407, {}, 'minute', 'Requested', 'gid-silterrae')
              req.request_options[0][:service]
            }
  
            it "sets best option as 'circ'" do
              response.should == BlacklightCornellRequests::Request::ASK_CIRCULATION
            end
  
          end
          
          context "Item status is 'missing'" do

            let(:response) {
              req = run_tests(6370407, {}, 'minute', 'Missing', 'gid-silterrae')
              req.request_options.size
            }
  
            it "sets no best option" do
              response == 0
            end
            
          end
          
          ## don't have good example
          context "Item status is 'lost'" do
            
            let(:response) {
              req = run_tests(6370407, {}, 'minute', 'Lost', 'gid-silterrae')
              req.request_options.size
            }
  
            it "sets no best option" do
              response.should == 0
            end
            
          end
          
        end
        
        context "Loan type is nocirc" do
          
          let(:response) {
            req = run_tests(6370407, {}, 'nocirc', 'Not Charged', 'gid-silterrae')
            req.request_options.size
          }
  
          it "sets no best option" do
            response.should == 0
          end
            
        end
        
      end

		end

	end

	context "Working with holdings data" do

		context "retrieving holdings data for its bib id" do

			it "returns nil if no bibid is passed in" do
				request = FactoryGirl.build(:request, bibid: nil)
				result = request.get_holdings
				result.should == nil
			end

			it "returns nil for an invalid bibid" do
				request = FactoryGirl.build(:request, bibid: 500000000)
				VCR.use_cassette 'holdings/invalid_bibid' do
					result = request.get_holdings
					result[request.bibid.to_s]['condensed_holdings_full'].should == []
				end
			end

			it "returns a condensed holdings record if type = 'retrieve'" do
				request = FactoryGirl.build(:request, bibid: 6665264)
				VCR.use_cassette 'holdings/condensed' do
					result = request.get_holdings 'retrieve' 
					result[request.bibid.to_s]['condensed_holdings_full'].should_not == []
				end
			end

			it "returns a condensed holdings record if no type is specified" do
				request = FactoryGirl.build(:request, bibid: 6665264)
				VCR.use_cassette 'holdings/condensed' do
					result = request.get_holdings
					result[request.bibid.to_s]['condensed_holdings_full'].empty?.should_not == true
				end
			end

			it "returns a verbose holdings record if type = 'retrieve_detail_raw" do
				request = FactoryGirl.build(:request, bibid: 6665264)
				VCR.use_cassette 'holdings/detail_raw' do
					result = request.get_holdings 'retrieve_detail_raw' 
					result[request.bibid.to_s]['records'].empty?.should_not == true
				end
			end

		end

		context "retrieving item types" do

			describe "get_item_type" do

				let(:request) { FactoryGirl.create(:request) }
				let(:day_loan_types) {
					[1, 5, 6, 7, 8, 10, 11, 13, 14, 15, 17, 18, 19, 20, 21, 23, 24, 25, 28, 33]
				}
				let(:minute_loan_types) {
					[12, 16, 22, 26, 27, 29, 30, 31, 32, 34, 35, 36, 37]
				}
				let(:nocirc_loan_types) { [9] }

				it "returns 'day' for a day-type loan" do
					day_loan_types.each do |t|
						request.loan_type(t).should == 'day'
					end
				end

				it "returns 'minute' for a minute-type loan" do
					minute_loan_types.each do |t|
						request.loan_type(t).should == 'minute'
					end
				end

				it "returns 'nocirc' for a non-circulating item" do
					nocirc_loan_types.each do |t|
						request.loan_type(t).should == 'nocirc'
					end
				end

				it "returns 'regular' for a regular loan" do
					(1..37).each do |t|
						unless day_loan_types.include? t or minute_loan_types.include? t or nocirc_loan_types.include? t
							request.loan_type(t).should == 'regular'
						end
					end
				end

				it "returns 'regular' if the loan type isn't recognized" do # is this really what we want?
					request.loan_type(-100).should == 'regular'
				end

			end

		end

		context "Getting item status" do

			describe "get_item_status" do

				let(:rc) { FactoryGirl.create(:request) }

				it "returns 'Not Charged' if item status includes 'Not Charged'" do
					result = rc.item_status 'status is Not Charged in this case'
					result.should == 'Not Charged'
				end
				
				it "returns 'Not Charged' if item status includes 'Discharged'" do
          result = rc.item_status 'status is Discharged'
          result.should == 'Not Charged'
        end
        
        it "returns '' if item status includes 'Cataloging Review'" do
          result = rc.item_status 'status is Cataloging Review'
          result.should == 'Not Charged'
        end
        
        it "returns 'Not Charged' if item status includes 'Circulation Review'" do
          result = rc.item_status 'status is Circulation Review'
          result.should == 'Not Charged'
        end

				it "returns 'Charged' if item status includes 'Charged' but not 'Not Charged'" do
					result = rc.item_status 'status is Charged in this case'
					result.should == 'Charged'
				end

				it "returns 'Charged' if item status includes a left-anchored 'Charged'" do
					result = rc.item_status 'Charged in this case'
					result.should == 'Charged'
				end

				it "returns 'Charged' if item status includes 'Renewed'" do
					result = rc.item_status 'status is Renewed in this case'
					result.should == 'Charged'
				end

				it "returns 'Charged' if item status includes 'In transit to (anything then dot) .'" do
          result = rc.item_status 'status is In transit to 2000-01-01.'
          result.should == 'Charged'
        end
        
        it "returns 'Charged' if item status includes 'In transit to (anything but dot)'" do
          result = rc.item_status 'status is In transit to 2000-01-01'
          result.should == 'Not Charged'
        end
        
        it "returns 'Charged' if item status includes Hold''" do
          result = rc.item_status 'status is Hold'
          result.should == 'Charged'
        end
        
        it "returns 'Charged' if item status includes 'Overdue'" do
          result = rc.item_status 'status is Overdue'
          result.should == 'Charged'
        end
        
        it "returns 'Charged' if item status includes 'Recall'" do
          result = rc.item_status 'status is Recall'
          result.should == 'Charged'
        end
        
        it "returns 'Charged' if item status includes 'Claims'" do
          result = rc.item_status 'status is Claims'
          result.should == 'Charged'
        end
        
        it "returns 'Charged' if item status includes 'Damaged'" do
          result = rc.item_status 'status is Damaged'
          result.should == 'Charged'
        end
        
        it "returns 'Charged' if item status includes 'Withdrawn'" do
          result = rc.item_status 'status is Withdrawn'
          result.should == 'Charged'
        end
        
        it "returns 'Charged' if item status includes 'Call Slip Request'" do
          result = rc.item_status 'status is Call Slip Request'
          result.should == 'Charged'
        end
        
        it "returns 'Requested' if item status includes 'Requested'" do
          result = rc.item_status 'status is Requested in this case'
          result.should == 'Requested'
        end

        it "returns 'Missing' if item status includes 'Missing'" do
          result = rc.item_status 'status is Missing in this case'
          result.should == 'Missing'
        end

        it "returns 'Lost' if item status includes 'Lost'" do
          result = rc.item_status 'status is Lost in this case'
          result.should == 'Lost'
        end
        
        it "returns 'At Bindery' if item status includes 'At Bindery'" do
          result = rc.item_status 'status is At Bindery'
          result.should == 'At Bindery'
        end

				it "returns the passed parameter if the status isn't recognized" do
					result = rc.item_status 'status is Leaving on a Jet Plane in this case'
					result.should == 'status is Leaving on a Jet Plane in this case'
				end

			end
		end

		context "Getting delivery times" do

			let(:req) { FactoryGirl.create(:request) }

			describe "l2l" do 

				it "returns 1 if item is at the annex" do
					params = { :service => 'l2l', :location => 'Library Annex' }
					req.get_delivery_time('l2l', params).should == 1
				end

				it "returns 2 if item is not at annex" do
					params = { :service => 'l2l', :location => 'Maui' }
					req.get_delivery_time('l2l', params).should == 2
				end

			end

			describe 'bd' do 

				it "returns 6" do
					req.get_delivery_time('bd', nil).should == 6
				end

			end

			describe 'hold' do 

				it "returns 180 if there is no hold date" do
					params = { :service => 'hold', :itemStatus => 'Hold' }
					req.get_delivery_time('hold', params).should == 180
				end

				it "returns 180 if there is a hold date problem" do
					params = { :service => 'hold', :itemStatus => 'Hold -- Due on 1977-10-15' }
					req.get_delivery_time('hold', params).should == 180					
				end

				it "returns the remaining time till due date plus padding time for a valid hold date" do
					params = { :service => 'hold', :itemStatus => "Hold -- Due on #{Date.today + 10}" }
					req.get_delivery_time('hold', params).should == 10 + req.get_hold_padding						
				end

			end

			describe 'ill' do 

				it "returns 14" do
					req.get_delivery_time('ill', nil).should == 14
				end

			end

			describe 'recall' do 

				it "returns 30" do
					req.get_delivery_time('recall', nil).should == 30
				end

			end

			describe 'pda' do 

				it "returns 5" do
					req.get_delivery_time('pda', nil).should == 5
				end

			end

			describe 'purchase' do 

				it "returns 10" do
					req.get_delivery_time('purchase', nil).should == 10
				end

			end

			describe 'ask' do 

				it "returns 9999" do
					req.get_delivery_time('ask', nil).should == 9999
				end

			end

			describe 'circ' do 

				it "returns 9998" do
					req.get_delivery_time('circ', nil).should == 9998
				end

			end

			describe 'default' do 

				it "returns 9999 if it doesn't know what else to do" do
					req.get_delivery_time('help', nil).should == 9999
				end

			end

		end

	end

 end

 # Helper function to simplify tests of the main request logic
 # Returns the result of a call to get_delivery_options
 #
 # Parameters:
 # loan_type = regular|day|minute
 # status = Charged|Not Charged|Requested|Missing| etc..
 # bd = true|false (is item available in BD?)
 # short_day_loan = true|false (is this a one- or two-day loan - i.e., not eligible for L2L delivery?)
 def run_cornell_tests(loan_type, status, bd, short_day_loan = false)

	r = FactoryGirl.build(:request, bibid: nil) 
	r.stub(:borrowDirect_available?).and_return(bd)				
	r.netid = 'sk274' 

	case loan_type
		when 'regular'
			type_code =  3 # book
		when 'day'
			type_code = short_day_loan ? 10 : 11 # 10 = 1-day, 11 = 3-day
		when 'minute'
			type_code = 22 # 1-hour
	  when 'nocirc'
      type_code = 9 # no circulation
		else
	end

	return r.get_delivery_options({ :typeCode => type_code, :status => status })


 end

def run_tests(bibid, bd_params, loan_type, status, netid, short_day_loan = false)
  
  req = FactoryGirl.build(:request, bibid: bibid)
  
  case loan_type
    when 'regular'
      type_code =  3 # book
    when 'day'
      type_code = short_day_loan ? 10 : 11 # 10 = 1-day, 11 = 3-day
    when 'minute'
      type_code = 22 # 1-hour
    when 'nocirc'
      type_code = 9 # no circulation
    else
  end
  
  item = {
          :href => "http://catalog-test.library.cornell.edu/vxws/record/3507363/items/5511982",
          :itemid => "5511982",
          :permLocation => "Olin Library",
          :location_id => "99",
          :tempLocation => "",
          :location => "Olin Library",
          :callNumber => "PR6068.O924 H36 1998",
          :copy => "c. 1",
          :itemBarcode => "31924086342510",
          :enumeration => "",
          :chron => "",
          :year => "",
          :caption => "",
          :freeText => "",
          :typeCode => type_code,
          :typeDesc => "book",
          :tempType => "0",
          :itemStatus => status,
          :status => req.item_status(status),
          :spineLabel => "",
          :itemNote => "0",
          :onReserve => "N",
          :exclude_location_id => [181, 188]
        }
  req.netid = netid
  options = req.get_delivery_options(item, bd_params)
  options = req.sort_request_options options
  if options.size > 0
    service = options[0][:service]
  else
    service = ''
  end
  req.populate_options service, options

  return req

end
