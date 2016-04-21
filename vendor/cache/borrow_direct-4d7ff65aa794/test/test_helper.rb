require 'minitest'
require 'minitest/autorun'
require "minispec-metadata"


require 'vcr'
require 'webmock'
require 'minitest-vcr'

require 'borrow_direct'

# Want to run tests against PRODUCTION BD? It WILL result in real requests being
# made to BD production system, so you probably don't -- but if you're not sure
# if production API is really behaving like test, you might want to anyway. 
if ENV["RAILS_ENV"] == "production"
  BorrowDirect::Defaults.api_base = BorrowDirect::Defaults::PRODUCTION_API_BASE
end

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

VCR.configure do |c|
  c.cassette_library_dir = 'test/vcr_cassettes'
  c.hook_into :webmock # or :fakeweb

  # BD API requests tend to have their distinguishing
  # features in a POSTed JSON request body
  c.default_cassette_options = { :match_requests_on => [:method, VCR.request_matchers.uri_without_param(:aid), :body] }
end

MinitestVcr::Spec.configure!

VCRFilter.sensitive_data! :bd_library_symbol
VCRFilter.sensitive_data! :bd_patron
VCRFilter.sensitive_data! :bd_api_key

BorrowDirect::Defaults.api_key = VCRFilter[:bd_api_key]

# Silly way to not have to rewrite all our tests if we
# temporarily disable VCR, make VCR.use_cassette a no-op
# instead of no-such-method. 
if ! defined? VCR  
  module VCR
    def self.use_cassette(*args)
      yield
    end
  end
end
