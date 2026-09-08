# frozen_string_literal: true
#
# Read-only Model Context Protocol (MCP) server for the catalog.
# Lets an AI assistant search the catalog. Read-only.
#
# The tools here don't build Solr queries. They turn their arguments into the
# same URL parameters the catalog's own search forms submit, then hand those to
# the catalog's normal search code. So an MCP search and the same search typed
# into the website give the same results, and they can't drift apart.
module BlacklightMcp
  VERSION = '1.0.0'

  # MCP Endpoint Switch
  #
  # Set MCP=false in the environment and /mcp, /mcp/console and the discovery
  # routes stop existing. The routes are constrained on this, so a request gets
  # an ordinary 404 -- not a refusal, not an error page. Nothing to find, which
  # is the point: an endpoint under attack should look like it was never there.
  #
  # Only "false" turns it off. Unset, or anything else, leaves it on
  #
  # It comes from the environment, so changing it means a new env file and a
  # restart. To stop traffic faster than that, block /mcp at the WAF: that also
  # keeps the requests off the Puma threads, which this cannot do.
  def self.enabled?
    ENV.fetch('MCP', '').to_s.strip.downcase != 'false'
  end

  # The caller asked for something this catalog can't do, like a facet that
  # doesn't exist. The message goes back to the AI so it can fix its
  # arguments and try again.
  class InvalidArgument < StandardError; end

  # No record with that id.
  class NotFound < StandardError; end
end
