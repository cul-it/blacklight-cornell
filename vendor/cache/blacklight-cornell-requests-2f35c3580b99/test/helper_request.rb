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
  VOYAGER_GET_HOLDS = "#{ENV['REST_URL']}/GetHoldingsService"
  VOYAGER_REQ_HOLDS = "#{ENV['REST_URL']}/SendPatronRequestService"
  MYACC_URL  = "#{ENV['REST_URL']}/MyAccountService"
  include BlacklightCornellRequests
end




VCR.configure do |c|
  c.allow_http_connections_when_no_cassette = true
  c.cassette_library_dir = 'test/fixtures/vcr_cassettes'
  c.default_cassette_options = {:re_record_interval => 720.days}
  c.hook_into :webmock # or :fakeweb
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

MiniTest::Unit.autorun
