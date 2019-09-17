source 'https://rubygems.org'
ruby "2.5.5"
#another try
gem 'rails', '5.2.3'
gem "dotenv-rails"
gem "dotenv-deployment"
gem 'appsignal'
gem "sprockets", '~> 3.7.2'

# added for rails 4.
gem 'activerecord-session_store'
gem 'protected_attributes_continued'
gem 'mini_racer', platforms: :ruby

group :development,:test, :integration do
  gem "rspec_junit_formatter"
  gem 'sqlite3', '~> 1.3.13' #latest 1.4 results in error
  gem "spreewald", :git => 'https://github.com/makandra/spreewald.git'
end

group :production,:staging do
  gem 'mysql2'
end

gem 'savon', '~> 2.11.1'
gem 'parslet'
gem 'ultraviolet'
gem 'yaml_db'
gem 'blacklight', '7.0.1'
gem 'blacklight_range_limit', '~> 7.0'
gem 'blacklight_unapi', :git => 'https://github.com/cul-it/blacklight-unapi', :branch => 'BL7-upgrade'
gem 'kaminari', '>= 0.15'

gem 'blacklight-hierarchy', :git => 'https://github.com/cul-it/blacklight-cornell-hierarchy', :branch => 'master'
gem 'htmlentities'
gem 'json'
gem 'httpclient'
gem 'haml'
gem 'haml-rails'
gem 'marc'
gem 'blacklight-marc'
gem 'rb-readline', '~> 0.5.x'
gem 'net-ldap'
gem 'nokogiri'
gem 'rufus-scheduler'
gem 'addressable'
gem 'redis-session-store'
gem 'rsolr'
#gem 'mini_racer', platforms: :ruby
# Gems used only for assets and not required
# in production environments by default.
  gem 'sass-rails',   '~> 5.0'
  gem 'coffee-rails', '~> 4.0'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes

  gem 'uglifier', '>= 1.0.3'

group :development, :test do
  gem 'rspec'
  gem 'rspec-rails'
  gem 'cucumber-rails', :require => false # Set require = false to get rid of a warning message
  gem 'database_cleaner'
  gem 'webrat'
  gem 'guard-rspec'
  gem 'poltergeist'
  gem 'pry'
  gem 'pry-byebug'
  gem 'meta_request'
  gem 'awesome_print'
  gem 'xray-rails' # Adding to explore which views are used
end

group :test do
  gem 'capybara','>= 2.3', '< 4'
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
#  gem 'mini_racer', platforms: :ruby
  gem 'phantomjs', :require => 'phantomjs/poltergeist'
end

gem 'jquery-rails'
gem 'jquery-ui-rails', '5.0.5'
gem 'rvm-capistrano'
gem 'capistrano'
gem 'capistrano-ext'
gem 'unicode', :platforms => [:mri_18, :mri_19, :mri_20]
gem 'devise', '~> 4.6.0'
gem 'devise-guests', '~> 0.3'

gem 'omniauth'
gem 'omniauth-saml'
#gem 'omniauth-google-oauth2'
# Use Omniauth Google plugin
gem 'omniauth-google-oauth2', '~> 0.4.1'
# Use Omniauth Facebook plugin
gem 'omniauth-facebook', '~> 4.0'
  # To handle omniauth security
gem "omniauth-rails_csrf_protection"
gem 'xmlrpc'
gem 'bootstrap'
gem 'font-awesome-rails'
gem 'blacklight_cornell_requests',:git =>'https://github.com/cul-it/blacklight-cornell-requests', :branch => 'master'
#gem 'blacklight_cornell_requests', :path => '/Users/matt/code/d&a/blacklight-cornell-requests'
#gem 'my_account', :path => '/Users/matt/code/cul/d&a/cul-my-account'
gem 'my_account', :git => 'https://github.com/cul-it/cul-my-account', :branch => 'master'
gem 'borrow_direct', :git => 'https://github.com/jrochkind/borrow_direct'

gem 'bento_search'
gem 'celluloid'  # Required for bento_search multisearcher
gem 'mollom'
gem 'exception_notification'
gem 'piwik_analytics', '~> 1.0.1'
gem 'citeproc'
gem 'csl-styles', :git => 'https://github.com/cul-it/csl-styles', :branch => 'master', :submodules => true
#gem 'csl-styles', :git => 'git://github.com/cul-it/csl-styles', :branch => 'master', :submodules => true
gem 'citeproc-ruby'
gem 'unicode_utils'
gem 'google-analytics-rails', '1.1.1'

# LD4P
gem 'leaflet-rails'
