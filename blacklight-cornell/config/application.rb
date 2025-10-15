require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require File.expand_path('../../lib/james_monkeys', __FILE__)
require File.expand_path('../../lib/maybe', __FILE__)

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

    # Search results limit, to prevent deep paging issues
    config.search_limit = 20000
  end
end

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

end
