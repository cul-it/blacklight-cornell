// MCP and JSON-RPC communication for the browser console.
//
// `McpClient` sends requests to the page's `/mcp` endpoint and accepts either a
// JSON response or an MCP event-stream response. It unwraps tool result text,
// turns JSON text into normal JavaScript data, reports server errors, and keeps
// the raw request and response available for inspection. Background requests
// can be marked `silent` so they do not replace the user's visible request.

(function () {
    'use strict';

    const App = window.McpConsole;

    class McpClient {
        constructor(page) {
            this.page = page;
            this.nextId = 1;

            // Keeps the last visible call for the Format switch.
            this.last = null;
        }

        // Sends one JSON-RPC request. `silent` requests do not replace the raw panel.
        request(method, params, options) {
            const requestBody = {jsonrpc: '2.0', id: this.nextId++, method: method};
            if (params) {
                requestBody.params = params;
            }

            return fetch(this.page.endpoint, {
                method: 'POST',
                headers: {'Content-Type': 'application/json', 'Accept': 'application/json, text/event-stream'},
                body: JSON.stringify(requestBody)
            }).then((response) => response.text().then((text) => {
                const responseBody = McpClient.parse(text);
                if (!(options && options.silent)) {
                    this.show(requestBody, responseBody || text);
                }
                if (!response.ok && !responseBody) {
                    throw new Error('HTTP ' + response.status);
                }
                if (!responseBody) {
                    throw new Error('the endpoint sent something that is not JSON-RPC');
                }
                if (responseBody.error) {
                    throw new Error(responseBody.error.message || 'the endpoint returned an error');
                }
                return responseBody.result;
            }));
        }

        // Returns the JSON stored in the tool's first text block.
        callTool(toolName, toolArguments, options) {
            const params = {name: toolName, arguments: toolArguments};
            return this.request('tools/call', params, options).then(function (result) {
                const text = result && result.content && result.content[0] ? result.content[0].text : '';
                if (result && result.isError) {
                    throw new Error(text || 'the tool reported an error');
                }
                try {
                    return JSON.parse(text);
                } catch (e) {
                    return {text: text};
                }
            });
        }

        static parse(text) {
            try {
                return JSON.parse(text);
            } catch (e) { /* Try SSE next. */
            }

            const frame = text.split('\n').filter((line) => line.indexOf('data:') === 0)
                .map((line) => line.slice(5).trim()).join('');
            try {
                return JSON.parse(frame);
            } catch (e) {
                return null;
            }
        }

        show(request, response) {
            this.page.rawPanel.hidden = false;

            // Labels the hidden panel with the request name.
            if (this.page.rawLabel) {
                let label = request.method;
                if (request.params && request.params.name) {
                    label += ' ' + request.params.name;
                }
                this.page.rawLabel.textContent = label;
            }

            this.last = {request: request, response: response};
            this.redraw();
        }

        // Shows plain text when copying is unavailable.
        showPlain(body) {
            this.page.rawPanel.hidden = false;
            this.last = null;
            this.page.raw.textContent = body;
        }

        redraw() {
            if (!this.last) {
                return;
            }

            let response = this.last.response;
            if (this.page.rawFormat && this.page.rawFormat.checked) {
                response = McpClient.expand(response);
            }

            this.page.raw.textContent = '\u2192 request\n' + JSON.stringify(this.last.request, null, 2) +
                '\n\n\u2190 response\n' +
                (typeof response === 'string' ? response : JSON.stringify(response, null, 2));
        }

        // Expands JSON text blocks so they are easier to read.
        static expand(response) {
            if (!response || typeof response === 'string' ||
                !response.result || !Array.isArray(response.result.content)) {
                return response;
            }

            const copy = JSON.parse(JSON.stringify(response));
            copy.result.content = copy.result.content.map(function (block) {
                if (block && typeof block.text === 'string') {
                    try {
                        block.text = JSON.parse(block.text);
                    } catch (e) { /* Keep non-JSON text unchanged. */
                    }
                }
                return block;
            });
            return copy;
        }
    }

    App.McpClient = McpClient;
})();
