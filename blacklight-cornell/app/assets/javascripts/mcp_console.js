// Sprockets entry point for the MCP console.
//
// These files share `window.McpConsole`, so their order is important. Shared
// helpers load first, followed by the client, forms, tool displays, and the main
// application. `app.js` starts the console after every dependency is available.
//= require mcp/console/core
//= require mcp/console/client
//= require mcp/console/form
//= require mcp/console/tools
//= require mcp/console/app
