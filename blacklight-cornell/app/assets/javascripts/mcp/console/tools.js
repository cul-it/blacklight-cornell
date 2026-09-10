// Examples and result displays for MCP tools.
//
// The base `Tool` wraps a definition returned by `tools/list` and provides
// shared examples, result cards, record links, and availability details. Classes
// for known tools add useful examples or a result layout and register under the
// exact MCP tool name. A tool without a custom class still works: its schema is
// used for the form and its result is shown as formatted JSON.

(function () {
    'use strict';

    const App = window.McpConsole;
    const Dom = App.Dom;

    class Tool {
        // Links an MCP tool name to its display class.
        static register(name, klass) {
            Tool.registry[name] = klass;
        }

        // Builds the registered class or uses the default.
        static build(toolDefinition, app) {
            const klass = Tool.registry[toolDefinition.name] || Tool;
            return new klass(toolDefinition, app);
        }

        constructor(toolDefinition, app) {
            this.toolDefinition = toolDefinition;
            this.app = app;
        }

        get name() {
            return this.toolDefinition.name;
        }

        get description() {
            return (this.toolDefinition.description || '').trim();
        }

        get schema() {
            return this.toolDefinition.inputSchema || {};
        }

        get properties() {
            return this.schema.properties || {};
        }

        // Adds the readable MCP title to the tool name.
        get label() {
            const title = (this.toolDefinition.annotations || {}).title;
            return title ? this.name + ' \u2014 ' + title : this.name;
        }

        // Returns examples that can be built from the schema.
        examples() {
            return this.derivedExamples();
        }

        derivedExamples() {
            return this.facetExamples().concat(this.recordExamples());
        }

        // Builds examples from allowed facet names.
        facetExamples() {
            const field = this.properties.field;
            if (!field) {
                return [];
            }

            const fields = field.enum || [];
            const chosen = fields.indexOf('Format') !== -1 ? 'Format' : fields[0];
            if (!chosen) {
                return [];
            }

            return [
                {label: 'Values of ' + chosen, args: {field: chosen}},
                {label: 'The same, A to Z', args: {field: chosen, sort: 'index'}}
            ];
        }

        // Builds examples with real record IDs.
        recordExamples() {
            if (!this.app.hasTool('search')) {
                return [];
            }

            const from = this.app.recentIds.length ? 'your last search' : 'the catalog';
            const examples = [];

            if (this.properties.id) {
                examples.push({
                    label: 'A record from ' + from,
                    finding: 'finding a record to try\u2026',
                    resolve: () => this.app.sampleRecordIds(1)
                        .then((ids) => (ids.length ? {id: ids[0]} : null))
                });
            }

            if (this.properties.ids) {
                examples.push({
                    label: 'Three records from ' + from,
                    finding: 'finding records to try\u2026',
                    resolve: () => this.app.sampleRecordIds(3)
                        .then((ids) => (ids.length ? {ids: ids} : null))
                });
            }

            return examples;
        }

        // Shows plain JSON when a tool has no custom display.
        render(payload) {
            const box = this.panel();
            box.appendChild(this.pre(JSON.stringify(payload, null, 2)));
        }

        // Adds a result card and returns its body.
        panel() {
            const card = document.createElement('div');
            card.className = 'card mb-4';

            const body = document.createElement('div');
            body.className = 'card-body';
            card.appendChild(body);

            this.app.page.results.appendChild(card);
            return body;
        }

        // Builds a result card heading.
        summary(content) {
            return Dom.text('div', Tool.SUMMARY, content);
        }

        pre(content) {
            return Dom.text('pre', Tool.PRE, content);
        }

        note(content, className) {
            return Dom.text('p', 'small mb-0 ' + (className || 'text-body-secondary'), content);
        }

        // Builds a record row with its title and year.
        record(title, year, id) {
            const rec = document.createElement('div');
            rec.className = 'mcp-rec py-3 border-bottom';
            if (id !== undefined && id !== null) {
                rec.dataset.id = id;
            }

            const head = document.createElement('div');
            head.className = 'd-flex justify-content-between gap-3 align-items-baseline';
            head.appendChild(title);
            head.appendChild(Dom.text('div', 'small text-body-secondary text-nowrap', year || ''));
            rec.appendChild(head);

            return rec;
        }

        // Links the title when the record has a URL.
        recordTitle(doc) {
            const title = document.createElement('div');
            title.className = 'fw-semibold';

            if (doc.url) {
                const link = document.createElement('a');
                link.href = doc.url;
                link.target = '_blank';
                link.rel = 'noopener';
                link.textContent = doc.title || '(untitled)';
                title.appendChild(link);
            } else {
                title.textContent = doc.title || '(untitled)';
            }

            return title;
        }

        // Shows availability with text, color, and an icon.
        availabilityInto(el, record) {
            const on = record.available_now === true;
            const out = record.available_now === false;

            el.className = 'small mt-1 ' + (on ? 'text-success' : (out ? 'text-danger' : 'text-body-secondary'));
            el.innerHTML = '';
            el.appendChild(Dom.icon(on ? 'check-circle' : (out ? 'clock-o' : 'question-circle-o'), 'me-1'));
            el.appendChild(document.createTextNode(record.summary || 'No availability reported'));

            const where = (record.copies || []).map(
                (copy) => [copy.library, copy.call_number].filter(Boolean).join(' \u2014 ')
            ).filter(Boolean);

            if (where.length) {
                el.appendChild(Dom.text('div', 'text-body-secondary', where.join(' \u00b7 ')));
            }
        }
    }

    Tool.registry = {};

    Tool.SUMMARY = 'd-flex justify-content-between align-items-baseline ' +
        'border-bottom pb-2 mb-3 small text-body-secondary';

    Tool.PRE = 'bg-body-tertiary border rounded p-3 small mb-0 mt-2';

    App.Tool = Tool;
})();
// Displays search and advanced_search results.

(function () {
    'use strict';

    const App = window.McpConsole;
    const Dom = App.Dom;

    class SearchTool extends App.Tool {
        // Provides common search examples.
        examples() {
            return [
                {
                    label: 'Newest books by an author',
                    args: {query: 'stephen king', formats: ['Book'], sort: 'year descending', per_page: 5}
                },
                {
                    label: 'An exact title',
                    args: {query: 'never flinch', search_field: 'title', per_page: 5}
                },
                {
                    label: 'A subject, this decade',
                    args: {query: 'climate change', date_range: {begin: 2015, end: 2025}, per_page: 5}
                },
                {
                    label: 'Narrowed by a facet',
                    args: {query: 'jazz', filters: {Format: ['Book']}, per_page: 5}
                }
            ].concat(this.derivedExamples());
        }

        render(payload) {
            // Scoring details are clearer as JSON.
            if (payload.explain) {
                return super.render(payload);
            }

            const box = this.panel();
            const docs = payload.documents || [];

            const head = this.summary('');
            head.appendChild(Dom.text('span', '',
                Dom.number(payload.total) + ' result' + (payload.total === 1 ? '' : 's')));
            head.appendChild(Dom.text('span', '',
                'page ' + payload.page + ' of ' + Dom.number(payload.total_pages)));
            box.appendChild(head);

            if (!docs.length) {
                box.appendChild(this.note('Nothing matched. Try fewer filters, or a broader query.'));
                return;
            }

            this.app.rememberRecordIds(docs);
            docs.forEach((doc) => box.appendChild(this.card(doc)));
            this.enrich(docs);
        }

        card(doc) {
            const rec = this.record(this.recordTitle(doc), doc.publication_year, doc.id);

            const meta = [doc.author, doc.format, doc.call_number].filter(Boolean).join(' \u00b7 ');
            if (meta) {
                rec.appendChild(Dom.text('div', 'small text-body-secondary mt-1', meta));
            }

            const slot = document.createElement('div');
            slot.className = 'small mt-1 text-body-secondary';
            slot.dataset.slot = doc.id;
            rec.appendChild(slot);

            // Opens this result with a record tool.
            const reader = this.app.hasTool('fetch') ? 'fetch' : 'get_record';
            if (this.app.hasTool(reader)) {
                const button = Dom.button(
                    'btn btn-link btn-sm p-0 align-baseline text-decoration-none',
                    'file-text-o', 'Full record');
                button.addEventListener('click', () => {
                    this.app.runTool(reader, {id: String(doc.id)});
                });

                const actions = document.createElement('div');
                actions.className = 'mt-2 d-flex gap-3';
                actions.appendChild(button);
                rec.appendChild(actions);
            }

            return rec;
        }

        // Adds availability with a background tool call.
        enrich(docs) {
            const ids = docs.map((doc) => String(doc.id)).slice(0, 10);
            if (!ids.length || !this.app.hasTool('check_availability')) {
                return;
            }

            this.app.callTool('check_availability', {ids: ids}, {silent: true}).then((payload) => {
                (payload.records || []).forEach((record) => {
                    const slot = this.app.page.results.querySelector(
                        '[data-slot="' + Dom.cssEscape(String(record.id)) + '"]');
                    if (slot) {
                        this.availabilityInto(slot, record);
                    }
                });
            }).catch(() => {
                // Search results still work without availability.
            });
        }
    }

    App.SearchTool = SearchTool;
    App.Tool.register('search', SearchTool);
})();
// Adds examples for the advanced_search tool.

(function () {
    'use strict';

    const App = window.McpConsole;

    class AdvancedSearchTool extends App.SearchTool {
        examples() {
            return [
                {
                    label: 'Two terms, different fields',
                    args: {
                        rows: [{query: 'cholera', field: 'subject'}, {query: 'london', field: 'all_fields'}],
                        booleans: ['AND'], per_page: 5
                    }
                },
                {
                    label: 'One term but not another',
                    args: {
                        rows: [{query: 'shakespeare', field: 'author'}, {query: 'hamlet', field: 'title'}],
                        booleans: ['NOT'], per_page: 5
                    }
                }
            ].concat(this.derivedExamples());
        }
    }

    App.AdvancedSearchTool = AdvancedSearchTool;
    App.Tool.register('advanced_search', AdvancedSearchTool);
})();
// Displays results from the facet_values tool.

(function () {
    'use strict';

    const App = window.McpConsole;
    const Dom = App.Dom;

    class FacetValuesTool extends App.Tool {
        render(payload) {
            const box = this.panel();
            box.appendChild(this.summary(
                payload.facet + ' \u00b7 page ' + payload.page + (payload.has_more ? ' (more available)' : '')));

            const table = document.createElement('table');
            table.className = 'table table-sm align-middle mb-0';
            table.innerHTML = '<thead><tr><th>Value</th><th class="text-end">Records</th></tr></thead>';

            const body = document.createElement('tbody');
            (payload.values || []).forEach((entry) => {
                const row = document.createElement('tr');
                row.appendChild(Dom.text('td', '', entry.value));
                row.appendChild(Dom.text('td', 'text-end text-body-secondary', Dom.number(entry.count)));
                body.appendChild(row);
            });

            table.appendChild(body);
            box.appendChild(table);
        }
    }

    App.FacetValuesTool = FacetValuesTool;
    App.Tool.register('facet_values', FacetValuesTool);
})();
// Displays results from the check_availability tool.

(function () {
    'use strict';

    const App = window.McpConsole;
    const Dom = App.Dom;

    class CheckAvailabilityTool extends App.Tool {
        render(payload) {
            const records = payload.records || [];
            const box = this.panel();

            if (!records.length) {
                box.appendChild(this.note('No records came back.'));
            }

            records.forEach((record) => {
                const rec = this.record(
                    Dom.text('div', 'fw-semibold', record.title || record.id),
                    record.publication_year);

                const line = document.createElement('div');
                line.className = 'small mt-1 text-body-secondary';
                this.availabilityInto(line, record);
                rec.appendChild(line);

                (record.online_access || []).forEach((entry) => this.appendLink(rec, entry));
                (record.copies || []).forEach((copy) => this.appendItems(rec, copy));

                box.appendChild(rec);
            });

            if (payload.not_found && payload.not_found.length) {
                box.appendChild(this.note('No such record: ' + payload.not_found.join(', '), 'text-danger'));
            }
        }

        appendLink(rec, entry) {
            const link = document.createElement('a');
            link.href = entry.url;
            link.target = '_blank';
            link.rel = 'noopener';
            link.textContent = entry.description || entry.url;

            const line = document.createElement('div');
            line.className = 'small mt-1';
            line.appendChild(link);
            rec.appendChild(line);
        }

        // Lists each physical copy.
        appendItems(rec, copy) {
            if (!copy.items || !copy.items.length) {
                return;
            }

            const rows = copy.items.map((item) => [
                item.status, item.enumeration, item.copy ? 'copy ' + item.copy : null, item.loan_type
            ].filter(Boolean).join(' \u00b7 '));

            rec.appendChild(Dom.text('div', 'small text-body-secondary mt-1 ps-3', rows.join(' \u00b7 ')));
        }
    }

    App.CheckAvailabilityTool = CheckAvailabilityTool;
    App.Tool.register('check_availability', CheckAvailabilityTool);
})();
// Displays results from the fetch tool.

(function () {
    'use strict';

    const App = window.McpConsole;
    const Dom = App.Dom;

    class FetchTool extends App.Tool {
        render(payload) {
            const box = this.panel();
            box.appendChild(this.summary(payload.title || payload.id || 'Record'));

            const list = document.createElement('dl');
            list.className = 'row small mb-0';

            Object.keys(payload).forEach((key) => {
                // Shows stored data in the details section below.
                if (key === 'record' || key === 'metadata') {
                    return;
                }

                const value = payload[key];
                if (value === null || value === undefined || value === '') {
                    return;
                }

                list.appendChild(Dom.text('dt', 'col-4 col-sm-3 fw-normal text-body-secondary', key));
                list.appendChild(Dom.text('dd', 'col-8 col-sm-9 mb-1',
                    typeof value === 'object' ? JSON.stringify(value) : String(value)));
            });

            box.appendChild(list);

            const stored = payload.record || payload.metadata;
            if (stored) {
                const more = document.createElement('details');
                more.appendChild(Dom.text('summary', 'small text-body-secondary', 'Every stored field'));
                more.appendChild(this.pre(JSON.stringify(stored, null, 2)));
                box.appendChild(more);
            }
        }
    }

    App.FetchTool = FetchTool;
    App.Tool.register('fetch', FetchTool);
})();
// Reuses the fetch display for the get_record tool.

(function () {
    'use strict';

    const App = window.McpConsole;

    class GetRecordTool extends App.FetchTool {
    }

    App.GetRecordTool = GetRecordTool;
    App.Tool.register('get_record', GetRecordTool);
})();
// Adds examples for the browse_call_numbers tool.

(function () {
    'use strict';

    const App = window.McpConsole;

    class BrowseCallNumbersTool extends App.Tool {
        examples() {
            return [
                {
                    label: 'What is shelved here',
                    args: {call_number: 'PS3561.I483', limit: 10}
                },
                {
                    label: 'And what comes before it',
                    args: {call_number: 'PS3561.I483', direction: 'backward', limit: 10}
                }
            ].concat(this.derivedExamples());
        }
    }

    App.BrowseCallNumbersTool = BrowseCallNumbersTool;
    App.Tool.register('browse_call_numbers', BrowseCallNumbersTool);
})();
// Adds examples for the describe_search_options tool.

(function () {
    'use strict';

    const App = window.McpConsole;

    class DescribeSearchOptionsTool extends App.Tool {
        examples() {
            return [
                {label: 'What can I ask for?', args: {}},
                {label: 'Fields and facets only', args: {include_facet_values: false}}
            ].concat(this.derivedExamples());
        }
    }

    App.DescribeSearchOptionsTool = DescribeSearchOptionsTool;
    App.Tool.register('describe_search_options', DescribeSearchOptionsTool);
})();
