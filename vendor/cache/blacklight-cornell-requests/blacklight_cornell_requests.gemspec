$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "blacklight_cornell_requests/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "blacklight_cornell_requests"
  s.version     = BlacklightCornellRequests::VERSION
  s.authors     = ["Shinwoo Kim", "Matt Connolly"]
  s.email       = ["cul-da-developers-l@list.cornell.edu"]
  s.homepage    = "http://search.library.cornell.edu"
  s.summary     = "Given a bibid, provide user with the best delivery option and all other available options."
  s.description = "Given a bibid, provide user with the best delivery option and all other available options."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "rails", "~> 4.0"
  s.add_dependency 'protected_attributes'
  # s.add_dependency "jquery-rails"
  s.add_dependency 'haml', ['>= 3.0.0']
  s.add_dependency 'haml-rails'
  s.add_dependency 'httpclient'
  s.add_dependency 'net-ldap'
  s.add_dependency 'blacklight',['~> 4.3']
  s.add_dependency 'i18n'
  s.add_dependency 'nokogiri'
  s.add_dependency 'dotenv'
  s.add_dependency 'dotenv-rails'
  s.add_dependency 'dotenv-deployment'
  s.add_dependency 'borrow_direct'

  s.add_development_dependency "sqlite3"

  s.add_development_dependency "rspec-rails", "~> 2.5"
  s.add_development_dependency "capybara", "2.4.1"
  s.add_development_dependency "guard-spork"
  s.add_development_dependency "guard-rspec"
  s.add_development_dependency "spork"
  s.add_development_dependency "webmock"
  s.add_development_dependency "vcr"
  s.add_development_dependency 'factory_girl_rails'
end
