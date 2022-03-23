# Rails application example
OmniAuth.config.logger = Rails.logger if Rails.env.development?

Rails.application.config.middleware.use OmniAuth::Builder do
    provider :google_oauth2, ENV['GOOGLE_CLIENT_ID'], ENV['GOOGLE_CLIENT_SECRET']
  end
OmniAuth.config.allowed_request_methods = %i[post]

