Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "*.library.cornell.edu"  # adjust this if you want to limit origins
    resource "*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end
