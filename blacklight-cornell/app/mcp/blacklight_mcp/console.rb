# frozen_string_literal: true

module BlacklightMcp
  # Whether the browser console at /mcp/console exists.
  #
  # It is a development tool. It exercises the endpoint, shows the raw JSON-RPC
  # under every answer, and is where you go to find out why a tool call did what
  # it did. A deployed host does not need it, and an unlisted page is still a
  # page -- so it is absent everywhere but development unless someone asks for
  # it by name.
  #
  #   MCP_CONSOLE unset     on in development, absent everywhere else
  #   MCP_CONSOLE=true      on, wherever it is set
  #   MCP_CONSOLE=false     absent, development included
  #
  # The route is constrained on this, so when it is off the path does not exist
  # rather than answering with a refusal -- there is nothing there to find.
  module Console
    PATH = '/mcp/console'

    module_function

    def enabled?
      # Do not show the MCP Console if MCP is disabled
      return false unless BlacklightMcp.enabled?

      case ENV.fetch('MCP_CONSOLE', '').to_s.strip.downcase
      when 'true' then true
      when 'false' then false
      else Rails.env.development?
      end
    end
  end
end
