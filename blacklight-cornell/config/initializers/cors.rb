# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  # The MCP endpoint is public, unauthenticated and read-only by design, so a
  # browser-based client can't reach anything it couldn't already GET from the
  # catalog. Browser MCP clients (the MCP Inspector, in-page agents) need any
  # origin, plus the two headers the streamable HTTP transport sets -- without
  # `expose` the browser hides them from the client and the session breaks.
  #
  # This block comes first so it wins the path match for Cornell origins too;
  # the wildcard resource below would otherwise match /mcp without exposing
  # those headers. No credentials: cookies must never ride along here.
  allow do
    origins "*"
    resource "/mcp",
      headers: :any,
      methods: [:get, :post, :options],
      expose: ["Mcp-Session-Id", "MCP-Protocol-Version"],
      credentials: false
  end

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
