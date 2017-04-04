#!/usr/bin/env rake
begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end
begin
  require 'rdoc/task'
rescue LoadError
  require 'rdoc/rdoc'
  require 'rake/rdoctask'
  RDoc::Task = Rake::RDocTask
end

RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'BlacklightCornellRequests'
  rdoc.options << '--line-numbers'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end


require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test' << 'lib/blacklight_cornell_requests'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

require 'ci/reporter/rake/minitest'

APP_RAKEFILE = File.expand_path("../spec/dummy/Rakefile", __FILE__)
load 'rails/tasks/engine.rake'

task :test => ["ci:setup:minitest"] 

Bundler::GemHelper.install_tasks

