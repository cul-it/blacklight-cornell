# require_relative 'boot'

# require 'rails/all'
# #require 'celluloid/autostart'
# require 'celluloid/current'
# require 'dotenv'
# require 'sprockets/railtie'
# require 'blacklight'
# require 'blacklight/marc'

# Load defaults from config/*.env in config
# Dotenv.load *Dir.glob(Rails.root.join("config/**/*.env"), File::FNM_DOTMATCH)
# error if .env does not exist.
# begin
#   Dotenv.load! *Dir.glob(".env", File::FNM_DOTMATCH)
# rescue
#    puts <<-eos
#    ******************************************************************************
#    Your .env config file is missing.
#    See DOTENV.example for a blank file.
#    ******************************************************************************
#    eos
#    exit(1)
#  end
#
# # Override any existing variables if an environment-specific file exists
# Dotenv.overload *Dir.glob(Rails.root.join("config/**/*.env.#{Rails.env}"), File::FNM_DOTMATCH)

# if defined?(Bundler)
#   # If you precompile assets before deploying to production, use this line
#   Bundler.require(*Rails.groups(:assets => %w(development test)))
#   # If you want your assets lazily compiled in production, use this line
#   # Bundler.require(:default, :assets, Rails.env)
# end
# require File.expand_path('../../lib/james_monkeys', __FILE__)
# require File.expand_path('../../lib/bl_monkeys', __FILE__)
require_relative 'boot'

require 'rails/all'
# require 'blacklight'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module BlacklightCornell
  class Application < Rails::Application
    # TODO: Match defaults to rails version 7.2 after confirming that app runs in prod
    # https://guides.rubyonrails.org/upgrading_ruby_on_rails.html#upgrading-from-rails-7-0-to-rails-7-1
    # https://guides.rubyonrails.org/upgrading_ruby_on_rails.html#upgrading-from-rails-7-1-to-rails-7-2
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = "Eastern Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end

