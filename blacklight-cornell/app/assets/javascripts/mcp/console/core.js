// Shared foundation for the MCP console.
//
// This file creates the `window.McpConsole` namespace used by the other files.
// It provides small helpers for building HTML, keeps references to the console's
// page elements in one place, and stores tool calls in the URL so they can be
// shared. It does not make MCP requests or contain tool-specific behavior.

(function () {
    'use strict';

    const App = (window.McpConsole = window.McpConsole || {});

    // Small helpers for common DOM elements.
    class Dom {
        static text(tag, className, content) {
            const el = document.createElement(tag);
            if (className) {
                el.className = className;
            }
            el.textContent = content;
            return el;
        }

        // Wraps a control in a grid column.
        static cell(className, child) {
            const el = document.createElement('div');
            el.className = className;
            el.appendChild(child);
            return el;
        }

        // Builds a dropdown with optional display labels.
        static picker(values, chosen, className, labels) {
            const el = document.createElement('select');
            el.className = className;
            values.forEach(function (value) {
                el.appendChild(new Option((labels || {})[value] || value, value));
            });
            if (chosen && Dom.hasOption(el, String(chosen))) {
                el.value = String(chosen);
            }
            return el;
        }

        static hasOption(select, value) {
            return Array.prototype.some.call(select.options, (option) => option.value === value);
        }

        static selectedValues(select) {
            return Array.prototype.filter.call(select.options, (option) => option.selected)
                .map((option) => option.value);
        }

        // Uses the catalog's Font Awesome 4.7 icons.
        static icon(glyph, extra) {
            const el = document.createElement('i');
            el.className = 'fa fa-' + glyph + (extra ? ' ' + extra : '');
            el.setAttribute('aria-hidden', 'true');
            return el;
        }

        static button(className, glyph, label) {
            const el = document.createElement('button');
            el.type = 'button';
            el.className = className;
            if (glyph) {
                el.appendChild(Dom.icon(glyph, label ? 'me-1' : ''));
            }
            if (label) {
                el.appendChild(document.createTextNode(label));
            }
            return el;
        }

        static number(value) {
            return typeof value === 'number' ? value.toLocaleString() : value;
        }

        static cssEscape(value) {
            return value.replace(/["\\]/g, '\\$&');
        }
    }

    // Stores the page elements used by the console.
    class ConsolePage {
        constructor() {
            this.endpoint = new URL('/mcp', window.location.href).toString();

            this.tool = document.getElementById('tool');
            this.description = document.getElementById('tool-desc');
            this.examples = document.getElementById('examples');
            this.form = document.getElementById('args');
            this.runButton = document.getElementById('run');
            this.curlButton = document.getElementById('curl');
            this.status = document.getElementById('status');
            this.results = document.getElementById('results');
            this.raw = document.getElementById('raw');
            this.rawPanel = document.getElementById('raw-wrap');
            this.rawLabel = document.getElementById('raw-label');
            this.rawFormat = document.getElementById('raw-format');
            this.availability = document.getElementById('availability');
            this.availabilitySwitch = document.getElementById('availability-switch');

            document.getElementById('endpoint').textContent = this.endpoint;

            // Saves the button content before showing a spinner.
            this.runLabel = this.runButton.innerHTML;
        }

        // Updates the status line.
        say(message, isError) {
            this.status.textContent = message || '';
            this.status.className = 'small ' + (isError ? 'text-danger' : 'text-body-secondary');
        }

        working(isWorking, label) {
            this.runButton.disabled = isWorking;
            this.runButton.innerHTML = isWorking
                ? '<span class="spinner-border spinner-border-sm me-2" aria-hidden="true"></span>' + label
                : this.runLabel;
        }

        clearResults() {
            this.results.innerHTML = '';
        }
    }

    App.Dom = Dom;
    App.ConsolePage = ConsolePage;
})();
// Saves a tool call in the URL for sharing.

(function () {
    'use strict';

    const App = window.McpConsole;

    class UrlState {
        save(toolName, toolArguments) {
            try {
                window.history.replaceState(null, '',
                    '#' + encodeURIComponent(JSON.stringify({tool: toolName, args: toolArguments})));
            } catch (e) {
                // The console still works if the URL cannot be updated.
            }
        }

        read() {
            if (!window.location.hash) {
                return null;
            }
            try {
                return JSON.parse(decodeURIComponent(window.location.hash.slice(1)));
            } catch (e) {
                return null;
            }
        }
    }

    App.UrlState = UrlState;
})();
