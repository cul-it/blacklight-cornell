// Main controller and startup code for the MCP console.
//
// This file connects the page, MCP client, schema form, tool displays, examples,
// and URL state. On startup it loads `tools/list`, fills the tool menu, and
// restores a shared call when one is present. It also handles Run, Try, Enter,
// and Copy curl actions, then sends each result to the selected tool's display.
// The final lines create the application after all earlier files have loaded.

(function () {
    'use strict';

    // application.js ends with `require_tree .`, which loads this directory
    // alphabetically -- app, client, core, form, tools -- not in the order the
    // manifest lists. So every file has to create the namespace rather than
    // assume an earlier one did, and must not read another file's classes at
    // load time. (On the console page the manifest order applies and all of
    // this is moot; it is the catalog pages that see the alphabet.)
    const App = (window.McpConsole = window.McpConsole || {});

    class ToolExamples {
        constructor(app) {
            this.app = app;
            this.el = app.page.examples;
        }

        show(tool) {
            this.el.innerHTML = '';

            const examples = tool.examples();
            if (!examples.length) {
                return;
            }

            const hint = App.Dom.text('span', 'small text-body-secondary me-1', ' Try:');
            hint.insertBefore(App.Dom.icon('lightbulb-o'), hint.firstChild);
            this.el.appendChild(hint);

            examples.forEach((example) => {
                const button = App.Dom.button('btn btn-sm btn-outline-secondary rounded-pill');
                button.textContent = example.label;
                button.addEventListener('click', () => this.apply(example, button));
                this.el.appendChild(button);
            });
        }

        apply(example, button) {
            if (!example.resolve) {
                this.app.runWithArguments(example.args);
                return;
            }

            const label = button.innerHTML;
            button.disabled = true;
            button.innerHTML = '<span class="spinner-border spinner-border-sm" aria-hidden="true"></span>';
            this.app.page.say(example.finding || 'finding an example\u2026');

            example.resolve().then((args) => {
                if (!args) {
                    throw new Error('the catalog returned nothing to use as an example');
                }
                this.app.runWithArguments(args);
            }).catch((error) => {
                this.app.page.say(error.message, true);
            }).then(() => {
                button.disabled = false;
                button.innerHTML = label;
            });
        }
    }

    App.ToolExamples = ToolExamples;
})();
// Starts the console and handles user actions.

(function () {
    'use strict';

    const App = (window.McpConsole = window.McpConsole || {});

    class ConsoleApp {
        constructor() {
            this.page = new App.ConsolePage();
            this.client = new App.McpClient(this.page);
            this.facetValueLoader = new App.FacetValueLoader(this.client);
            this.toolForm = new App.ToolForm(this.page, this.facetValueLoader);
            this.toolExamples = new App.ToolExamples(this);
            this.urlState = new App.UrlState();

            this.toolsByName = {};
            this.toolNames = [];

            // Record IDs from the latest search.
            this.recentIds = [];
        }

        hasTool(name) {
            return !!this.toolsByName[name];
        }

        getTool(name) {
            return this.toolsByName[name];
        }

        get selectedTool() {
            return this.getTool(this.page.tool.value);
        }

        callTool(toolName, toolArguments, options) {
            return this.client.callTool(toolName, toolArguments, options);
        }

        // Whether a search should follow itself with check_availability. Off
        // by default: a search you ran to test the search endpoint should put
        // one request in the log, not two.
        get availabilityWanted() {
            return !!(this.page.availability && this.page.availability.checked);
        }

        rememberRecordIds(docs) {
            this.recentIds = docs.map((doc) => String(doc.id)).filter(Boolean);
        }

        // Gets real record IDs for examples.
        sampleRecordIds(count) {
            if (this.recentIds.length >= count) {
                return Promise.resolve(this.recentIds.slice(0, count));
            }

            // A small search avoids scanning the full index.
            return this.callTool('search', {query: 'library', per_page: count}, {silent: true})
                .then((payload) => (payload.documents || []).map((doc) => String(doc.id)));
        }

        selectTool(name) {
            const tool = this.getTool(name);
            if (!tool) {
                return;
            }

            this.page.tool.value = name;
            this.page.description.textContent = tool.description;

            // Only the tools that show records have anything to check.
            if (this.page.availabilitySwitch) {
                this.page.availabilitySwitch.hidden = !tool.showsAvailability;
            }

            this.toolForm.build(tool);
            this.toolExamples.show(tool);
        }

        runSelectedTool() {
            const tool = this.selectedTool;
            if (!tool) {
                return;
            }

            let toolArguments;
            try {
                toolArguments = this.toolForm.readArguments();
            } catch (e) {
                this.page.say(e.message, true);
                return;
            }

            this.urlState.save(tool.name, toolArguments);
            this.page.working(true, 'Running');
            this.page.say('running\u2026');
            const started = performance.now();

            this.callTool(tool.name, toolArguments).then((payload) => {
                this.page.say('done in ' + Math.round(performance.now() - started) + ' ms');
                this.page.clearResults();
                tool.render(payload);
            }).catch((error) => {
                this.page.say(error.message, true);
                this.page.clearResults();
            }).then(() => {
                this.page.working(false);
            });
        }

        // Runs an example for the selected tool.
        runWithArguments(toolArguments) {
            this.toolForm.writeArguments(toolArguments || {});
            this.runSelectedTool();
        }

        // Selects a tool, fills its form, and runs it.
        runTool(name, toolArguments) {
            if (!this.hasTool(name)) {
                return;
            }
            this.selectTool(name);
            this.runWithArguments(toolArguments);
        }

        copyCurlCommand() {
            let toolArguments;
            try {
                toolArguments = this.toolForm.readArguments();
            } catch (e) {
                this.page.say(e.message, true);
                return;
            }

            const body = JSON.stringify({
                jsonrpc: '2.0', id: 1, method: 'tools/call',
                params: {name: this.page.tool.value, arguments: toolArguments}
            });
            const command = "curl -s -X POST " + this.page.endpoint +
                " \\\n  -H 'Content-Type: application/json'" +
                " \\\n  -H 'Accept: application/json, text/event-stream'" +
                " \\\n  -d '" + body.replace(/'/g, "'\\''") + "'";

            navigator.clipboard.writeText(command).then(() => {
                this.page.say('curl command copied');
            }).catch(() => {
                this.page.say('could not copy \u2014 the command is in the panel below', true);
                this.client.showPlain(command);
            });
        }

        start() {
            this.bindEvents();
            this.page.say('asking the endpoint what it can do\u2026');

            return this.client.request('tools/list').then((result) => {
                this.loadTools(result.tools || []);
                this.page.runButton.disabled = false;
                this.page.say(this.toolNames.length + ' tools available');
                this.restoreUrlCall();
            }).catch((error) => {
                this.page.say('could not reach the endpoint: ' + error.message, true);
            });
        }

        bindEvents() {
            this.page.tool.addEventListener('change', () => this.selectTool(this.page.tool.value));
            this.page.runButton.addEventListener('click', () => this.runSelectedTool());
            this.page.curlButton.addEventListener('click', () => this.copyCurlCommand());

            if (this.page.rawFormat) {
                this.page.rawFormat.addEventListener('change', () => this.client.redraw());
            }

            // Enter submits the tool instead of leaving the page.
            this.page.form.addEventListener('submit', (event) => {
                event.preventDefault();
                this.runSelectedTool();
            });
        }

        // Builds one view for each tool returned by tools/list.
        loadTools(toolDefinitions) {
            this.page.tool.innerHTML = '';

            toolDefinitions.forEach((toolDefinition) => {
                const tool = App.Tool.build(toolDefinition, this);
                this.toolsByName[tool.name] = tool;
                this.toolNames.push(tool.name);
                this.page.tool.appendChild(new Option(tool.label, tool.name));
            });

            if (!this.toolNames.length) {
                throw new Error('the endpoint reported no tools');
            }
        }

        // Restores a tool call from the URL.
        restoreUrlCall() {
            const state = this.urlState.read();
            if (state && this.hasTool(state.tool)) {
                this.runTool(state.tool, state.args || {});
            } else {
                this.selectTool(this.toolNames[0]);
            }
        }
    }

    App.ConsoleApp = ConsoleApp;

    // Only on the page this is the client for.
    //
    // application.js ends with `require_tree .`, so every file in here is also
    // bundled into every catalog page -- the same as aeon.js and
    // search_form.js. ConsolePage reads the console's own elements the moment
    // it is built, so without this check it throws on load everywhere else.
    // Whatever else these files grow, they have to stay inert off this page.
    if (document.getElementById('tool')) {
        App.app = new ConsoleApp();
        App.app.start();
    }
})();
