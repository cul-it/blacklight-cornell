# In-app MCP server. Exposes Blacklight catalog search / facet metadata to
# Claude (and any other MCP client) over Streamable HTTP at /mcp.
module BlacklightMcp
  VERSION = "0.1.0"

  TOOLS = [
    Tools::DescribeFacets,
    Tools::CatalogSearch
  ].freeze

  class << self
    def build_server
      MCP::Server.new(
        name: "blacklight-cornell",
        version: VERSION,
        tools: TOOLS,
        server_context: { logger: Rails.logger }
      )
    end

    # Memoized Rack app for mounting in routes.rb. `stateless: true` lets
    # clients POST without an `initialize` handshake first;
    # `enable_json_response: true` returns a single JSON body instead of an
    # SSE stream, which is friendlier to curl, gateways, and most non-
    # Anthropic MCP clients.
    def rack_app
      @rack_app ||= MCP::Server::Transports::StreamableHTTPTransport.new(
        build_server,
        stateless: true,
        enable_json_response: true
      )
    end
  end
end
