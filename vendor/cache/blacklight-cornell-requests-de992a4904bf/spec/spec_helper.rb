require 'rubygems'
require 'spork'
require 'webmock/rspec'
require 'vcr'
require "factory_girl_rails"
require 'blacklight'
require 'dotenv'
Dotenv.load

FactoryGirl.find_definitions

ENV['RAILS_ENV'] ||= 'test'

ENGINE_RAILS_ROOT=File.join(File.dirname(__FILE__), '../')

Spork.prefork do
  ENV["RAILS_ENV"] ||= 'test'
  require File.expand_path("../dummy/config/environment", __FILE__)
  require 'rspec/rails'
  require 'rspec/autorun'

#   Dir[File.join(ENGINE_RAILS_ROOT, "spec/support/**/*.rb")].each {|f| require f }

#ENGINE_RAILS_ROOT=File.join(File.dirname(__FILE__), '../')
Dir[File.join(ENGINE_RAILS_ROOT, "spec/support/**/*.rb")].each {|f| require f }

  RSpec.configure do |config|
    config.fixture_path = "#{::Rails.root}/spec/fixtures"
    config.use_transactional_fixtures = true
    config.infer_base_class_for_anonymous_controllers = false
    #config.order = "random"
  end
end

Spork.each_run do
end
