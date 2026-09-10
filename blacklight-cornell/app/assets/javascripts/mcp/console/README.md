# MCP console JavaScript

This directory contains the browser code for the MCP console. The console asks
the server for its tools, builds forms from their schemas, runs tool calls, and
displays the results.

Sprockets loads the files through `app/assets/javascripts/mcp_console.js`. The
order in that manifest matters because these files share the
`window.McpConsole` namespace.

## Structure

```text
console/
├── core.js     DOM helpers, page elements, and URL state
├── client.js   MCP requests and raw JSON-RPC output
├── form.js     All schema-based form controls
├── tools.js    Tool examples and result displays
└── app.js      Try buttons, startup, and user actions
```

## Request flow

1. `ConsoleApp` asks for `tools/list` through `McpClient`.
2. `ToolForm` builds controls from each tool's `inputSchema`.
3. The user runs a `tools/call` request.
4. The matching `Tool` class displays the result.
5. Unknown tools use the default JSON display in `tools.js`.

## Naming

- Tool sections and classes use the exact MCP tool name.
- Tool classes use PascalCase plus `Tool`: `CheckAvailabilityTool`.
- Each tool registers its exact MCP name:

  ```javascript
  App.Tool.register('check_availability', CheckAvailabilityTool);
  ```

- Shared classes describe their role, such as `McpClient` and `ToolForm`.

## Adding a tool

A new server tool already gets a schema form and JSON result display. No custom
JavaScript is required.

For custom examples or result markup, update `tools.js`:

1. Extend `App.Tool` or another suitable tool class.
2. Register the exact name returned by `tools/list`.

Keep shared behavior in the base `Tool` class. Keep each tool's code together.
