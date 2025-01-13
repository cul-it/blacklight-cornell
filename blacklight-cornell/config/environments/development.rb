BlacklightCornell::Application.configure do
  config.hosts << /[a-z0-9\-.]+\.library\.cornell\.edu/

  # Settings specified here will take precedence over those in config/application.rb
  config.eager_load = false
  #config.eager_load = true

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.perform_deliveries = false
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address: ENV["SMTP_ADDRESS"],
    port: ENV["SMTP_PORT"],
    user_name: ENV["SMTP_USERNAME"],
    password: ENV["SMTP_PASSWORD"],
    authentication: :login,
    enable_starttls_auto: true,
  }
  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log
  # See everything in the log (default is :info)
  config.logger = ActiveSupport::Logger.new(STDOUT)
  #config.log_level = ENV["LOG_LEVEL"].blank?  ? :debug : ENV["LOG_LEVEL"].to_sym
  config.log_level = ENV["LOG_LEVEL"].blank? ? :debug : ENV["LOG_LEVEL"].to_sym

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Raise exception on mass assignment protection for Active Record models
  #config.active_record.mass_assignment_sanitizer = :strict
  #config.active_record.mass_assignment_sanitizer = false
  config.active_record.yaml_column_permitted_classes = [
    ActiveSupport::HashWithIndifferentAccess,
  ]

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  #  config.active_record.auto_explain_threshold_in_seconds = 0.5

  # Do not compress assets
  config.assets.compress = false

  # Expands the lines which load the assets
  config.assets.debug = true

  # this allows WEBrick to handle pipe symbols in query parameters
  #URI::DEFAULT_PARSER = URI::Parser.new(:UNRESERVED => URI::REGEXP::PATTERN::UNRESERVED + '|')

end
