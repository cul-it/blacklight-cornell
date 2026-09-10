// Schema-driven forms for MCP tool arguments.
//
// This file turns each tool's `inputSchema` into controls a person can use. It
// handles basic values, lists, facets, filters, year ranges, and advanced search
// rows. Every control knows how to read its value into MCP tool arguments and
// how to restore a saved example or shared URL. Facet choices are loaded through
// the MCP client and cached for the current page.

(function () {
    'use strict';

    const App = window.McpConsole;
    const Dom = App.Dom;

    class Widget {
        constructor(name, spec) {
            this.name = name;
            this.spec = spec || {};
            this.el = null;
        }

        // Tells the form to use a full row.
        get wide() {
            return false;
        }

        // Uses the schema description as help text.
        get hint() {
            return this.spec.description;
        }

        // Adds this value to the tool arguments.
        read() {
            throw new Error(this.constructor.name + ' cannot read itself');
        }

        // Fills this control from tool arguments.
        write() {
            throw new Error(this.constructor.name + ' cannot write itself');
        }
    }

    class ListWidget extends Widget {
        constructor(name, spec, addLabel) {
            super(name, spec);

            // Keeps each row's extra control with that row.
            this.parts = new Map();

            this.list = document.createElement('div');
            this.list.className = 'vstack gap-2';

            this.add = Dom.button('btn btn-sm btn-outline-secondary mt-2', 'plus', addLabel);
            this.add.addEventListener('click', () => this.append());

            this.el = document.createElement('div');
            this.el.appendChild(this.list);
            this.el.appendChild(this.add);
        }

        get wide() {
            return true;
        }

        // Adds a row to the page.
        append() {
            const row = this.row();
            this.list.appendChild(row);
            this.settle();
            return row;
        }

        // Subclasses define their row layout.
        row() {
            throw new Error(this.constructor.name + ' has no row to add');
        }

        // Subclasses can update controls after rows change.
        settle() {
        }

        clear() {
            this.list.innerHTML = '';
            this.parts.clear();
        }

        remember(row, part) {
            this.parts.set(row, part);
            return part;
        }

        part(row) {
            return this.parts.get(row);
        }

        get rows() {
            return Array.prototype.slice.call(this.list.children);
        }

        // Builds a button that removes its row.
        removeButton(row, title) {
            const button = Dom.button('btn btn-sm btn-outline-secondary', 'times');
            button.dataset.role = 'remove';
            button.title = title;
            button.addEventListener('click', () => {
                this.list.removeChild(row);
                this.parts.delete(row);
                this.settle();
            });
            return Dom.cell('col-auto', button);
        }
    }

    App.Widget = Widget;
    App.ListWidget = ListWidget;
})();
// Builds basic controls from schema types.

(function () {
    'use strict';

    const App = window.McpConsole;
    const Dom = App.Dom;

    class SimpleWidget extends App.Widget {
        constructor(name, spec) {
            super(name, spec);

            this.kind = SimpleWidget.kindOf(this.spec);
            this.el = this.control();
            this.el.id = 'arg-' + name;
        }

        static kindOf(spec) {
            if (spec.enum) {
                return 'string';
            }
            if (spec.type === 'boolean') {
                return 'boolean';
            }
            if (spec.type === 'integer' || spec.type === 'number') {
                return 'number';
            }
            if (spec.type === 'array') {
                return spec.items && spec.items.enum ? 'multi' : 'list';
            }
            return 'string';
        }

        control() {
            const spec = this.spec;

            if (spec.enum) {
                const el = document.createElement('select');
                el.className = 'form-select';
                el.appendChild(new Option('', ''));
                spec.enum.forEach((value) => el.appendChild(new Option(value, value)));
                return el;
            }

            if (this.kind === 'boolean') {
                const el = document.createElement('input');
                el.type = 'checkbox';
                el.className = 'form-check-input';
                return el;
            }

            if (this.kind === 'number') {
                const el = document.createElement('input');
                el.type = 'number';
                el.className = 'form-control';
                if (spec.minimum !== undefined) {
                    el.min = spec.minimum;
                }
                if (spec.maximum !== undefined) {
                    el.max = spec.maximum;
                }
                return el;
            }

            if (this.kind === 'multi') {
                const el = document.createElement('select');
                el.className = 'form-select';
                el.multiple = true;
                el.size = Math.min(spec.items.enum.length, 4);
                spec.items.enum.forEach((value) => el.appendChild(new Option(value, value)));
                return el;
            }

            const el = document.createElement('input');
            el.type = 'text';
            el.className = 'form-control';
            if (this.kind === 'list') {
                el.placeholder = 'one per comma';
            }
            return el;
        }

        read(args) {
            if (this.kind === 'boolean') {
                if (this.el.checked) {
                    args[this.name] = true;
                }
                return;
            }

            if (this.kind === 'multi') {
                const picked = Dom.selectedValues(this.el);
                if (picked.length) {
                    args[this.name] = picked;
                }
                return;
            }

            const raw = (this.el.value || '').trim();
            if (!raw) {
                return;
            }

            if (this.kind === 'number') {
                args[this.name] = Number(raw);
            } else if (this.kind === 'list') {
                args[this.name] = raw.split(',').map((value) => value.trim()).filter(Boolean);
            } else {
                args[this.name] = raw;
            }
        }

        write(args) {
            const value = args[this.name];

            if (this.kind === 'boolean') {
                this.el.checked = !!value;
                return;
            }

            if (this.kind === 'multi') {
                const wanted = value === undefined ? [] : [].concat(value).map(String);
                Array.prototype.forEach.call(this.el.options, (option) => {
                    option.selected = wanted.indexOf(option.value) !== -1;
                });
                return;
            }

            if (value === undefined) {
                this.el.value = '';
                return;
            }

            if (this.kind === 'list') {
                this.el.value = [].concat(value).join(', ');
                return;
            }

            // Ignores dropdown values missing from the current schema.
            if (this.el.tagName === 'SELECT' && !Dom.hasOption(this.el, String(value))) {
                this.el.value = '';
                return;
            }

            this.el.value = String(value);
        }
    }

    App.SimpleWidget = SimpleWidget;
})();
// Loads facet values and builds their picker.

(function () {
    'use strict';

    const App = window.McpConsole;
    const Dom = App.Dom;

    // Reads the allowed facets from an argument schema.
    class Facets {
        static namesFrom(spec) {
            const named = (spec.propertyNames || {}).enum;
            if (named && named.length) {
                return named;
            }

            // Supports older schemas that list facets in their description.
            return ((spec.description || '').match(/"([^"]+)"/g) || [])
                .map((quoted) => quoted.slice(1, -1));
        }
    }

    // Loads and caches values from the facet_values tool, once per facet per
    // page load. Asked for by adding a filter row, so it is part of building
    // the call rather than something the console does behind your back.
    class FacetValueLoader {
        constructor(client) {
            this.client = client;
            this.known = {};
        }

        load(facet) {
            if (this.known[facet]) {
                return Promise.resolve(this.known[facet]);
            }

            return this.client.callTool('facet_values', {field: facet}, {silent: true}).then((payload) => {
                this.known[facet] = payload.values || [];
                return this.known[facet];
            }).catch(() => []);
        }
    }

    // Offers known values plus a box for custom values.
    class ValuePicker {
        constructor(facetValueLoader, chosen) {
            this.facetValueLoader = facetValueLoader;

            this.select = document.createElement('select');
            this.select.className = 'form-select form-select-sm';
            this.select.dataset.role = 'value';

            this.typed = document.createElement('input');
            this.typed.type = 'text';
            this.typed.className = 'form-control form-control-sm';
            this.typed.placeholder = 'value';
            this.typed.dataset.role = 'typed';
            this.typed.hidden = true;

            // Keeps preset values visible while choices load.
            if (chosen !== undefined && chosen !== null) {
                this.typed.value = String(chosen);
                this.typed.hidden = false;
                this.select.hidden = true;
            }

            this.select.addEventListener('change', () => {
                const custom = this.select.value === ValuePicker.CUSTOM;
                this.typed.hidden = !custom;
                this.select.hidden = custom;
                if (custom) {
                    this.typed.focus();
                }
            });

            this.el = Dom.cell('col', this.select);
            this.el.appendChild(this.typed);
        }

        // Loads the choices for one facet.
        fill(facet, chosen) {
            this.select.innerHTML = '';
            this.select.appendChild(new Option('loading...', ''));
            this.select.disabled = true;

            return this.facetValueLoader.load(facet).then((values) => {
                this.select.innerHTML = '';
                this.select.disabled = false;

                // Nothing to choose from -- helper calls are off, or the facet
                // could not be read. Either way a text box beats an empty menu.
                if (!values.length) {
                    this.typed.hidden = false;
                    this.select.hidden = true;
                    return;
                }

                this.select.appendChild(new Option('', ''));

                values.forEach((entry) => {
                    this.select.appendChild(
                        new Option(entry.value + '  (' + Dom.number(entry.count) + ')', entry.value));
                });
                this.select.appendChild(new Option('Type a value...', ValuePicker.CUSTOM));

                if (chosen === undefined || chosen === null) {
                    return;
                }

                // Keeps custom values in the text box.
                if (Dom.hasOption(this.select, String(chosen))) {
                    this.select.value = String(chosen);
                    this.select.hidden = false;
                    this.typed.hidden = true;
                    this.typed.value = '';
                }
            });
        }

        // Resets the picker after its facet changes.
        reset() {
            this.typed.hidden = true;
            this.typed.value = '';
            this.select.hidden = false;
        }

        get value() {
            const value = (this.typed.hidden ? this.select.value : this.typed.value).trim();
            return value === ValuePicker.CUSTOM ? '' : value;
        }
    }

    // Marks the custom-value option without matching real data.
    ValuePicker.CUSTOM = '\u0000custom';

    App.Facets = Facets;
    App.FacetValueLoader = FacetValueLoader;
    App.ValuePicker = ValuePicker;
})();
// Builds controls for facet values and filters.

(function () {
    'use strict';

    const App = window.McpConsole;
    const Dom = App.Dom;

    // Handles an argument tied to one facet, such as formats.
    class FacetValuesWidget extends App.ListWidget {
        constructor(name, spec, facetValueLoader) {
            super(name, spec, 'Add ' + name.replace(/s$/, ''));
            this.facet = spec['x-facet'];
            this.facetValueLoader = facetValueLoader;
        }

        get hint() {
            return 'Values are OR-ed, and come from the ' + this.facet + ' facet.';
        }

        row(chosen) {
            const row = document.createElement('div');
            row.className = 'row g-2 align-items-center';

            const picker = this.remember(row, new App.ValuePicker(this.facetValueLoader, chosen));
            row.appendChild(picker.el);
            row.appendChild(this.removeButton(row, 'Remove this ' + this.name.replace(/s$/, '')));

            picker.fill(this.facet, chosen);
            return row;
        }

        read(args) {
            const chosen = this.rows
                .map((row) => this.part(row).value)
                .filter(Boolean);

            if (chosen.length) {
                args[this.name] = chosen;
            }
        }

        write(args) {
            this.clear();
            [].concat(args[this.name] || []).forEach((value) => this.append(value));
        }
    }

    // Handles filters made of facet and value pairs.
    class FiltersWidget extends App.ListWidget {
        constructor(name, spec, facetValueLoader) {
            super(name, spec, 'Add filter');
            this.facets = App.Facets.namesFrom(spec);
            this.facetValueLoader = facetValueLoader;
        }

        get hint() {
            return this.name === 'filters_all'
                ? 'Every value must be present on a record for it to match.'
                : 'Values are OR-ed. Two rows naming the same facet are one filter with two ' +
                'values, which is what ticking two boxes does on the site.';
        }

        row(facet, value) {
            const row = document.createElement('div');
            row.className = 'row g-2 align-items-center';

            const which = Dom.picker(this.facets, facet || this.facets[0], 'form-select form-select-sm');
            which.dataset.role = 'facet';
            row.appendChild(Dom.cell('col-12 col-sm-5', which));

            const picker = this.remember(row, new App.ValuePicker(this.facetValueLoader, value));
            row.appendChild(picker.el);
            row.appendChild(this.removeButton(row, 'Remove this filter'));

            which.addEventListener('change', () => {
                picker.reset();
                picker.fill(which.value);
            });

            picker.fill(which.value, value);
            return row;
        }

        read(args) {
            const chosen = {};

            this.rows.forEach((row) => {
                const facet = row.querySelector('[data-role=facet]').value;
                const value = this.part(row).value;
                if (!facet || !value) {
                    return;
                }

                // Groups values from rows that use the same facet.
                chosen[facet] = (chosen[facet] || []).concat(value);
            });

            if (Object.keys(chosen).length) {
                args[this.name] = chosen;
            }
        }

        write(args) {
            this.clear();
            const value = args[this.name];
            if (!value) {
                return;
            }

            Object.keys(value).forEach((facet) => {
                [].concat(value[facet]).forEach((entry) => this.append(facet, entry));
            });
        }
    }

    App.FacetValuesWidget = FacetValuesWidget;
    App.FiltersWidget = FiltersWidget;
})();
// Builds year and facet range controls.

(function () {
    'use strict';

    const App = window.McpConsole;
    const Dom = App.Dom;

    function yearInput(placeholder) {
        const el = document.createElement('input');
        el.type = 'number';
        el.className = 'form-control form-control-sm';
        el.placeholder = placeholder;
        return el;
    }

    // Handles one publication year range.
    class YearRangeWidget extends App.Widget {
        constructor(name, spec) {
            super(name, spec);

            this.begin = yearInput('from');
            this.end = yearInput('to');

            this.el = document.createElement('div');
            this.el.className = 'row g-2';
            this.el.appendChild(Dom.cell('col', this.begin));
            this.el.appendChild(Dom.cell('col', this.end));
        }

        get hint() {
            return 'Both years are required; the catalog ignores a half-open range.';
        }

        read(args) {
            if (this.begin.value && this.end.value) {
                args[this.name] = {begin: Number(this.begin.value), end: Number(this.end.value)};
            }
        }

        write(args) {
            const value = args[this.name] || {};
            this.begin.value = value.begin === undefined ? '' : value.begin;
            this.end.value = value.end === undefined ? '' : value.end;
        }
    }

    // Handles ranges that also choose a facet.
    class RangesWidget extends App.ListWidget {
        constructor(name, spec) {
            super(name, spec, 'Add range');
            this.facets = App.Facets.namesFrom(spec);
        }

        row(facet, bounds) {
            const row = document.createElement('div');
            row.className = 'row g-2 align-items-center';

            const which = Dom.picker(this.facets, facet || this.facets[0], 'form-select form-select-sm');
            which.dataset.role = 'facet';
            row.appendChild(Dom.cell('col-12 col-sm-5', which));

            const begin = yearInput('from');
            const end = yearInput('to');
            begin.dataset.role = 'begin';
            end.dataset.role = 'end';
            if (bounds) {
                begin.value = bounds.begin === undefined ? '' : bounds.begin;
                end.value = bounds.end === undefined ? '' : bounds.end;
            }
            row.appendChild(Dom.cell('col', begin));
            row.appendChild(Dom.cell('col', end));

            row.appendChild(this.removeButton(row, 'Remove this range'));
            return row;
        }

        read(args) {
            const chosen = {};

            this.rows.forEach((row) => {
                const facet = row.querySelector('[data-role=facet]').value;
                const begin = row.querySelector('[data-role=begin]').value;
                const end = row.querySelector('[data-role=end]').value;
                if (facet && begin && end) {
                    chosen[facet] = {begin: Number(begin), end: Number(end)};
                }
            });

            if (Object.keys(chosen).length) {
                args[this.name] = chosen;
            }
        }

        write(args) {
            this.clear();
            const value = args[this.name];
            if (!value) {
                return;
            }
            Object.keys(value).forEach((facet) => this.append(facet, value[facet]));
        }
    }

    App.RangesWidget = RangesWidget;
    App.YearRangeWidget = YearRangeWidget;
})();
// Builds advanced_search rows and their AND/OR/NOT joins.

(function () {
    'use strict';

    const App = window.McpConsole;
    const Dom = App.Dom;

    const OP_LABELS = {
        AND: 'all of these words',
        OR: 'any of these words',
        phrase: 'this exact phrase',
        begins_with: 'begins with'
    };

    class RowsWidget extends App.ListWidget {
        constructor(name, spec, props) {
            super(name, spec, 'Add row');

            const item = spec.items.properties || {};
            this.fields = (item.field || {}).enum || [];
            this.ops = (item.op || {}).enum || [];
            this.joins = ((props.booleans || {}).items || {}).enum || ['AND', 'OR', 'NOT'];
            this.max = spec.maxItems || 10;

            this.write({});
        }

        get hint() {
            return 'Rows are combined left to right: A, B, C joined by AND then OR means ' +
                '((A AND B) OR C). A row with no words in it is left out.';
        }

        row(value, join) {
            const row = document.createElement('div');
            row.className = 'row g-2 align-items-center';

            // Hides the first join but keeps all columns aligned.
            const boolean = Dom.picker(this.joins, join || 'AND', 'form-select form-select-sm');
            boolean.dataset.role = 'boolean';
            row.appendChild(Dom.cell('col-auto mcp-join', boolean));

            const query = document.createElement('input');
            query.type = 'text';
            query.className = 'form-control form-control-sm';
            query.placeholder = 'words to search for';
            query.dataset.role = 'query';
            query.value = (value && value.query) || '';
            row.appendChild(Dom.cell('col-12 col-sm', query));

            const field = Dom.picker(this.fields, (value && value.field) || this.fields[0],
                'form-select form-select-sm');
            field.dataset.role = 'field';
            row.appendChild(Dom.cell('col-auto', field));

            const op = Dom.picker(this.ops, (value && value.op) || this.ops[0],
                'form-select form-select-sm', OP_LABELS);
            op.dataset.role = 'op';
            row.appendChild(Dom.cell('col-auto', op));

            row.appendChild(this.removeButton(row, 'Remove this row'));
            return row;
        }

        // Keeps at least one row and hides its unused join.
        settle() {
            this.rows.forEach((row, index) => {
                row.querySelector('.mcp-join').classList.toggle('invisible', index === 0);
                row.querySelector('[data-role=remove]').disabled = this.rows.length === 1;
            });
            this.add.disabled = this.rows.length >= this.max;
        }

        read(args) {
            const kept = [];

            this.rows.forEach((row) => {
                const query = row.querySelector('[data-role=query]').value.trim();
                if (!query) {
                    return;
                }
                kept.push({
                    row: {
                        query: query,
                        field: row.querySelector('[data-role=field]').value,
                        op: row.querySelector('[data-role=op]').value
                    },
                    join: row.querySelector('[data-role=boolean]').value
                });
            });

            if (!kept.length) {
                return;
            }

            args.rows = kept.map((entry) => entry.row);

            // Only keeps joins between non-empty rows.
            const operators = kept.slice(1).map((entry) => entry.join);
            if (operators.length) {
                args.booleans = operators;
            }
        }

        write(args) {
            this.clear();

            const values = args.rows && args.rows.length ? args.rows : [null];
            values.forEach((value, index) => {
                this.append(value, index > 0 ? (args.booleans || [])[index - 1] : null);
            });
        }
    }

    App.RowsWidget = RowsWidget;
})();
// Builds tool forms from MCP input schemas.

(function () {
    'use strict';

    const App = window.McpConsole;
    const Dom = App.Dom;

    class ToolForm {
        constructor(page, facetValueLoader) {
            this.page = page;
            this.facetValueLoader = facetValueLoader;
            this.widgets = [];
        }

        build(tool) {
            this.page.form.innerHTML = '';
            this.widgets = [];

            const props = tool.properties;
            const required = tool.schema.required || [];
            const names = Object.keys(props);
            if (!names.length) {
                return;
            }

            const grid = document.createElement('div');
            grid.className = 'row g-3';
            this.page.form.appendChild(grid);

            names.forEach((name) => {
                // RowsWidget manages its own boolean joins.
                if (name === 'booleans' && props.rows) {
                    return;
                }

                const widget = this.widgetFor(name, props[name] || {}, props);
                this.widgets.push(widget);
                grid.appendChild(this.field(widget, required.indexOf(name) !== -1));
            });
        }

        // Wraps a control with its label and help text.
        field(widget, isRequired) {
            const field = document.createElement('div');
            field.className = widget.wide ? 'col-12' : 'col-12 col-md-6';

            const label = document.createElement('label');
            label.className = 'form-label mb-1';
            label.textContent = widget.name;
            if (isRequired) {
                label.appendChild(Dom.text('span', 'text-danger', ' *'));
            }
            if (widget.el.id) {
                label.setAttribute('for', widget.el.id);
            }

            field.appendChild(label);
            field.appendChild(widget.el);

            if (widget.hint) {
                field.appendChild(Dom.text('p', 'form-text mt-1', widget.hint));
            }
            return field;
        }

        // Picks a control from the argument schema.
        widgetFor(name, spec, props) {
            if (name === 'rows' && spec.items && spec.items.type === 'object') {
                return new App.RowsWidget(name, spec, props);
            }
            if (name === 'date_range') {
                return new App.YearRangeWidget(name, spec);
            }
            if (name === 'ranges') {
                return new App.RangesWidget(name, spec);
            }
            if (spec.type === 'object' && spec.additionalProperties) {
                return new App.FiltersWidget(name, spec, this.facetValueLoader);
            }
            // Use catalog choices for facet-backed arguments.
            if (spec['x-facet']) {
                return new App.FacetValuesWidget(name, spec, this.facetValueLoader);
            }
            return new App.SimpleWidget(name, spec);
        }

        // Reads the current tool arguments.
        readArguments() {
            const toolArguments = {};
            this.widgets.forEach((widget) => widget.read(toolArguments));
            return toolArguments;
        }

        // Replaces every value so old form data is cleared.
        writeArguments(toolArguments) {
            this.widgets.forEach((widget) => widget.write(toolArguments || {}));
        }
    }

    App.ToolForm = ToolForm;
})();
