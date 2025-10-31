# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "*.library.cornell.edu"  # adjust this if you want to limit origins
    resource "*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end

  allow do
    origins "https://amplify-pages.d277og7fvixi1h.amplifyapp.com", "*.library.cornell.edu"
    resource "/status", headers: :any, methods: [:get]
    resource "/status.json", headers: :any, methods: [:get]
  end
end
