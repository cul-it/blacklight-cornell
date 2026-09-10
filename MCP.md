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
variable the app already uses for sessions (Redis is a future implementaion):

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

## Console

`/mcp/console` is a browser MCP client for this endpoint — a development tool for
testing it and showing people what it does. Pick a tool, fill in the form, see
the results rendered, with the raw JSON-RPC underneath and a button to copy the
equivalent `curl`.

Getting started with it:

- Every tool has one-click **Try** examples, so there is something to run before
  you know what any of the arguments mean. The ones for tools that need a record
  id (`get_record`, `fetch`, `check_availability`) go and find a real record
  first — reusing the ids from your last search if there was one — so no bib
  number is ever hardcoded and nothing rots when the index is rebuilt.
  `spec/requests/mcp_console_spec.rb` fails if a tool ships with no example.
- Search results carry a **Full record** link, so reading a record does not mean
  copying an id and switching tools by hand.
- Arguments that are awkward as JSON get a builder instead of a text box:
  - **`rows`** (advanced search) is a row at a time — query, field, and how the
    words are matched, each a dropdown, with the boolean joining it to the row
    above. `rows` and `booleans` are one widget, so the two arrays cannot fall
    out of alignment: an empty row drops out and takes its operator with it.
  - **`filters` / `filters_all`** pick a facet, then a value — and the values are
    fetched from `facet_values`, with counts, so you cannot mistype one. A
    *Type a value* option covers anything past the first page. Two rows naming
    the same facet become one filter with two values, as ticking two boxes does
    on the site.
  - **`formats` / `languages`** are one facet each, so they get that facet's real
    values with counts, added one at a time. The schema says which facet with an
    `x-facet` annotation, so a client does not have to read it out of the prose.
  - **`date_range`** is a from/to pair of years.
- Whatever you run goes into the address bar, so a link to the console carries
  the call with it — useful for "try this" in a ticket.
- The tool dropdown shows each tool's own title next to its name.

The page *is* the client: it speaks JSON-RPC to `/mcp` with `fetch()` like any
other MCP client, and builds its forms from the schemas `tools/list` reports, so
a new tool or argument appears there without anyone editing it. Its styling and
behaviour live in the asset pipeline, not in the markup:

| File | What it is |
| ---- | ---------- |
| `app/assets/stylesheets/mcp.scss` | bundle for both MCP pages — `cornell/variables`, Bootstrap, Font Awesome, then `mcp/_landing` and `mcp/_console` |
| `app/assets/javascripts/mcp_console.js` | bundle for the console — `mcp/console.js` |

Both pages are built from **Bootstrap 5.3 and Font Awesome 4.7**, the same two
the catalog uses, and the bundle imports `cornell/variables` before Bootstrap
exactly as `application.css.scss` does — so `$danger` is Carnelian and a button
here matches a button in the catalog. The two `mcp/` partials hold only what
Bootstrap has no utility for (a page width, a `white-space: pre-wrap`, a
last-row border). Colour modes are compiled with `$color-mode-type: media-query`,
so the pages follow the reader's system theme without a switcher.

Both are standalone bundles (the pages render outside the Blacklight layout), so
both are listed in `config/initializers/assets.rb`. Every rule is scoped to
`body.mcp-landing` or `body.mcp-console`, so the bundle cannot restyle the
catalog if it is ever loaded elsewhere. **Adding an MCP asset means adding it to
that precompile list** — production runs with `config.assets.compile = false`, so
an unlisted asset is a 500 on these pages, not a missing stylesheet. There is no
server-side proxy, so nothing the console can reach is out of reach of an outside
client. Its calls count against the rate limit like anyone else's.

Where it exists:

| `MCP_CONSOLE` | Result |
| ------------- | ------ |
| unset (default) | on in development, **absent everywhere else** |
| `true` | on, wherever it is set |
| `false` | absent, development included |

Same spelling as `MCP`. Three states rather than two, because "not set" has to
mean something different from "set to false": unset follows the environment,
`false` is a decision. Anything that is neither word is treated as unset.

The route is constrained on that, so where the console is off the path is an
ordinary 404 — there is nothing there to find. `/mcp` links to it only where it
exists.

## date_range and ranges

`date_range` sets a start and end year on the publication-year facet. `ranges` is
the general form of the same thing for *other* range facets — and this catalog
has none: publication year is its only one, so `ranges` could only ever duplicate
`date_range`, and offering both invites the "appears in both" error for no gain.

So `ranges` is **not advertised** while that stays true. It is still accepted, so
a caller already sending it keeps working; configure a second range facet in
`catalog_controller.rb` and it starts being offered again on its own.
`spec/mcp/blacklight_mcp/mcp_schema_spec.rb` fails when that day comes, because
it is a new argument appearing on two published tools.

## Facet names

Facets are named the way the catalog names them -- `Language`, `Subject: Region`,
`Fiction/Non-Fiction` -- not by their Solr field (`language_facet`,
`fast_geo_facet`, `subject_content_facet`). Students should not have to learn the
catalog's internals to ask a question, and an assistant that says "I filtered by
fast_geo_facet" has leaked one.

```json
{ "query": "cholera", "filters": { "Library Location": ["Olin Library"] } }
```

The names come from the facet labels in `catalog_controller.rb`, so they match
the headings on the website and there is no second list to maintain. Rename a
facet heading and it is renamed here too.

Input is lenient: a caller may send the readable name in any case, or the Solr
field itself, so nothing written against the older vocabulary breaks. Only what
the endpoint *advertises* changes.

| Variable | Effect |
| -------- | ------ |
| unset (default) | tools advertise the readable names |
| `MCP_SOLR_FACETS_DISPLAY=true` | tools advertise the raw Solr field names |

Tool schemas are built when the app boots, so this takes effect on restart, not
per request.

One exception, by design: `search(explain: true)` returns the Solr parameters a
query would produce, Solr field names and all. That is the whole point of
`explain`, and it is a debugging affordance no student-facing assistant will
reach for.

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
