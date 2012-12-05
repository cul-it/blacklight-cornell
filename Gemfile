source 'https://rubygems.org'

gem 'rails', '3.2.9'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'sqlite3'
gem 'mysql', '~>2.8.1'

gem 'blacklight','~> 4.0.0'
gem 'blacklight_range_limit'
gem 'blacklight_advanced_search'
gem 'blacklight_unapi'
gem 'json'
gem 'httpclient'
gem 'haml'
gem 'haml-rails'
gem 'marc'
gem 'rb-readline'
# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
   gem 'therubyracer', :platforms => :ruby

  gem 'uglifier', '>= 1.0.3'
end

group :development, :test do
  gem 'rspec'
  gem 'rspec-rails'
  gem 'cucumber-rails', :require => false # Set require = false to get rid of a warning message
  gem 'database_cleaner'
  gem 'webrat'
  gem 'guard-rspec'
end

group :test do
  gem 'capybara'
  # Following two gems are following the setup proposed in the RoR tutorial
  # at http://ruby.railstutorial.org/chapters/static-pages#sec-advanced_setup
  gem 'rb-inotify'
  gem 'libnotify'
  # Spork support
  gem 'guard-spork', '0.3.2'
  gem 'spork', '0.9.0'
end

gem 'jquery-rails'

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
# gem 'unicorn'

# Deploy with Capistrano
gem 'capistrano'

# To use debugger
# gem 'debugger'

gem "unicode", :platforms => [:mri_18, :mri_19]
gem "devise"
gem "devise-guests", "~> 0.3"
gem "bootstrap-sass"
