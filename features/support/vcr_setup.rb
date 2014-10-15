require 'vcr'
#use_mock_and_vcr = false 
use_mock_and_vcr = true 
VCR.configure do |c|
  #the directory where your cassettes will be saved
  c.cassette_library_dir = 'features/cassettes'
  # turn off webmock if we do not want to use vcr and webmock
  if use_mock_and_vcr 
    then  
      # your HTTP request service. You can also use fakeweb, typhoeus, and more
      c.hook_into :webmock
      #c.allow_http_connections_when_no_cassette = false # This means that we *always* have to use VCR for HTTP
      c.allow_http_connections_when_no_cassette = true # This means that we don't *always* have to use VCR for HTTP, only when we want
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
  t.tag  '@DISCOVERYACCESS-137'
  t.tag  '@DISCOVERYACCESS-1430'
  t.tag  '@availability'
  t.tag  '@missing'
  t.tag  '@search_availability_title_mission_etrangeres_missing'
  t.tag  '@search_availability_annotated_hobbit'
end
end
