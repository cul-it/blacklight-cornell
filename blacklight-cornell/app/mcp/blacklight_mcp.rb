# In-app MCP server. Exposes Blacklight catalog search / facet metadata to
# Claude (and any other MCP client) over Streamable HTTP at /mcp.
module BlacklightMcp
  VERSION = "0.1.0"

  class << self
    def build_server
      # Tool list is inlined (not a frozen constant) so each rebuild
      # re-resolves the tool classes via constant lookup — important after
      # a Zeitwerk reload in development, when the previous class object
      # has been swapped out.
      MCP::Server.new(
        name: "blacklight-cornell",
        version: VERSION,
        tools: [
          Tools::DescribeFacets,
          Tools::CatalogSearch
        ],
        server_context: { logger: Rails.logger }
      )
    end

    # Memoized Rack app. `stateless: true` lets clients POST without an
    # `initialize` handshake first; `enable_json_response: true` returns a
    # single JSON body instead of an SSE stream, which is friendlier to
    # curl, gateways, and most non-Anthropic MCP clients.
    def rack_app
      @rack_app ||= MCP::Server::Transports::StreamableHTTPTransport.new(
        build_server,
        stateless: true,
        enable_json_response: true
      )
    end

    def reset!
      @rack_app = nil
    end
  end

  # Rack endpoint mounted in routes.rb. The lambda re-resolves
  # BlacklightMcp.rack_app on every request, so when the to_prepare hook
  # (config/initializers/blacklight_mcp_reload.rb) clears the cache after
  # a Rails code reload, the next request gets a freshly-built server.
  # Without this indirection, `mount BlacklightMcp.rack_app` would pin
  # the very first instance built at boot.
  ENDPOINT = ->(env) { BlacklightMcp.rack_app.call(env) }
end
