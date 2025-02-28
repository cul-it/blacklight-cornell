require File.expand_path('../boot', __FILE__)

require 'rails/all'
#require 'celluloid/autostart'
require 'celluloid/current'
require 'dotenv'

# Load defaults from config/*.env in config
# Dotenv.load *Dir.glob(Rails.root.join("config/**/*.env"), File::FNM_DOTMATCH)
# error if .env does not exist.
begin
  Dotenv.load! *Dir.glob(".env", File::FNM_DOTMATCH)
rescue
   puts <<-eos
   ******************************************************************************
   Your .env config file is missing.
   See DOTENV.example for a blank file.
   ******************************************************************************
   eos
   exit(1)
 end
#
# # Override any existing variables if an environment-specific file exists
# Dotenv.overload *Dir.glob(Rails.root.join("config/**/*.env.#{Rails.env}"), File::FNM_DOTMATCH)

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require(*Rails.groups(:assets => %w(development test)))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end
require File.expand_path('../../lib/james_monkeys', __FILE__)
require File.expand_path('../../lib/bl_monkeys', __FILE__)
module BlacklightCornell
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)
    config.autoload_paths += %W(#{config.root}/lib)
    #config.autoload_paths += Dir["#{config.root}/lib/**/"]

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Enable escaping HTML in JSON.
    config.active_support.escape_html_entities_in_json = true

    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    # config.active_record.schema_format = :sql

    # Enforce whitelist mode for mass assignment.
    # This will create an empty whitelist of attributes available for mass-assignment for all models
    # in your app. As such, your models will need to explicitly whitelist or blacklist accessible
    # parameters by using an attr_accessible or attr_protected declaration.
    #config.active_record.whitelist_attributes = true

    # Enable the asset pipeline
    config.assets.enabled = true
    # Default SASS Configuration, check out https://github.com/rails/sass-rails for details
    config.assets.compress = !Rails.env.development?

    config.assets.precompile += ['cornell/print.css']
    config.assets.precompile << /\.(?:svg|eot|woff|ttf)$/
    config.assets.paths << Rails.root.join('vendor', 'assets', 'fonts')

    config.active_record.suppress_multiple_database_warning

    # custom error pages
    config.exceptions_app = self.routes
    config.action_controller.permit_all_parameters = true

    # Generate ids on inputs with form_with
    config.action_view.form_with_generates_ids = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    # Search results limit, to prevent deep paging issues
    config.search_limit = 20000

    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins "https://amplify-pages.d277og7fvixi1h.amplifyapp.com", "*.library.cornell.edu"
        resource "/status", headers: :any, methods: [:get]
        resource '/status.json', headers: :any, methods: [:get]
      end
    end
  end
end
if true
# Monkey patch
module Blacklight::SearchFields
  # Looks up a search field blacklight_config hash from search_field_list having
  # a certain supplied :key.
  def search_field_def_for_key(key)
    blacklight_config.search_fields[key] ?
      blacklight_config.search_fields[key] :
      blacklight_config.default_search_field
  end

  # Returns default search field, used for simpler display in history, etc.
  # if not set in blacklight_config, defaults to first field listed in #search_field_list
  def default_search_field
    blacklight_config.default_search_field || search_field_list.first
  end


  # Shortcut for commonly needed operation, look up display
  # label for the key specified. Returns "Keyword" if a label
  # can't be found.
  def label_for_search_field(key)
    field_def = search_field_def_for_key(key)
    if field_def && field_def.label
       field_def.label
    else
       I18n.t('blacklight.search.fields.default')
    end
  end

end # if module SearchFields

end # if  false




