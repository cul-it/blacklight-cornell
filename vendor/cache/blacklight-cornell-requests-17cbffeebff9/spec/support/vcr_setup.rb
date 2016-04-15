VCR.configure do |c|
  #the directory where your cassettes will be saved
  c.cassette_library_dir = 'spec/vcr'
  # your HTTP request service. You can also use fakeweb, typhoeus, and more
  c.hook_into :webmock
  c.allow_http_connections_when_no_cassette = true # This means that we don't *always* have to use VCR for HTTP, only when we want
  c.filter_sensitive_data('<REST_URL>')  { "#{ENV['REST_URL']}"}
  c.filter_sensitive_data('<VOYAGER_DB>') { "#{ENV['VOYAGER_DB']}"}
  c.filter_sensitive_data('<DUMMY_VOYAGER_HOLDINGS>') { "#{ENV['DUMMY_VOYAGER_HOLDINGS']}"}
  c.filter_sensitive_data('<TEST_LASTNAME>') { "#{ENV['TEST_LASTNAME']}"}
  c.filter_sensitive_data('<TEST_USER_BARCODE>') { "#{ENV['TEST_USER_BARCODE']}"}
  c.filter_sensitive_data('<TEST_USER_ID>') { "#{ENV['TEST_USER_ID']}"}
  c.filter_sensitive_data('<TEST_NETID>') { "#{ENV['TEST_NETID']}"}
  c.filter_sensitive_data('<NETID_URL>') { "#{ENV['NETID_URL']}"}
  c.filter_sensitive_data('<TEST_FIRSTNAME>') { "#{ENV['TEST_FIRSTNAME']}"}
end