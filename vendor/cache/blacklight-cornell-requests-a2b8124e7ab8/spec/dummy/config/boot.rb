require 'rubygems'

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

ENV['RAILS_ENV'] ||= IO.read('.env').match(/RAILS_ENV=(\w+)/)[1]


require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])
