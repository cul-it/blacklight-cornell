# Blacklight MCP

A read-only [Model Context Protocol](https://modelcontextprotocol.io) endpoint
at `/mcp`. An AI assistant can search the catalog, read records, list facet
values, check availability and walk the shelf. Nothing here writes.

**This file is about the server code.** The other two:
[MCP_SERVER_README.md](../../../MCP_SERVER_README.md) for using the endpoint and
connecting an assistant to it, and
[MCP_CONSOLE_README.md](../assets/javascripts/mcp/console/MCP_CONSOLE_README.md)
for the browser console's JavaScript.

**The rule the design follows:** tools do not build Solr queries. They turn
their arguments into the same URL parameters the catalog's own search forms
submit, then hand those to the catalog's normal search code, so an MCP search
and the same search typed into the website cannot drift apart.
`call_number_browse.rb` is the one exception and says why in its own comments.

## Layout

```text
app/mcp/
├── blacklight_mcp.rb              the MCP=false switch, VERSION, error classes
└── blacklight_mcp/
    ├── server.rb                  the tool list, allowed JSON-RPC methods, client instructions
    ├── tools/                     one class per tool, plus base.rb for what they share
    ├── query_builder.rb           arguments in, catalog search parameters out
    ├── query_builder/             filters, ranges, rows, paging
    ├── search_runner.rb           runs those through Blacklight, with MCP's Solr timeouts
    ├── catalog_options.rb         what this catalog offers, read live from catalog_controller.rb
    ├── facet_names.rb             readable facet labels in, Solr fields out
    ├── result_presenter.rb        search results as a short JSON reply
    ├── availability_presenter.rb  "can I get this now", read off the record
    ├── call_number_browse.rb      the separate call-number Solr collection
    ├── rate_limit.rb              how often one caller may hit /mcp
    ├── landing_page.rb            the page a browser gets at /mcp
    └── console.rb                 whether /mcp/console exists
```

## A request, end to end

1. `McpController` takes the POST — an `ActionController::API`, so no session
   and no CSRF token. It rate-limits, refuses any method outside
   `Server::ALLOWED_METHODS`, and passes the rest to the MCP gem.
2. The gem routes `tools/call` to the tool class.
3. The tool validates arguments through `QueryBuilder`, which raises
   `InvalidArgument` naming what *is* valid, so the assistant can retry.
4. `SearchRunner` runs the parameters through the same Blacklight path
   `CatalogController` uses, with shorter Solr timeouts — an assistant that
   gets no answer retries, and a slow query holding a Puma thread is how MCP
   traffic would starve the human catalog.
5. A presenter turns the response into the tool's JSON reply.

## Two things to know before editing

**Facet names.** The tools speak the labels the catalog shows a person
("Subject: Region", "Call Number") and translate to Solr fields on the way
through, so an assistant never repeats `fast_geo_facet` back to a student.
`FacetNames` owns both directions.

**Nothing keeps a second list.** Search fields, facets, sorts and ranges are
read from `catalog_controller.rb` through `CatalogOptions`, and the landing page
builds its tool list from `Server.tools`.

## Adding a tool

1. Add `tools/your_tool.rb` inheriting `Tools::Base`, with `tool_name`,
   `read_only`, a `description` and an `input_schema`. Use `filter_properties`
   if it searches.
2. List it in `Server.tools`.
3. Add its spec, and add the name to the tool-list specs (`server_spec.rb`,
   `mcp_schema_spec.rb`, `spec/requests/mcp_endpoint_spec.rb`) — they enumerate
   what clients have been told about, so they fail until you do.

Bump `VERSION` while you are there. Nothing reads it, but it is what tells a
human which build answered.

The console needs no JavaScript for a new tool: it builds a form from the schema
and prints the reply as JSON. For a nicer result display, add a class in
`tools.js` — see
[MCP_CONSOLE_README.md](../assets/javascripts/mcp/console/MCP_CONSOLE_README.md).

**Clients read `tools/list` once, at connect.** The transport is stateless, so
there is no `list_changed` notification to send — a new tool reaches an
assistant only when it reconnects. Two things soften that:
`describe_search_options` reports the running version and tool names, and a
`tools/call` naming a tool this server does not have gets an error saying so and
telling the caller to reconnect.

## Environment

| Variable | Default | Effect |
| --- | --- | --- |
| `MCP` | on | `MCP=false` makes `/mcp` and `/mcp/console` 404, as if never added |
| `MCP_CONSOLE` | development only | `true` anywhere, `false` nowhere |
| `MCP_CATALOG_URL` | `https://catalog.library.cornell.edu` | where the links in a reply point |
| `MCP_SOLR_FACETS_DISPLAY` | off | `true` advertises raw Solr facet fields |
| `MCP_SOLR_TIMEOUT` | 5 | seconds a request waits on Solr |
| `MCP_SOLR_OPEN_TIMEOUT` | 2 | seconds to open that connection |
| `MCP_RATE_LIMIT` | 120 | requests per caller; `0` turns the limit off |
| `MCP_RATE_LIMIT_PERIOD` | 60 | seconds those are counted over |

Only the literal `true` and `false` are read. All of it needs a restart to
change; to stop traffic faster, block `/mcp` at the WAF — that also keeps the
requests off the Puma threads, which none of these can do.

The `/.well-known` discovery routes sit outside the `MCP` switch deliberately:
they answer a flat 404 either way, so remote clients can learn this server needs
no login without Rails raising a routing error.

## Elsewhere

| | |
| --- | --- |
| `app/controllers/mcp_controller.rb` | the endpoint |
| `app/controllers/mcp_console_controller.rb`, `app/views/mcp_console/` | the console page |
| [`app/assets/javascripts/mcp/console/`](../assets/javascripts/mcp/console/MCP_CONSOLE_README.md) | its JavaScript |
| `config/routes.rb` | routes, constrained on the switches above |
| `spec/mcp/`, `spec/requests/mcp_endpoint_spec.rb`, `spec/requests/mcp_console_spec.rb` | specs |
