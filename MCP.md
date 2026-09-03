# MCP server

A read-only [Model Context Protocol](https://modelcontextprotocol.io) endpoint at
`/mcp`. Point an AI assistant at it and it can search the catalog.

| Environment | URL |
| ----------- | --- |
| Development | `http://localhost:9292/mcp` |
| Production  | `https://catalog.library.cornell.edu/mcp` |


## Tools

| Tool | Needs | What it does |
| ---- | ----- | ------------ |
| `search` | — | One search box: a query, a field, plus facets, year range and sort |
| `advanced_search` | `rows` | The `/advanced` form: several rows joined by AND/OR/NOT |
| `describe_search_options` | — | Every search field, facet and sort this catalog has, with example values |
| `facet_values` | `field` | All values for one facet, with counts -- to find exact spellings |
| `get_record` | `id` | The full record for one id, every stored field |
| `fetch` | `id` | The same record as readable text -- what ChatGPT deep research expects |
| `check_availability` | `ids` | Online links, which library holds it, call number, copies on the shelf |

Start with `describe_search_options` if you are unsure what to ask for.

## Connecting an assistant

Swap the URL for `http://localhost:9292/mcp` when working locally.

Every client uses a slightly different key for the same thing — `mcpServers`,
`servers`, `mcp_servers` — so for anything not shown here, follow its own
instructions in [Reference](#reference) below.

**Claude Code** -- one command:

```bash
claude mcp add --transport http cornell-library-catalog https://catalog.library.cornell.edu/mcp
```

**Claude Desktop** -- Settings → Connectors → Add custom connector, and paste the
URL. If your version has no such option, use the `mcp-remote` bridge below.

**Cursor** (`~/.cursor/mcp.json`) **and Windsurf** (`~/.codeium/windsurf/mcp_config.json`):

```jsonc
{
  "mcpServers": {
    "cornell-library-catalog": { "url": "https://catalog.library.cornell.edu/mcp" }
  }
}
```

**VS Code / Copilot** uses `servers` and wants an explicit type, in `.vscode/mcp.json`:

```jsonc
{
  "servers": {
    "cornell-library-catalog": { "type": "http", "url": "https://catalog.library.cornell.edu/mcp" }
  }
}
```

**Any client that only launches commands**, or refuses a plain `http://` address
-- which covers local development -- bridges through
[`mcp-remote`](https://github.com/geelen/mcp-remote):

```jsonc
{
  "mcpServers": {
    "cornell-library-catalog": {
      "command": "npx",
      "args": ["-y", "mcp-remote", "http://localhost:9292/mcp", "--allow-http"]
    }
  }
}
```

**OpenAI Codex CLI** -- runs on your machine, so it can reach localhost:

```bash
codex mcp add cornell-library-catalog --url https://catalog.library.cornell.edu/mcp
```

Codex keeps its config in TOML, not JSON, at `~/.codex/config.toml`:

```toml
[mcp_servers.cornell-library-catalog]
url = "https://catalog.library.cornell.edu/mcp"
```

`codex mcp list` shows it, `codex mcp remove cornell-library-catalog` undoes it.
Auth listing as "Unsupported" is correct -- this server needs no login.

**ChatGPT** connects from OpenAI's servers rather than your machine, so it needs a
public HTTPS address. `http://localhost:9292/mcp` can never work, and production
is behind the WAF described above, so **ChatGPT cannot reach this server today** --
use the Codex CLI instead. Once production is opened up, add it under
Settings → Connectors as a custom MCP connector (paid plans, developer mode).

Deep research connectors specifically want a `search` tool and a `fetch` tool,
and `fetch` must return `id`, `title`, `text`, `url` and `metadata`. This server
has both, so it should qualify -- though that pairing has not been tested against
ChatGPT itself, only against the documented shape.


## Reference

**The protocol itself**

- [What MCP is](https://modelcontextprotocol.io/docs/getting-started/intro) — the plain-language introduction
- [Specification](https://modelcontextprotocol.io/specification/2025-06-18) — and the
  [transport chapter](https://modelcontextprotocol.io/specification/2025-06-18/basic/transports),
  which is what this endpoint implements
- [How tools work](https://modelcontextprotocol.io/docs/concepts/tools)
- [Every known MCP client](https://modelcontextprotocol.io/clients) — check here first if
  yours is not listed below

**Connecting each assistant**

| Assistant | Their instructions |
| --------- | ------------------ |
| Claude Code | [MCP in Claude Code](https://docs.claude.com/en/docs/claude-code/mcp) |
| Claude Desktop | [Custom integrations using remote MCP](https://support.claude.com/en/articles/11175166-about-custom-integrations-using-remote-mcp) |
| Claude API | [MCP connector](https://docs.claude.com/en/docs/agents-and-tools/mcp-connector) |
| OpenAI Codex CLI | [MCP in Codex](https://developers.openai.com/codex/mcp/) |
| ChatGPT | [MCP and deep research connectors](https://platform.openai.com/docs/mcp) |
| Cursor | [Model Context Protocol](https://docs.cursor.com/context/model-context-protocol) |
| VS Code / Copilot | [Use MCP servers](https://code.visualstudio.com/docs/copilot/chat/mcp-servers) |
| Windsurf | [MCP in Cascade](https://docs.windsurf.com/windsurf/cascade/mcp) |
| Gemini CLI | [MCP servers](https://github.com/google-gemini/gemini-cli/blob/main/docs/tools/mcp-server.md) |
| Zed | [MCP](https://zed.dev/docs/ai/mcp) |

**Bridging a client that cannot speak HTTP**

- [`mcp-remote`](https://github.com/geelen/mcp-remote) — turns a stdio-only client into
  an HTTP one, and the reason `--allow-http` is needed for `localhost`

## Limits

120 requests per caller per minute. Tune with `MCP_RATE_LIMIT` and
`MCP_RATE_LIMIT_PERIOD`; `MCP_RATE_LIMIT=0` turns it off.

Where the count is kept depends on whether `REDIS_SESSION_HOST` is set -- the same
variable the app already uses for sessions:

| `REDIS_SESSION_HOST` | Count is kept | Effect |
| -------------------- | ------------- | ------ |
| set | in Redis | one shared allowance for every task |
| not set | in the process | each task gets its own allowance, so the real ceiling is 120 × number of tasks |

Either way the limit applies; without Redis it is just not a single global count.
The app logs which one it picked at startup, so you can check rather than guess:

```
[MCP] rate limit 120 requests per 60s per caller, counted in Redis and shared by every task
```

If Redis is configured but unreachable, the limit is skipped rather than blocking
every search.

## How it works

Tools never build Solr queries. They turn their arguments into the same
parameters the catalog's own search forms submit, then hand those to the
catalog's normal search code -- so an MCP search and the same search typed into
the website produce an identical Solr query, which
`spec/mcp/blacklight_mcp/solr_query_spec.rb` proves against a real
advanced-search URL. What the tools accept is read from the catalog's live
settings, so adding a facet or sort in `catalog_controller.rb` exposes it here.

## Read-only

Every tool is marked `readOnlyHint`. The server offers tools and nothing else,
refuses any request outside `BlacklightMcp::Server::ALLOWED_METHODS`, and runs
on `ActionController::API` -- no session, no CSRF token, no views. There is no
code path from any tool to a Solr update.

Code is in `blacklight-cornell/app/mcp/blacklight_mcp/`, specs in
`blacklight-cornell/spec/mcp/` and
`blacklight-cornell/spec/requests/mcp_endpoint_spec.rb`.
