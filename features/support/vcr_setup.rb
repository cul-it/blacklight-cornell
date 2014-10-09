require 'vcr'

VCR.configure do |c|
  #the directory where your cassettes will be saved
  c.cassette_library_dir = 'features/cassettes'
  # your HTTP request service. You can also use fakeweb, typhoeus, and more
  c.hook_into :webmock
  c.ignore_localhost = true
  c.allow_http_connections_when_no_cassette = true # This means that we don't *always* have to use VCR for HTTP, only when we want
  #c.allow_http_connections_when_no_cassette = false # This means that we don't *always* have to use VCR for HTTP, only when we want
  c.default_cassette_options = { :record => :new_episodes, :erb => true }
end

VCR.cucumber_tags do |t|
  t.tag  '@availability'
  t.tag  '@missing'
  t.tag  '@search_availability_title_mission_etrangeres_missing'
  t.tag  '@search_availability_annotated_hobbit'
end
