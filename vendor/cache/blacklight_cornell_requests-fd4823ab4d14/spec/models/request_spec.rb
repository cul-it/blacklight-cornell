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

    context "Testing delivery_options functions", :delivery_options => true do

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
           "sensitize"=>"Y",
           "spine_label"=>"",
           "magnetic_media"=>"N",
           "recalls_placed"=>"0",
           "temp_location"=>"0",
           "historical_browses"=>"1",
           "item_enum"=>"v.10",
           "item_sequence_number"=>"10",
           "historical_charges"=>"0",
           "create_date"=>"2000-05-31 00:00:00.0",
           "copy_number"=>"1",
           "create_location_id"=>"0",
           "mfhd_id"=>"6058442",
           "short_loan_charges"=>"0",
           "chron"=>"1939",
           "reserve_charges"=>"0",
           "year"=>"",
           "modify_location_id"=>"100",
           "media_type_id"=>"0",
           "create_operator_id"=>"",
           "historical_bookings"=>"0",
           "holds_placed"=>"0",
           "perm_location"=>"99",
           "modify_date"=>"2006-12-21 20:25:35.0",
           "temp_item_type_id"=>"0",
           "caption"=>"",
           "on_reserve"=>"N",
           "pieces"=>"1",
           "item_type_id"=>"3",
           "price"=>"0",
           "item_type_name"=>"book",
           "item_id"=>"5511982",
           "freetext"=>"",
           "modify_operator_id"=>"es254",
           "status"=>2,
           "call_number"=>"PR6068.O924 H36 1998",
           "location"=>"Olin Library",
           "exclude_location_id"=>['181', '188']
        }.with_indifferent_access
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
        req.stub(:borrowDirect_available?).and_return(true)
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
        req.stub(:borrowDirect_available?).and_return(true)
        options = req.get_delivery_options(item, bd_params)
        options = req.sort_request_options options
        service = options[0][:service]
        req.populate_options service, options
        req.request_options[0][:service].should == BlacklightCornellRequests::Request::BD
      end

      # Next set of tests act on get_cornell_delivery_options
      context "Patron is Cornell-affiliated", :cornell => true do

        let(:r) {
          request = FactoryGirl.build(:request, bibid: nil)
          request.netid = 'sk274'
          request
        }
        
        context "Item is PDA eligible" do
          it "sets request options to 'pda", :cornell_pda => true do
            document = {
              :id => '8047524',
              :url_pda_display => ['http://pda.library.cornell.edu/coutts/pod.cgi?CouttsID=cou21231016|Click to ask Cornell University Library to RUSH purchase. We will contact you by email when it arrives (typically within a week).'],
              :isbn_display => ['1118083393 (pbk.)'],
              :title_display => 'The organic chem lab survival manual'
            }.with_indifferent_access
            r.bibid = 8047524
            r.magic_request document, 'http://localhost'
            expect(r.service).to be BlacklightCornellRequests::Request::PDA
          end
        end
        
        context "Item is available for document delivery", :cornell_document_delivery => true do
          it "lists document delivery as alternate option" do
            document = {
              :id => '5747274',
              :format => ['Journal'],
              :title_display => '1 world manga',
              :multivol_b => 'true'
            }.with_indifferent_access
            r.bibid = 5747274
            r.magic_request document, 'http://localhost'
            # expect({:service=>"document_delivery", :iid=> {:itemid=>"document_delivery", :url=> "https://cornell.hosts.atlas-sys.com/illiad/illiad.dll?Action=10&Form=22"}, :estimate=>2}).to include(:service=>"document_delivery")
            # puts r.alternate_options.inspect + "\n"
            expect(r.alternate_options[0]).to include(:service=>BlacklightCornellRequests::Request::DOCUMENT_DELIVERY)
          end
        end

        context "Loan type is regular", :cornell_regular => true do

          context "item status is 'not charged'" do

            before(:all) {
              @services = run_cornell_tests('regular', BlacklightCornellRequests::Request::NOT_CHARGED, false)
            }

            it "suggests L2L for the service" do
              @services[0][:service].should == BlacklightCornellRequests::Request::L2L
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
                @services = run_cornell_tests('regular', BlacklightCornellRequests::Request::CHARGED, true)
              }


              it "suggests BD for the service" do
                @services[0][:service].should == BlacklightCornellRequests::Request::BD
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
                @services = run_cornell_tests('regular', BlacklightCornellRequests::Request::CHARGED, false)
              }


              it "suggests ILL for the service" do
                @services[0][:service].should == BlacklightCornellRequests::Request::ILL
              end

              it "sets request options to 'ill, recall, hold'" do
                item = { 'typeCode' => 'regular', 
                        :status => BlacklightCornellRequests::Request::CHARGED
                 }
                options = r.get_delivery_options item
                b = Set.new [BlacklightCornellRequests::Request::RECALL, BlacklightCornellRequests::Request::ILL, BlacklightCornellRequests::Request::HOLD]
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
                @services = run_cornell_tests('regular', BlacklightCornellRequests::Request::REQUESTED, true)
              }


              it "suggests BD for the service" do
                @services[0][:service].should == 'bd'
              end

              it "sets request options to 'bd, recall, ill, hold'" do
                b = Set.new [BlacklightCornellRequests::Request::BD, BlacklightCornellRequests::Request::RECALL, BlacklightCornellRequests::Request::ILL, BlacklightCornellRequests::Request::HOLD]
                @services.length.should == b.length
                @services.each do |o|
                  b.should include(o[:service])
                end

              end

            end

            context "not available through Borrow Direct" do

              before(:all) { 
                @services = run_cornell_tests('regular', BlacklightCornellRequests::Request::REQUESTED, false)
              }

              it "suggests ILL for the service" do
                @services[0][:service].should == BlacklightCornellRequests::Request::ILL
              end

              it "sets request options to 'ill, recall, hold'" do
                b = Set.new [BlacklightCornellRequests::Request::RECALL, BlacklightCornellRequests::Request::ILL, BlacklightCornellRequests::Request::HOLD]
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
                @services = run_cornell_tests('regular', BlacklightCornellRequests::Request::MISSING, true)
              }

              it "suggests BD for the service" do
                @services[0][:service].should == BlacklightCornellRequests::Request::BD
              end

              it "sets request options to 'bd, purchase, ill'" do
                b = Set.new [BlacklightCornellRequests::Request::BD, BlacklightCornellRequests::Request::PURCHASE, BlacklightCornellRequests::Request::ILL]
                @services.length.should == b.length
                @services.each do |o|
                  b.should include(o[:service])
                end

              end

            end

            context "not available through Borrow Direct" do

              before(:all) { 
                @services = run_cornell_tests('regular', BlacklightCornellRequests::Request::MISSING, false)
              }

              it "suggests purchase for the service" do
                @services[0][:service].should == BlacklightCornellRequests::Request::PURCHASE
              end

              it "sets request options to 'ill, purchase'" do
                b = Set.new [BlacklightCornellRequests::Request::PURCHASE, BlacklightCornellRequests::Request::ILL]
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
                @services = run_cornell_tests('regular', BlacklightCornellRequests::Request::LOST, true)
              }

              it "suggests BD for the service" do
                @services[0][:service].should == 'bd'
              end

              it "sets request options to 'bd, purchase, ill'" do
                b = Set.new [BlacklightCornellRequests::Request::BD, BlacklightCornellRequests::Request::PURCHASE, BlacklightCornellRequests::Request::ILL]
                @services.length.should == b.length
                @services.each do |o|
                  b.should include(o[:service])
                end

              end

            end

            context "not available through Borrow Direct" do

              before(:all) { 
                @services = run_cornell_tests('regular', BlacklightCornellRequests::Request::LOST, false)
              }

              it "suggests purchase for the service" do
                @services[0][:service].should == BlacklightCornellRequests::Request::PURCHASE
              end

              it "sets request options to 'ill, purchase'" do
                b = Set.new [BlacklightCornellRequests::Request::PURCHASE, BlacklightCornellRequests::Request::ILL]
                @services.length.should == b.length
                @services.each do |o|
                  b.should include(o[:service])
                end
              end

            end
          end

        end 

        context "Loan type is day", :cornell_day => true do

          context "item status is 'not charged'" do

            before(:all) { 
              r.stub(:borrowDirect_available?).and_return(true)
            }

            context "one- or two-day loan" do 

              # L2L is not available, so there should be no services listed
              it "has no request options" do
                options = run_cornell_tests('day', BlacklightCornellRequests::Request::NOT_CHARGED, true, true)
                options.should == []
              end

            end

            context "three- or more-day loan" do

              before(:all) { 
                @options = run_cornell_tests('day', BlacklightCornellRequests::Request::NOT_CHARGED, true)
                     }

              it "sets request options to 'L2L'" do
                b = Set.new [BlacklightCornellRequests::Request::L2L]
                @options.length.should == b.length
                @options.each do |o|
                  b.should include(o[:service])
                end
              end

              it "suggests L2L for the service" do
                @options[0][:service].should == BlacklightCornellRequests::Request::L2L
              end

            end

          end

          context "item status is 'charged'" do

            context "available through Borrow Direct" do

              before(:all) { 
                @options = run_cornell_tests('day', BlacklightCornellRequests::Request::CHARGED, true)
              }

              it "sets request options to 'BD, ILL, hold'" do
                b = Set.new [BlacklightCornellRequests::Request::BD, BlacklightCornellRequests::Request::ILL, BlacklightCornellRequests::Request::HOLD]
                @options.length.should == b.length
                @options.each do |o|
                  b.should include(o[:service])
                end
              end

              it "suggests BD for the service" do
                @options[0][:service].should == BlacklightCornellRequests::Request::BD
              end

            end

            context "not available through Borrow Direct" do

              before(:all) { 
                @options = run_cornell_tests('day', BlacklightCornellRequests::Request::CHARGED, false)
              }

              it "sets request options to ILL, hold" do
                b = Set.new [BlacklightCornellRequests::Request::ILL, BlacklightCornellRequests::Request::HOLD]
                @options.length.should == b.length
                @options.each do |o|
                  b.should include(o[:service])
                end
              end

              it "suggests ILL for the service" do
                @options[0][:service].should == BlacklightCornellRequests::Request::ILL
              end

            end

          end

          context "item status is 'requested'" do

            context "available through Borrow Direct" do

              before(:all) { 
                @options = run_cornell_tests('day', BlacklightCornellRequests::Request::REQUESTED, true)
              }

              it "sets request options to 'BD, ILL, hold'" do
                b = Set.new [BlacklightCornellRequests::Request::BD, BlacklightCornellRequests::Request::ILL, BlacklightCornellRequests::Request::HOLD]
                @options.length.should == b.length
                @options.each do |o|
                  b.should include(o[:service])
                end
              end

              it "suggests BD for the service" do
                @options[0][:service].should == BlacklightCornellRequests::Request::BD
              end

            end

            context "not available through Borrow Direct" do

              before(:all) { 
                @options = run_cornell_tests('day', BlacklightCornellRequests::Request::REQUESTED, false)
              }


              it "sets request options to ILL, hold" do
                b = Set.new [BlacklightCornellRequests::Request::ILL, BlacklightCornellRequests::Request::HOLD]
                @options.length.should == b.length
                @options.each do |o|
                  b.should include(o[:service])
                end
              end

              it "suggests ILL for the service" do
                @options[0][:service].should == BlacklightCornellRequests::Request::ILL
              end

            end

          end

          context "item status is 'missing'" do

            context "available through Borrow Direct" do

              before(:all) { 
                @services = run_cornell_tests('day', BlacklightCornellRequests::Request::MISSING, true)
              }

              it "suggests BD for the service" do
                @services[0][:service].should == BlacklightCornellRequests::Request::BD
              end

              it "sets request options to 'bd, purchase, ill'" do
                b = Set.new [BlacklightCornellRequests::Request::BD, BlacklightCornellRequests::Request::PURCHASE, BlacklightCornellRequests::Request::ILL]
                @services.length.should == b.length
                @services.each do |o|
                  b.should include(o[:service])
                end

              end

            end

            context "not available through Borrow Direct" do

              before(:all) { 
                @services = run_cornell_tests('day', BlacklightCornellRequests::Request::MISSING, false)
              }

              it "suggests purchase for the service" do
                @services[0][:service].should == BlacklightCornellRequests::Request::PURCHASE
              end

              it "sets request options to 'ill, purchase'" do
                b = Set.new [BlacklightCornellRequests::Request::PURCHASE, BlacklightCornellRequests::Request::ILL]
                @services.length.should == b.length
                @services.each do |o|
                  b.should include(o[:service])
                end
              end

            end

          end

          context "item status is 'lost'" do

            context "available through Borrow Direct" do

              before(:all) { 
                @services = run_cornell_tests('day', BlacklightCornellRequests::Request::LOST, true)
              }

              it "suggests BD for the service" do
                @services[0][:service].should == BlacklightCornellRequests::Request::BD
              end

              it "sets request options to 'bd, purchase, ill'" do
                b = Set.new [BlacklightCornellRequests::Request::BD, BlacklightCornellRequests::Request::PURCHASE, BlacklightCornellRequests::Request::ILL]
                @services.length.should == b.length
                @services.each do |o|
                  b.should include(o[:service])
                end

              end

            end

            context "not available through Borrow Direct" do

              before(:all) { 
                @services = run_cornell_tests('day', BlacklightCornellRequests::Request::LOST, false)
              }

              it "suggests purchase for the service" do
                @services[0][:service].should == BlacklightCornellRequests::Request::PURCHASE
              end

              it "sets request options to 'ill, purchase'" do
                b = Set.new [BlacklightCornellRequests::Request::PURCHASE, BlacklightCornellRequests::Request::ILL]
                @services.length.should == b.length
                @services.each do |o|
                  b.should include(o[:service])
                end
              end

            end
          end

        end

        context "Loan type is minute", :cornell_minute => true do

          context "item status is 'not charged'" do

            context "available through Borrow Direct" do

              before(:all) { 
                @options = run_cornell_tests('minute', BlacklightCornellRequests::Request::NOT_CHARGED, true)
              }

              it "sets request options to 'BD, ask at circulation'" do
                b = Set.new [BlacklightCornellRequests::Request::BD, BlacklightCornellRequests::Request::ASK_CIRCULATION]
                @options.length.should == b.length
                @options.each do |o|
                  b.should include(o[:service])
                end
              end

              it "suggests BD for the service" do
                @options[0][:service].should == BlacklightCornellRequests::Request::BD
              end

            end

            context "not available through Borrow Direct" do

              before(:all) { 
                @options = run_cornell_tests('minute', BlacklightCornellRequests::Request::NOT_CHARGED, false)
              }

              it "sets request options to 'ask at circulation'" do
                b = Set.new [BlacklightCornellRequests::Request::ASK_CIRCULATION]
                @options.length.should == b.length
                @options.each do |o|
                  b.should include(o[:service])
                end
              end

              it "suggests ask at circ for the service" do
                @options[0][:service].should == BlacklightCornellRequests::Request::ASK_CIRCULATION
              end

            end

          end

          context "item status is 'charged'" do

            context "available through Borrow Direct" do

              before(:all) { 
                @options = run_cornell_tests('minute', BlacklightCornellRequests::Request::CHARGED, true)
              }

              it "sets request options to 'BD, ask at circulation'" do
                b = Set.new [BlacklightCornellRequests::Request::BD, BlacklightCornellRequests::Request::ASK_CIRCULATION]
                @options.length.should == b.length
                @options.each do |o|
                  b.should include(o[:service])
                end
              end

              it "suggests BD for the service" do
                @options[0][:service].should == BlacklightCornellRequests::Request::BD
              end

            end

            context "not available through Borrow Direct" do

              before(:all) { 
                @options = run_cornell_tests('minute', BlacklightCornellRequests::Request::CHARGED, false)
              }

              it "sets request options to 'ask at circulation'" do
                b = Set.new [BlacklightCornellRequests::Request::ASK_CIRCULATION]
                @options.length.should == b.length
                @options.each do |o|
                  b.should include(o[:service])
                end
              end

              it "suggests ask at circ for the service" do
                @options[0][:service].should == BlacklightCornellRequests::Request::ASK_CIRCULATION
              end

            end

          end

          context "item status is 'requested'" do

            context "available through Borrow Direct" do

              before(:all) { 
                @options = run_cornell_tests('minute', BlacklightCornellRequests::Request::REQUESTED, true)

              }

              it "sets request options to 'BD, ask at circulation'" do
                b = Set.new [BlacklightCornellRequests::Request::BD, BlacklightCornellRequests::Request::ASK_CIRCULATION]
                @options.length.should == b.length
                @options.each do |o|
                  b.should include(o[:service])
                end
              end

              it "suggests BD for the service" do
                @options[0][:service].should == BlacklightCornellRequests::Request::BD
              end

            end

            context "not available through Borrow Direct" do

              before(:all) { 
                @options = run_cornell_tests('minute', BlacklightCornellRequests::Request::REQUESTED, false)
              }

              it "sets request options to 'ask at circulation'" do
                b = Set.new [BlacklightCornellRequests::Request::ASK_CIRCULATION]
                @options.length.should == b.length
                @options.each do |o|
                  b.should include(o[:service])
                end
              end

              it "suggests ask at circ for the service" do
                @options[0][:service].should == BlacklightCornellRequests::Request::ASK_CIRCULATION
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
        
        context "Loan type is nocirc", :cornell_nocirc => true do
          before(:all) {
            @options = run_cornell_tests('nocirc', BlacklightCornellRequests::Request::NOT_CHARGED, false)
          }
          it "sets best option as ill" do
            @options[0][:service].should == BlacklightCornellRequests::Request::ILL
          end
        end

       end

      context "Patron is a guest", :guest => true do
      
        let(:request) {
          request = FactoryGirl.build(:request, bibid: nil)
          request.netid = 'gid-silterrae'
          request
        }
        
        context "Loan type is regular", :guest_regular => true do
          
          context "item status is 'not charged'" do
  
            let(:response) {
              req = run_tests(6370407, {}, 'regular', BlacklightCornellRequests::Request::NOT_CHARGED, 'gid-silterrae')
              req.request_options[0][:service]
            }
  
            it "sets best option as 'l2l'" do
              response.should == BlacklightCornellRequests::Request::L2L
            end
  
          end
  
          context "item status is 'charged'" do
  
            let(:response) {
              req = run_tests(6370407, {}, 'regular', BlacklightCornellRequests::Request::CHARGED, 'gid-silterrae')
              req.request_options[0][:service]
            }
            
            it "sets best option as 'hold'" do
              response.should == BlacklightCornellRequests::Request::HOLD
            end
            
          end
  
          context "Item status is 'requested'" do

            let(:response) {
              req = run_tests(6370407, {}, 'regular', BlacklightCornellRequests::Request::REQUESTED, 'gid-silterrae')
              req.request_options[0][:service]
            }
  
            it "sets best option as 'hold'" do
              response.should == BlacklightCornellRequests::Request::HOLD
            end
  
          end
          
          context "Item status is 'missing'" do
            
            let(:response) {
              req = run_tests(6370407, {}, 'regular', BlacklightCornellRequests::Request::MISSING, 'gid-silterrae')
              req.request_options.size
            }
  
            it "sets no best option" do
              response.should == 0
            end
            
          end
          
          context "Item status is 'lost'" do
            
            let(:response) {
              req = run_tests(6370407, {}, 'regular', BlacklightCornellRequests::Request::LOST, 'gid-silterrae')
              req.request_options.size
            }
  
            it "sets no best option" do
              response.should == 0
            end
            
          end
          
        end
        
        context "Loan type is day", :guest_day => true do
          
          context "item status is 'not charged'" do

            let(:response) {
              req = run_tests(6370407, {}, 'day', BlacklightCornellRequests::Request::NOT_CHARGED, 'gid-silterrae')
              req.request_options[0][:service]
            }
  
            it "sets best option as 'l2l'" do
              response.should == BlacklightCornellRequests::Request::L2L
            end
  
          end
  
          context "item status is 'charged'" do

            let(:response) {
              req = run_tests(6370407, {}, 'day', BlacklightCornellRequests::Request::CHARGED, 'gid-silterrae')
              req.request_options[0][:service]
            }
  
            it "sets best option as 'hold'" do
              response.should == BlacklightCornellRequests::Request::HOLD
            end
            
          end
  
          context "Item status is 'requested'" do
 
            let(:response) {
              req = run_tests(6370407, {}, 'day', BlacklightCornellRequests::Request::REQUESTED, 'gid-silterrae')
              req.request_options[0][:service]
            }
  
            it "sets best option as 'hold'" do
              response.should == BlacklightCornellRequests::Request::HOLD
            end
  
          end
          
          context "Item status is 'missing'" do
            
            let(:response) {
              req = run_tests(6370407, {}, 'day', BlacklightCornellRequests::Request::MISSING, 'gid-silterrae')
              req.request_options.size
            }
  
            it "sets no best option" do
              response.should == 0
            end
            
          end
          
          context "Item status is 'lost'" do
            
            let(:response) {
              req = run_tests(6370407, {}, 'day', BlacklightCornellRequests::Request::LOST, 'gid-silterrae')
              req.request_options.size
            }
  
            it "sets no best option" do
              response.should == 0
            end
            
          end
          
        end
  
        context "Loan type is minute", :guest_minute => true do
          
          context "item status is 'not charged'" do
 
            let(:response) {
              req = run_tests(6370407, {}, 'minute', BlacklightCornellRequests::Request::NOT_CHARGED, 'gid-silterrae')
              req.request_options[0][:service]
            }
  
            it "sets best option as 'circ'" do
              response.should == BlacklightCornellRequests::Request::ASK_CIRCULATION
            end
  
          end
  
          context "item status is 'charged'" do

            let(:response) {
              req = run_tests(6370407, {}, 'minute', BlacklightCornellRequests::Request::CHARGED, 'gid-silterrae')
              req.request_options[0][:service]
            }
  
            it "sets best option as 'circ'" do
              response.should == BlacklightCornellRequests::Request::ASK_CIRCULATION
            end
            
          end
  
          ## no good example
          context "Item status is 'requested'" do
 
            let(:response) {
              req = run_tests(6370407, {}, 'minute', BlacklightCornellRequests::Request::REQUESTED, 'gid-silterrae')
              req.request_options[0][:service]
            }
  
            it "sets best option as 'circ'" do
              response.should == BlacklightCornellRequests::Request::ASK_CIRCULATION
            end
  
          end
          
          context "Item status is 'missing'" do

            let(:response) {
              req = run_tests(6370407, {}, 'minute', BlacklightCornellRequests::Request::MISSING, 'gid-silterrae')
              req.request_options.size
            }
  
            it "sets no best option" do
              response == 0
            end
            
          end
          
          ## don't have good example
          context "Item status is 'lost'" do
            
            let(:response) {
              req = run_tests(6370407, {}, 'minute', BlacklightCornellRequests::Request::LOST, 'gid-silterrae')
              req.request_options.size
            }
  
            it "sets no best option" do
              response.should == 0
            end
            
          end
          
        end
        
        context "Loan type is nocirc", :guest_nocirc => true do
          
          let(:response) {
            req = run_tests(6370407, {}, 'nocirc', BlacklightCornellRequests::Request::NOT_CHARGED, 'gid-silterrae')
            req.request_options.size
          }
  
          it "sets no best option" do
            response.should == 0
          end
            
        end
        
      end

    end

    context "Testing volume sort logic", :volume_sort => true do
      let(:sorted_volumes) {
        req = FactoryGirl.build(:request, bibid: nil)
        items =
        [
          {
            "href"=>"http://catalog-test.library.cornell.edu/vxws/record/307808/items/641023",
            "itemid"=>"641023", "item_enum"=>"v.46:no.17-20", "chron"=>"1990", "year"=>""
          }.with_indifferent_access,
          {
            "href"=>"http://catalog-test.library.cornell.edu/vxws/record/307808/items/641019",
            "itemid"=>"641019", "item_enum"=>"v.46:no.1-4", "chron"=>"1990", "year"=>""
          }.with_indifferent_access,
          {
            "href"=>"http://catalog-test.library.cornell.edu/vxws/record/307808/items/641021",
            "itemid"=>"641021", "item_enum"=>"v.46:no.7-8", "chron"=>"1990", "year"=>""
          }.with_indifferent_access,
          {
            "href"=>"http://catalog-test.library.cornell.edu/vxws/record/307808/items/641022",
            "itemid"=>"641022", "item_enum"=>"v.46:no.13/14-16", "chron"=>"1990", "year"=>""
          }.with_indifferent_access,
          {
            "href"=>"http://catalog-test.library.cornell.edu/vxws/record/307808/items/641020",
            "itemid"=>"641020", "item_enum"=>"v.46:no.5-6", "chron"=>"1990", "year"=>""
          }.with_indifferent_access,
          {
            "href"=>"http://catalog-test.library.cornell.edu/vxws/record/307808/items/641023",
            "itemid"=>"641023", "item_enum"=>"v.46:no.9-12", "chron"=>"1990", "year"=>""
          }.with_indifferent_access,
          {
            "href"=>"http://catalog-test.library.cornell.edu/vxws/record/307808/items/641023",
            "itemid"=>"641023", "item_enum"=>"v.46:no.21-24", "chron"=>"1990", "year"=>""
          }.with_indifferent_access,
          {
            "href"=>"http://catalog-test.library.cornell.edu/vxws/record/307808/items/641023",
            "itemid"=>"641023", "item_enum"=>"v.24", "chron"=>"1968:Dec.", "year"=>""
          }.with_indifferent_access,
          {
            "href"=>"http://catalog-test.library.cornell.edu/vxws/record/307808/items/641023",
            "itemid"=>"641023", "item_enum"=>"v.24", "chron"=>"1968:Feb.", "year"=>""
          }.with_indifferent_access,
          {
            "href"=>"http://catalog-test.library.cornell.edu/vxws/record/307808/items/641023",
            "itemid"=>"641023", "item_enum"=>"v.24", "chron"=>"1968:Apr.", "year"=>""
          }.with_indifferent_access,
          {
            "href"=>"http://catalog-test.library.cornell.edu/vxws/record/307808/items/641023",
            "itemid"=>"641023", "item_enum"=>"v.24", "chron"=>"1968:Jan.", "year"=>""
          }.with_indifferent_access,
          {
            "href"=>"http://catalog-test.library.cornell.edu/vxws/record/307808/items/641023",
            "itemid"=>"641023", "item_enum"=>"v.24", "chron"=>"1968:June", "year"=>""
          }.with_indifferent_access,
          {
            "href"=>"http://catalog-test.library.cornell.edu/vxws/record/307808/items/641023",
            "itemid"=>"641023", "item_enum"=>"v.24", "chron"=>"1968:May", "year"=>""
          }.with_indifferent_access,
          {
            "href"=>"http://catalog-test.library.cornell.edu/vxws/record/307808/items/641023",
            "itemid"=>"641023", "item_enum"=>"v.24", "chron"=>"1968:July", "year"=>""
          }.with_indifferent_access,
          {
            "href"=>"http://catalog-test.library.cornell.edu/vxws/record/307808/items/641023",
            "itemid"=>"641023", "item_enum"=>"v.24", "chron"=>"1968:Aug.", "year"=>""
          }.with_indifferent_access,
          {
            "href"=>"http://catalog-test.library.cornell.edu/vxws/record/307808/items/641023",
            "itemid"=>"641023", "item_enum"=>"v.24", "chron"=>"1968:Oct.", "year"=>""
          }.with_indifferent_access,
          {
            "href"=>"http://catalog-test.library.cornell.edu/vxws/record/307808/items/641023",
            "itemid"=>"641023", "item_enum"=>"v.24", "chron"=>"1968:Mar.", "year"=>""
          }.with_indifferent_access,
          {
            "href"=>"http://catalog-test.library.cornell.edu/vxws/record/307808/items/641023",
            "itemid"=>"641023", "item_enum"=>"v.24", "chron"=>"1968:Sept.", "year"=>""
          }.with_indifferent_access,
          {
            "href"=>"http://catalog-test.library.cornell.edu/vxws/record/307808/items/641023",
            "itemid"=>"641023", "item_enum"=>"v.24", "chron"=>"1968:Nov.", "year"=>""
          }.with_indifferent_access
        ]
        req.set_volumes(items)
        req.volumes.keys
        Hash[req.volumes.keys.map.with_index.to_a]
      }
      
      it "should sort 'v.24 - 1968:Jan.' before 'v.24 - 1968:Feb.'" do
        expect(sorted_volumes['v.24 - 1968:Jan.']).to be < sorted_volumes['v.24 - 1968:Feb.']
      end
      
      it "should sort 'v.24 - 1968:Feb.' before 'v.24 - 1968:Mar.'" do
        expect(sorted_volumes['v.24 - 1968:Feb.']).to be < sorted_volumes['v.24 - 1968:Mar.']
      end
      
      it "should sort 'v.24 - 1968:Mar.' before 'v.24 - 1968:Apr.'" do
        expect(sorted_volumes['v.24 - 1968:Mar.']).to be < sorted_volumes['v.24 - 1968:Apr.']
      end
      
      it "should sort 'v.24 - 1968:Apr.' before 'v.24 - 1968:May'" do
        expect(sorted_volumes['v.24 - 1968:Apr.']).to be < sorted_volumes['v.24 - 1968:May']
      end
      
      it "should sort 'v.24 - 1968:May' before 'v.24 - 1968:June'" do
        expect(sorted_volumes['v.24 - 1968:May']).to be < sorted_volumes['v.24 - 1968:June']
      end
      
      it "should sort 'v.24 - 1968:June' before 'v.24 - 1968:July'" do
        expect(sorted_volumes['v.24 - 1968:June']).to be < sorted_volumes['v.24 - 1968:July']
      end
      
      it "should sort 'v.24 - 1968:July' before 'v.24 - 1968:Aug.'" do
        expect(sorted_volumes['v.24 - 1968:July']).to be < sorted_volumes['v.24 - 1968:Aug.']
      end
      
      it "should sort 'v.24 - 1968:Aug.' before 'v.24 - 1968:Sept.'" do
        expect(sorted_volumes['v.24 - 1968:Aug.']).to be < sorted_volumes['v.24 - 1968:Sept.']
      end
      
      it "should sort 'v.24 - 1968:Sept.' before 'v.24 - 1968:Oct.'" do
        expect(sorted_volumes['v.24 - 1968:Sept.']).to be < sorted_volumes['v.24 - 1968:Oct.']
      end
      
      it "should sort 'v.24 - 1968:Oct.' before 'v.24 - 1968:Nov.'" do
        expect(sorted_volumes['v.24 - 1968:Oct.']).to be < sorted_volumes['v.24 - 1968:Nov.']
      end
      
      it "should sort 'v.24 - 1968:Nov.' before 'v.24 - 1968:Dec.'" do
        expect(sorted_volumes['v.24 - 1968:Nov.']).to be < sorted_volumes['v.24 - 1968:Dec.']
      end
      
      it "should sort 'v.46:no.9-12 - 1990' before 'v.46:no.13/14-16 - 1990'" do
        expect(sorted_volumes['v.46:no.9-12 - 1990']).to be < sorted_volumes['v.46:no.13/14-16 - 1990']
      end
      
      it "should sort 'v.24 - 1968:Jan.' before 'v.46:no.1-4 - 1990'" do
        expect(sorted_volumes['v.24 - 1968:Jan.']).to be < sorted_volumes['v.46:no.1-4 - 1990']
      end
      
    end

  end

  context "Working with holdings data", :holdings_data => true do
    
    let(:document) {
      {
        :item_id=>1,
        :item_record_display=>["{\"sensitize\":\"Y\",\"spine_label\":\"\",\"magnetic_media\":\"N\",\"recalls_placed\":\"0\",\"temp_location\":\"0\",\"historical_browses\":\"51\",\"item_enum\":\"\",\"item_sequence_number\":\"1\",\"historical_charges\":\"118\",\"create_date\":\"2000-05-31 00:00:00.0\",\"copy_number\":\"1\",\"create_location_id\":\"0\",\"mfhd_id\":\"3614020\",\"short_loan_charges\":\"0\",\"chron\":\"\",\"reserve_charges\":\"0\",\"year\":\"\",\"modify_location_id\":\"183\",\"media_type_id\":\"0\",\"create_operator_id\":\"\",\"historical_bookings\":\"0\",\"holds_placed\":\"0\",\"perm_location\":\"99\",\"modify_date\":\"2001-01-25 07:25:13.0\",\"temp_item_type_id\":\"0\",\"caption\":\"\",\"on_reserve\":\"N\",\"pieces\":\"1\",\"item_type_id\":\"3\",\"price\":\"0\",\"item_type_name\":\"book\",\"item_id\":\"5060937\",\"freetext\":\"\",\"modify_operator_id\":\"ks21\"}", "{\"sensitize\":\"Y\",\"spine_label\":\"\",\"magnetic_media\":\"N\",\"recalls_placed\":\"0\",\"temp_location\":\"0\",\"historical_browses\":\"46\",\"item_enum\":\"\",\"item_sequence_number\":\"0\",\"historical_charges\":\"110\",\"create_date\":\"2000-07-27 16:02:41.0\",\"copy_number\":\"2\",\"create_location_id\":\"153\",\"mfhd_id\":\"4422673\",\"short_loan_charges\":\"0\",\"chron\":\"\",\"reserve_charges\":\"0\",\"year\":\"\",\"modify_location_id\":\"183\",\"media_type_id\":\"0\",\"create_operator_id\":\"ja14\",\"historical_bookings\":\"0\",\"holds_placed\":\"0\",\"perm_location\":\"99\",\"modify_date\":\"2001-07-09 13:22:10.0\",\"temp_item_type_id\":\"0\",\"caption\":\"\",\"on_reserve\":\"N\",\"pieces\":\"1\",\"item_type_id\":\"3\",\"price\":\"0\",\"item_type_name\":\"book\",\"item_id\":\"5861554\",\"freetext\":\"\",\"modify_operator_id\":\"ks21\"}", "{\"sensitize\":\"Y\",\"spine_label\":\"\",\"magnetic_media\":\"N\",\"recalls_placed\":\"0\",\"temp_location\":\"0\",\"historical_browses\":\"0\",\"item_enum\":\"\",\"item_sequence_number\":\"1\",\"historical_charges\":\"0\",\"create_date\":\"2003-04-12 14:15:18.0\",\"copy_number\":\"1\",\"create_location_id\":\"187\",\"mfhd_id\":\"5136116\",\"short_loan_charges\":\"0\",\"chron\":\"\",\"reserve_charges\":\"0\",\"year\":\"\",\"modify_location_id\":\"100\",\"media_type_id\":\"0\",\"create_operator_id\":\"lbb4\",\"historical_bookings\":\"0\",\"holds_placed\":\"0\",\"perm_location\":\"87\",\"modify_date\":\"2013-11-04 12:40:08.0\",\"temp_item_type_id\":\"0\",\"caption\":\"\",\"on_reserve\":\"N\",\"pieces\":\"1\",\"item_type_id\":\"9\",\"price\":\"0\",\"item_type_name\":\"nocirc\",\"item_id\":\"6694301\",\"freetext\":\"\",\"modify_operator_id\":\"pm66\"}"]
      }
    }

    context "retrieving holdings data for its bib id" do

      it "returns nil if no bibid is passed in" do
        request = FactoryGirl.build(:request, bibid: nil)
        result = request.get_holdings document
        result.nil?.should == true
      end

      it "returns nil for an invalid bibid" do
        request = FactoryGirl.build(:request, bibid: 500000000)
        VCR.use_cassette 'holdings/invalid_bibid' do
          result = request.get_holdings document
          puts "---\n" + result.inspect + "---\n"
          result[request.bibid.to_s].empty?.should == true
        end
      end

      it "returns a status_short holdings record if no type is specified" do
        request = FactoryGirl.build(:request, bibid: 6665264)
        VCR.use_cassette 'holdings/status_short' do
          result = request.get_holdings document
          puts "---\n" + result.inspect + "---\n"
          result[request.bibid].empty?.should_not == true
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

        it "returns 'Not Charged' if item status is 'Not Charged'" do
          result = rc.item_status BlacklightCornellRequests::Request::NOT_CHARGED
          result.should == BlacklightCornellRequests::Request::NOT_CHARGED
        end
        
        it "returns 'Not Charged' if item status is 'Discharged'" do
          result = rc.item_status BlacklightCornellRequests::Request::DISCHARGED
          result.should == BlacklightCornellRequests::Request::NOT_CHARGED
        end
        
        it "returns '' if item status is 'Cataloging Review'" do
          result = rc.item_status BlacklightCornellRequests::Request::CATALOG_REVIEW
          result.should == BlacklightCornellRequests::Request::NOT_CHARGED
        end
        
        it "returns 'Not Charged' if item status is 'Circulation Review'" do
          result = rc.item_status BlacklightCornellRequests::Request::CIRCULATION_REVIEW
          result.should == BlacklightCornellRequests::Request::NOT_CHARGED
        end

        it "returns 'Charged' if item status is 'Charged'" do
          result = rc.item_status BlacklightCornellRequests::Request::CHARGED
          result.should == BlacklightCornellRequests::Request::CHARGED
        end

        it "returns 'Charged' if item status is 'Renewed'" do
          result = rc.item_status BlacklightCornellRequests::Request::RENEWED
          result.should == BlacklightCornellRequests::Request::CHARGED
        end

        it "returns 'Charged' if item status is 'In transit ON HOLD .'" do
          result = rc.item_status BlacklightCornellRequests::Request::IN_TRANSIT_ON_HOLD
          result.should == BlacklightCornellRequests::Request::CHARGED
        end
        
        it "returns 'Charged' if item status is 'In transit to (anything but dot)'" do
          result = rc.item_status BlacklightCornellRequests::Request::IN_TRANSIT
          result.should == BlacklightCornellRequests::Request::NOT_CHARGED
        end
        
        it "returns 'Charged' if item status is 'In transit to (anything but dot)'" do
          result = rc.item_status BlacklightCornellRequests::Request::IN_TRANSIT_DISCHARGED
          result.should == BlacklightCornellRequests::Request::NOT_CHARGED
        end
        
        it "returns 'Charged' if item status is Hold''" do
          result = rc.item_status BlacklightCornellRequests::Request::ON_HOLD
          result.should == BlacklightCornellRequests::Request::CHARGED
        end
        
        it "returns 'Charged' if item status is 'Overdue'" do
          result = rc.item_status BlacklightCornellRequests::Request::OVERDUE
          result.should == BlacklightCornellRequests::Request::CHARGED
        end
        
        it "returns 'Charged' if item status is 'Recall'" do
          result = rc.item_status BlacklightCornellRequests::Request::RECALL_REQUEST
          result.should == BlacklightCornellRequests::Request::CHARGED
        end
        
        it "returns 'Charged' if item status is 'Claims'" do
          result = rc.item_status BlacklightCornellRequests::Request::CLAIMS_RETURNED
          result.should == BlacklightCornellRequests::Request::CHARGED
        end
        
        it "returns 'Charged' if item status is 'Damaged'" do
          result = rc.item_status BlacklightCornellRequests::Request::DAMAGED
          result.should == BlacklightCornellRequests::Request::CHARGED
        end
        
        it "returns 'Charged' if item status is 'Withdrawn'" do
          result = rc.item_status BlacklightCornellRequests::Request::WITHDRAWN
          result.should == BlacklightCornellRequests::Request::CHARGED
        end
        
        it "returns 'Charged' if item status is 'Call Slip Request'" do
          result = rc.item_status BlacklightCornellRequests::Request::CALL_SLIP_REQUEST
          result.should == BlacklightCornellRequests::Request::CHARGED
        end
        
        it "returns 'Requested' if item status is 'Requested'" do
          result = rc.item_status BlacklightCornellRequests::Request::REQUESTED
          result.should == BlacklightCornellRequests::Request::REQUESTED
        end

        it "returns 'Missing' if item status is 'Missing'" do
          result = rc.item_status BlacklightCornellRequests::Request::MISSING
          result.should == BlacklightCornellRequests::Request::MISSING
        end

        it "returns 'Lost' if item status is 'Lost'" do
          result = rc.item_status BlacklightCornellRequests::Request::LOST_LIBRARY_APPLIED
          result.should == BlacklightCornellRequests::Request::LOST
        end
        
        it "returns 'Lost' if item status is 'Lost'" do
          result = rc.item_status BlacklightCornellRequests::Request::LOST_SYSTEM_APPLIED
          result.should == BlacklightCornellRequests::Request::LOST
        end
        
        it "returns 'At Bindery' if item status is 'At Bindery'" do
          result = rc.item_status BlacklightCornellRequests::Request::AT_BINDERY
          result.should == BlacklightCornellRequests::Request::AT_BINDERY
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
          params = { :service => 'hold', :status => 'Hold' }
          req.get_delivery_time('hold', params).should == 180
        end

        it "returns 180 if there is a hold date problem" do
          params = { :service => 'hold', :status => 'Hold -- Due on 1977-10-15' }
          req.get_delivery_time('hold', params).should == 180          
        end

        it "returns the remaining time till due date plus padding time for a valid hold date" do
          params = { :service => 'hold', :status => "Hold -- Due on #{Date.today + 10}" }
          # fix this when due date is properly handled
          # req.get_delivery_time('hold', params).should == 10 + req.get_hold_padding
          req.get_delivery_time('hold', params).should == 180
        end

      end

      describe 'ill' do 

        it "returns 14" do
          req.get_delivery_time('ill', nil).should == 14
        end

      end

      describe 'recall' do 

        it "returns 15" do
          req.get_delivery_time('recall', nil).should == 15 
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

  item = {
    "sensitize"=>"Y",
           "spine_label"=>"",
           "magnetic_media"=>"N",
           "recalls_placed"=>"0",
           "temp_location"=>"0",
           "historical_browses"=>"1",
           "item_enum"=>"v.10",
           "item_sequence_number"=>"10",
           "historical_charges"=>"0",
           "create_date"=>"2000-05-31 00:00:00.0",
           "copy_number"=>"1",
           "create_location_id"=>"0",
           "mfhd_id"=>"6058442",
           "short_loan_charges"=>"0",
           "chron"=>"1939",
           "reserve_charges"=>"0",
           "year"=>"",
           "modify_location_id"=>"100",
           "media_type_id"=>"0",
           "create_operator_id"=>"",
           "historical_bookings"=>"0",
           "holds_placed"=>"0",
           "perm_location"=>"99",
           "modify_date"=>"2006-12-21 20:25:35.0",
           "temp_item_type_id"=>"0",
           "caption"=>"",
           "on_reserve"=>"N",
           "pieces"=>"1",
           "item_type_id"=>"3",
           "price"=>"0",
           "item_type_name"=>"book",
           "item_id"=>"5511982",
           "freetext"=>"",
           "modify_operator_id"=>"es254",
           "status"=>2,
           "call_number"=>"PR6068.O924 H36 1998",
           "location"=>"Olin Library",
           "exclude_location_id"=>['181', '188'],
           "callNumber" => "PR6068.O924 H36 1998",
           :copy_number => "1",
           :item_type_id => type_code,
           :status => req.item_status(status),
           :exclude_location_id => [181, 188]
        }.with_indifferent_access
                puts "mjc12test: options: #{type_code}, #{status}"

  return r.get_delivery_options(item, { :item_type_id => type_code, :status => status })

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
    "sensitize"=>"Y",
           "spine_label"=>"",
           "magnetic_media"=>"N",
           "recalls_placed"=>"0",
           "temp_location"=>"0",
           "historical_browses"=>"1",
           "item_enum"=>"v.10",
           "item_sequence_number"=>"10",
           "historical_charges"=>"0",
           "create_date"=>"2000-05-31 00:00:00.0",
           "copy_number"=>"1",
           "create_location_id"=>"0",
           "mfhd_id"=>"6058442",
           "short_loan_charges"=>"0",
           "chron"=>"1939",
           "reserve_charges"=>"0",
           "year"=>"",
           "modify_location_id"=>"100",
           "media_type_id"=>"0",
           "create_operator_id"=>"",
           "historical_bookings"=>"0",
           "holds_placed"=>"0",
           "perm_location"=>"99",
           "modify_date"=>"2006-12-21 20:25:35.0",
           "temp_item_type_id"=>"0",
           "caption"=>"",
           "on_reserve"=>"N",
           "pieces"=>"1",
           "item_type_id"=>"3",
           "price"=>"0",
           "item_type_name"=>"book",
           "item_id"=>"5511982",
           "freetext"=>"",
           "modify_operator_id"=>"es254",
           "status"=>2,
           "call_number"=>"PR6068.O924 H36 1998",
           "location"=>"Olin Library",
           "exclude_location_id"=>['181', '188'],
           "callNumber" => "PR6068.O924 H36 1998",
           :copy_number => "1",
           :item_type_id => type_code,
           :status => req.item_status(status),
           :exclude_location_id => [181, 188]
        }.with_indifferent_access
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
