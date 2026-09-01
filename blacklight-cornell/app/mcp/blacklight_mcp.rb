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

  # The caller asked for something this catalog can't do, like a facet that
  # doesn't exist. The message goes back to the AI so it can fix its
  # arguments and try again.
  class InvalidArgument < StandardError; end

  # No record with that id.
  class NotFound < StandardError; end
end
