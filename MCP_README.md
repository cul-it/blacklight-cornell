# Blacklight-Cornell MCP

An in-process [Model Context Protocol](https://modelcontextprotocol.io)
server that lets Claude (Desktop, Code, or any other MCP client) search
the Cornell University Library catalog in natural language.

The server lives inside the Rails app at `app/mcp/` and is mounted at
`/mcp`. Tools talk to `Blacklight::SearchService` directly — no separate deploy

## Description

Library catalog search is a classic case where users know what they want
but don't know how to phrase it for a faceted search engine. The MCP
surface lets Claude do query reformulation (vocabulary mapping, facet
selection, multi-pass strategies) and synthesize results, while Solr
keeps doing what it's good at — ranked retrieval over structured
bibliographic data. No vector index, no separate semantic layer.

It's also a low-risk way to expose catalog search to any agentic client
that speaks MCP, without inventing a new HTTP API.

## Tools

| Tool              | Purpose                                                                  |
| ----------------- | ------------------------------------------------------------------------ |
| `catalog_search`  | Search the Solr catalog. Simple (`query`) or advanced (`advanced.rows`). |
| `describe_facets` | Lists every facet field + a live sample of values, so Claude can filter. |

`catalog_search` exposes named parameters for every user-facing facet
(format, subject, genre, language, author, etc.) plus `pub_date_range`,
`online_only`, a generic `facets` catch-all, and a multi-row `advanced`
mode supporting AND/OR/NOT between rows and All/Any/Phrase/Begins With
match types per row. The facet, search-field, and sort lists are built
from `CatalogController.blacklight_config` at boot, so the tool stays
in sync with `catalog_controller.rb` automatically.

## Running it locally

### 1. Start the Rails app

The MCP endpoint is just a route on the dev server.

```bash
./build.sh -dr rails_env/YOUR_DEV_ENV_FILE   # first time
./run.sh   -dr rails_env/YOUR_DEV_ENV_FILE
```

The app comes up at `http://localhost:9292` and the MCP endpoint at
`http://localhost:9292/mcp`. Quick MCP test:

```bash
curl -s -X POST http://localhost:9292/mcp \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | jq .
```

You should see `catalog_search` and `describe_facets` in the response.

### 2. Wire it into Claude Desktop

Claude Desktop only speaks **stdio** MCP, so an HTTP endpoint needs a
small stdio↔HTTP bridge. The easiest is
[`mcp-remote`](https://www.npmjs.com/package/mcp-remote), which `npx`
can run on demand (no global install).

**Prerequisites:** Node on `PATH` (`which npx` should return a path; if
not, `brew install node` (or use your prefered node manager)).

Open Claude Desktop's config file:

- Stock Claude Desktop: `~/Library/Application Support/Claude/claude_desktop_config.json`
- Claude-3p: `~/Library/Application Support/Claude-3p/claude_desktop_config.json`

Add an `mcpServers` block (merge with any existing top-level keys —
don't replace the whole file):

```json
{
  "mcpServers": {
    "blacklight-cornell": {
      "command": "npx",
      "args": ["-y", "mcp-remote", "http://localhost:9292/mcp", "--allow-http"]
    }
  }
}
```

- `--allow-http` is required because `mcp-remote` rejects non-HTTPS URLs
  by default.
- The first launch downloads `mcp-remote` via `npx` (a few seconds).

**Restart Claude Desktop** to pick up the config change. In a chat,
the catalog tools should now appear under the tools/connectors menu.

### 3. Wire it into Claude Code

```bash
claude mcp add --transport http blacklight-cornell http://localhost:9292/mcp
```

Claude Code speaks Streamable HTTP natively, so no bridge needed.

## Hot reload in development

Editing `app/mcp/blacklight_mcp/tools/*.rb` or
`app/controllers/catalog_controller.rb` does **not** require a server
restart. The mount uses an indirect lambda
(`app/mcp/blacklight_mcp.rb`'s `ENDPOINT`), and a `to_prepare` hook
(`config/initializers/blacklight_mcp_reload.rb`) busts the memoized
rack app whenever Rails reloads code. The next request rebuilds the
MCP server against the freshly-loaded classes.

Restart is still needed for:
- `config/routes.rb` changes
- `config/initializers/blacklight_mcp_reload.rb` changes
- `Gemfile` changes


## File layout

```
blacklight-cornell/
├── app/mcp/
│   ├── blacklight_mcp.rb                 # module + Rack endpoint + reset!
│   └── blacklight_mcp/
│       └── tools/
│           ├── catalog_search.rb         # simple + advanced search
│           └── describe_facets.rb        # facet introspection
├── config/
│   ├── routes.rb                         # mount BlacklightMcp::ENDPOINT, at: "/mcp"
│   └── initializers/
│       └── blacklight_mcp_reload.rb      # to_prepare → BlacklightMcp.reset!
```
