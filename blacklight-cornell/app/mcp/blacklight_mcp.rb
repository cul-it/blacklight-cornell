# frozen_string_literal: true

# Read-only Model Context Protocol (MCP) server for the catalog.
#
# The tools here never talk to Solr directly. They translate their arguments into
# exactly the Blacklight params a browser would submit -- q_row/op_row/boolean_row/
# search_field_row for advanced search, f/f_inclusive for facets, range for the
# publication-year limit, sort/page/per_page for everything else -- and then run
# them through CatalogController's own SearchBuilder. Nothing in this namespace
# reimplements the query grammar in SearchBuilder#set_query, so an MCP search and
# the equivalent catalog URL cannot drift apart.
module BlacklightMcp
  VERSION = '1.0.0'

  # Raised when a tool is called with arguments this catalog cannot honor.
  # Surfaced to the client as an MCP tool error (not a protocol error) so the
  # caller can read the message and retry with corrected arguments.
  class InvalidArgument < StandardError; end

  # Raised when a requested record does not exist.
  class NotFound < StandardError; end
end
