# frozen_string_literal: true

# A browser-side MCP client for this catalog's own endpoint.
#
# The page served here *is* the client. It speaks JSON-RPC to /mcp with fetch(),
# exactly the way any other MCP client would, and builds its forms from the
# schemas `tools/list` hands back. Nothing about the tools is described twice:
# add a tool, or an argument to one, and this console picks it up on reload.
#
# Deliberately thin. There is no server-side proxy, so there is no second code
# path to keep honest, and nothing this page can reach that an outside client
# could not reach for itself.
#
# A development tool. BlacklightMcp::Console decides where it exists, and the
# route is constrained on the same predicate, so off a development machine this
# path is an ordinary 404 unless someone sets MCP_CONSOLE=true. The check below is
# the same answer again, in case the route is ever reached another way.
class McpConsoleController < ActionController::Base
  layout false

  # GET /mcp/console
  def show
    return head :not_found unless BlacklightMcp::Console.enabled?

    render :show
  end
end
