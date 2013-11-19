require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'minitest/unit'
#require 'mocha'


$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'voyager_request'
require 'james_monkeys'
require 'vcr'
require 'webmock'

require 'active_support/all'

class MiniTest::Unit::TestCase
end

class VoyagerRequestTestCase < MiniTest::Unit::TestCase
  VOYAGER_GET_HOLDS = "http://catalog-test.library.cornell.edu:7074/vxws/GetHoldingsService"
  VOYAGER_REQ_HOLDS = "http://catalog-test.library.cornell.edu:7074/vxws/SendPatronRequestService"
  MYACC_URL  = 'http://catalog-test.library.cornell.edu:7074/vxws/MyAccountService'
  include BlacklightCornellRequests
end




VCR.configure do |c|
  c.allow_http_connections_when_no_cassette = true
  c.cassette_library_dir = 'test/fixtures/vcr_cassettes'
  c.default_cassette_options = {:re_record_interval => 720.days}
  c.hook_into :webmock # or :fakeweb
end

MiniTest::Unit.autorun
