source 'https://rubygems.org'
ruby "3.1.4"
#another try
gem 'rails', '~> 6.1.7'
gem "dotenv-rails"
gem 'appsignal', '~> 3.3.2' #, '2.11.10'
gem "sprockets"#, '~> 3.7.2'
gem "actionview"#, ">= 5.2.7.1"
gem "byebug"
gem "ffi"
# added for rails 4.
gem 'activerecord-session_store', ">= 2.0.0"
gem 'protected_attributes_continued'
#gem 'mini_racer', github: 'sqreen/mini_racer', branch: 'use-libv8-node'
gem 'net-smtp'
gem 'net-sftp'

group :development,:test, :integration do
  gem "rspec_junit_formatter"
  gem 'sqlite3', '~> 1.5.1'
  gem "spreewald", :git => 'https://github.com/makandra/spreewald.git'
  gem 'brakeman'
end

group :production,:staging do
  gem 'mysql2', '0.5.3'
end

gem 'savon', '~> 2.11.1'
gem 'parslet'
gem 'ultraviolet'
gem 'yaml_db'
gem 'blacklight', '7.29.0'
gem 'blacklight_range_limit', '7.1.0'
gem 'blacklight_unapi', :git => 'https://github.com/cul-it/blacklight-unapi', :branch => 'BL7-upgrade'
gem 'kaminari', '>= 0.15'
gem 'view_component', '2.73.0' # ( was 2.72.0)
gem 'blacklight-hierarchy'
gem 'htmlentities'
gem 'json'
gem 'httpclient'
gem 'haml'
gem 'haml-rails'
gem 'marc'
gem 'blacklight-marc', '~> 6.3'
gem 'rb-readline', '~> 0.5.x'
gem 'net-ldap'
gem 'nokogiri', '>= 1.14.3'
gem 'rufus-scheduler'
gem 'addressable', ">= 2.8.0"
gem 'redis-session-store'
gem 'rsolr'
gem 'utf8-cleaner'
gem 'mini_racer', '0.6.2', platforms: :ruby
gem 'libv8-node'
# Gems used only for assets and not required
# in production environments by default.
  gem 'sass-rails',   '~> 5.0'
  gem 'coffee-rails', '~> 4.0'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes

  gem "terser", "~> 1.1"

group :development, :test do
  gem 'rspec'
  gem 'rspec-rails'
  gem 'cucumber-rails', :require => false # Set require = false to get rid of a warning message
  gem 'cucumber', '~> 3.1'
  gem 'database_cleaner'
  gem 'webrat'
  gem 'guard-rspec'
  gem 'pry'
  gem 'pry-byebug'
  gem 'meta_request'
  gem 'awesome_print'
  gem 'selenium-webdriver'
end

group :test do
  gem 'capybara','3.39.2'
  # Following two gems are following the setup proposed in the RoR tutorial
  # at http://ruby.railstutorial.org/chapters/static-pages#sec-advanced_setup
  gem 'rb-inotify', :require => false
  gem 'libnotify', :require => false
  # Spork support
  #gem 'guard-spork', '0.3.2'
  #gem 'spork', '0.9.0'
  gem 'webmock'
  gem 'vcr'
  gem 'capybara-email'
  gem 'simplecov', :require => false
  gem 'simplecov-rcov', :require => false
end

gem 'jquery-rails'
gem 'jquery-ui-rails', '6.0.0'
gem "capistrano", "~> 3.18"
gem "capistrano-rails", "~> 1.6"
gem 'capistrano-rvm'
gem 'capistrano-ext'
gem 'net-ssh', '5.2.0'
gem 'net-scp', '2.0.0'
gem 'unicode', :platforms => [:mri_18, :mri_19, :mri_20]
gem 'devise', '>= 4.7.0'
gem 'devise-guests', '~> 0.3'

gem 'omniauth', '~> 2.0'
gem 'omniauth-saml', '~> 2.0'
gem 'omniauth-oauth2'
gem 'omniauth-rails_csrf_protection'
#gem 'omniauth-google-oauth2'
# Use Omniauth Google plugin
gem 'omniauth-google-oauth2', '~> 0.8'
# Use Omniauth Facebook plugin
gem 'omniauth-facebook', '~> 5.0'
gem 'repost'
gem 'xmlrpc'
gem 'bootstrap', '~> 4.3'
gem 'bootstrap-sass', '~> 3.4.1'
gem 'sassc-rails', '>= 2.1.0'
gem 'sassc', '~> 2.4'
gem 'font-awesome-rails'
gem 'blacklight_cornell_requests', :git =>'https://github.com/cul-it/blacklight-cornell-requests'
# gem 'blacklight_cornell_requests', :path => '/Users/matt/code/cul/d&a/blacklight-cornell-requests'
# gem 'my_account', :path => '/Users/matt/code/cul/d&a/cul-my-account'
gem 'cul-folio-edge', :git => 'https://github.com/cul-it/cul-folio-edge'
gem 'my_account', :git => 'https://github.com/cul-it/cul-my-account'
gem 'borrow_direct', :git => 'https://github.com/jrochkind/borrow_direct'
gem 'ruby-saml', '>= 1.12.1'
gem 'bento_search', '~> 2.0.0.rc1'
gem 'celluloid', '0.17.4' # Required for bento_search multisearcher
gem 'exception_notification'
gem 'piwik_analytics', '~> 1.0.1'
gem 'citeproc'
gem 'csl-styles', :git => 'https://github.com/cul-it/csl-styles', :branch => 'master', :submodules => true
#gem 'csl-styles', :git => 'git://github.com/cul-it/csl-styles', :branch => 'master', :submodules => true
gem 'citeproc-ruby'
gem 'unicode_utils'
gem 'ebsco-eds'
#gem 'loofah', '~> 2.0', '>= 2.3'
gem 'loofah', '2.19.1'

gem 'puma', '~> 6.4', '>= 6.4.2'
gem 'aws-sdk-s3', '~> 1.143'
gem 'uri', '0.12.2'
