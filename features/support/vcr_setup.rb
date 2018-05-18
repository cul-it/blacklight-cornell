require 'vcr'
#use_mock_and_vcr = false 
# only matters that env variables is set, does not matter what value is.
use_mock_and_vcr = ENV['VCR_USE_MOCK_AND_VCR'] ? true : false  
use_mock_and_vcr = true
VCR.configure do |c|
  #the directory where your cassettes will be saved
  c.cassette_library_dir = 'features/cassettes'
  c.default_cassette_options = { :record => :new_episodes, :erb => true }
  # turn off webmock if we do not want to use vcr and webmock
  if use_mock_and_vcr 
    then  
      # your HTTP request service. You can also use fakeweb, typhoeus, and more
      c.default_cassette_options = { :record => :new_episodes, :erb => true }
      c.hook_into :webmock
      c.debug_logger = File.open("vcr.log", 'w')
      #c.allow_http_connections_when_no_cassette = ENV['VCR_ALLOW_HTTP'] ? true : false #false means we *always* have to use VCR for HTTP
      #c.allow_http_connections_when_no_cassette = true # true means that we don't *always* have to use VCR for HTTP, only when we want
      c.allow_http_connections_when_no_cassette = true # false means that we *always* have to use VCR for HTTP
    else 
      VCR.turn_off!
      WebMock.allow_net_connect!
      c.allow_http_connections_when_no_cassette = true # This means that we don't *always* have to use VCR for HTTP, only when we want
  end 
  c.ignore_localhost = true
  c.default_cassette_options = { :record => :new_episodes, :erb => true }
end
if use_mock_and_vcr
then
  VCR.cucumber_tags do |t|
    t.tag  '@all'
    t.tag  '@citations'
    t.tag  '@databases'
    t.tag  '@digitalcollections'
    t.tag  '@browse'
    t.tag  '@tou'
    t.tag  '@linkfields'
    t.tag  '@begins_with'
    t.tag  '@all_select_and_export'
    t.tag  '@all_search'
    t.tag  '@all_results_list'
    t.tag  '@all_item_view'
    #t.tag  '@javascript'
    t.tag  '@homepage'
    t.tag  '@holdings'
    t.tag  '@DISCOVERYACCESS-137'
    t.tag  '@DISCOVERYACCESS-1430'
    t.tag  '@availability'
    t.tag  '@missing'
    t.tag  '@search_availability_title_mission_etrangeres_missing'
    t.tag  '@search_availability_annotated_hobbit'
  end
end
