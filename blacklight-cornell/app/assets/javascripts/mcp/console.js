// The browser MCP client behind /mcp/console.
//
// It speaks JSON-RPC to this app's own /mcp endpoint with fetch(), exactly the
// way any other MCP client would, and builds its forms from the schemas
// tools/list reports -- so a new tool, or a new argument on one, appears here
// with no change to this file.
//
// Result *renderers* are keyed by tool name on purpose: an availability card
// cannot be drawn generically. Anything without one falls back to formatted
// JSON, so an unknown tool is still usable.

    (function () {
        'use strict';

        var ENDPOINT = new URL('/mcp', window.location.href).toString();
        var tools = {};
        var order = [];
        var nextId = 1;
        var lastCall = null;

        var $tool = document.getElementById('tool');
        var $desc = document.getElementById('tool-desc');
        var $examples = document.getElementById('examples');
        var $args = document.getElementById('args');
        var $run = document.getElementById('run');
        var $curl = document.getElementById('curl');
        var $status = document.getElementById('status');
        var $results = document.getElementById('results');
        var $raw = document.getElementById('raw');
        var $rawWrap = document.getElementById('raw-wrap');
        var $rawLabel = document.getElementById('raw-label');

        document.getElementById('endpoint').textContent = ENDPOINT;

        // Captured before the button is ever swapped for a spinner.
        var RUN_LABEL = $run.innerHTML;

        // --- talking to the endpoint ---------------------------------------------

        // One JSON-RPC round trip. The stateless transport answers a plain POST, and
        // may answer as either JSON or a single SSE frame depending on what it
        // negotiates, so both are handled.
        // `silent` is for the calls the console makes on your behalf -- filling a
        // facet dropdown, chasing availability after a search. They are real
        // requests, but showing them would mean the raw panel never held the call
        // you actually asked for.
        function rpc(method, params, options) {
            var body = {jsonrpc: '2.0', id: nextId++, method: method};
            if (params) {
                body.params = params;
            }
            lastCall = body;

            return fetch(ENDPOINT, {
                method: 'POST',
                headers: {'Content-Type': 'application/json', 'Accept': 'application/json, text/event-stream'},
                body: JSON.stringify(body)
            }).then(function (res) {
                return res.text().then(function (text) {
                    var parsed = parseBody(text);
                    if (!(options && options.silent)) {
                        showRaw(body, parsed || text);
                    }
                    if (!res.ok && !parsed) {
                        throw new Error('HTTP ' + res.status);
                    }
                    if (!parsed) {
                        throw new Error('the endpoint sent something that is not JSON-RPC');
                    }
                    if (parsed.error) {
                        throw new Error(parsed.error.message || 'the endpoint returned an error');
                    }
                    return parsed.result;
                });
            });
        }

        function parseBody(text) {
            try {
                return JSON.parse(text);
            } catch (e) { /* maybe SSE */
            }
            var frame = text.split('\n').filter(function (line) {
                return line.indexOf('data:') === 0;
            })
                .map(function (line) {
                    return line.slice(5).trim();
                }).join('');
            try {
                return JSON.parse(frame);
            } catch (e) {
                return null;
            }
        }

        // Tools answer with one text block holding JSON.
        function callTool(name, args, options) {
            return rpc('tools/call', {name: name, arguments: args}, options).then(function (result) {
                var text = result && result.content && result.content[0] ? result.content[0].text : '';
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

        function showRaw(request, response) {
            $rawWrap.hidden = false;

            // Name the call in the summary, so what the panel holds is obvious
            // without opening it.
            if ($rawLabel) {
                var label = request.method;
                if (request.params && request.params.name) {
                    label += ' ' + request.params.name;
                }
                $rawLabel.textContent = label;
            }
            $raw.textContent = '\u2192 request\n' + JSON.stringify(request, null, 2) +
                '\n\n\u2190 response\n' +
                (typeof response === 'string' ? response : JSON.stringify(response, null, 2));
        }

        // --- building the form from the tool's own schema ------------------------
        //
        // Each argument becomes a widget: an object that owns some markup, can
        // read itself into an arguments hash, and can be written back from one.
        // Most are one control, but `rows` and `filters` are collections a person
        // builds a line at a time, and one widget may own more than one argument
        // -- the row builder produces both `rows` and `booleans`.
        var widgets = [];

        function buildForm(tool) {
            $args.innerHTML = '';
            widgets = [];

            var schema = tool.inputSchema || {};
            var props = schema.properties || {};
            var required = schema.required || [];
            var names = Object.keys(props);
            if (!names.length) {
                return;
            }

            var grid = document.createElement('div');
            grid.className = 'row g-3';
            $args.appendChild(grid);

            names.forEach(function (name) {
                // The row builder carries the booleans, so they get no control.
                if (name === 'booleans' && props.rows) {
                    return;
                }

                var widget = widgetFor(name, props[name] || {}, props);
                widgets.push(widget);

                var field = document.createElement('div');
                field.className = widget.wide ? 'col-12' : 'col-12 col-md-6';
                grid.appendChild(field);

                var label = document.createElement('label');
                label.className = 'form-label mb-1';
                label.textContent = name;
                if (required.indexOf(name) !== -1) {
                    label.appendChild(text('span', 'text-danger', ' *'));
                }
                if (widget.el.id) {
                    label.setAttribute('for', widget.el.id);
                }
                field.appendChild(label);
                field.appendChild(widget.el);

                var hint = widget.hint || props[name].description;
                if (hint) {
                    field.appendChild(text('p', 'form-text mt-1', hint));
                }
            });
        }

        function widgetFor(name, spec, props) {
            if (name === 'rows' && itemsAreObjects(spec)) {
                return rowsWidget(spec, props);
            }
            if (name === 'date_range') {
                return yearRangeWidget(name);
            }
            if (name === 'ranges') {
                return rangesWidget(name, spec);
            }
            if (spec.type === 'object' && spec.additionalProperties) {
                return filtersWidget(name, spec);
            }
            // The schema says these are one facet's values, so offer that facet's
            // values rather than a box to type them into.
            if (spec['x-facet']) {
                return facetValuesWidget(name, spec['x-facet']);
            }
            return simpleWidget(name, spec);
        }

        function itemsAreObjects(spec) {
            return !!(spec.items && spec.items.type === 'object');
        }

        // --- one plain control ---------------------------------------------------

        function simpleWidget(name, spec) {
            var el;
            var kind;

            if (spec.enum) {
                kind = 'string';
                el = document.createElement('select');
                el.className = 'form-select';
                el.appendChild(new Option('', ''));
                spec.enum.forEach(function (value) {
                    el.appendChild(new Option(value, value));
                });
            } else if (spec.type === 'boolean') {
                kind = 'boolean';
                el = document.createElement('input');
                el.type = 'checkbox';
                el.className = 'form-check-input';
            } else if (spec.type === 'integer' || spec.type === 'number') {
                kind = 'number';
                el = document.createElement('input');
                el.type = 'number';
                el.className = 'form-control';
                if (spec.minimum !== undefined) {
                    el.min = spec.minimum;
                }
                if (spec.maximum !== undefined) {
                    el.max = spec.maximum;
                }
            } else if (spec.type === 'array' && spec.items && spec.items.enum) {
                kind = 'multi';
                el = document.createElement('select');
                el.className = 'form-select';
                el.multiple = true;
                el.size = Math.min(spec.items.enum.length, 4);
                spec.items.enum.forEach(function (value) {
                    el.appendChild(new Option(value, value));
                });
            } else if (spec.type === 'array') {
                kind = 'list';
                el = document.createElement('input');
                el.type = 'text';
                el.className = 'form-control';
                el.placeholder = 'one per comma';
            } else {
                kind = 'string';
                el = document.createElement('input');
                el.type = 'text';
                el.className = 'form-control';
            }

            el.id = 'arg-' + name;

            return {
                el: el,
                read: function (args) {
                    if (kind === 'boolean') {
                        if (el.checked) {
                            args[name] = true;
                        }
                        return;
                    }
                    if (kind === 'multi') {
                        var picked = selectedValues(el);
                        if (picked.length) {
                            args[name] = picked;
                        }
                        return;
                    }

                    var raw = (el.value || '').trim();
                    if (!raw) {
                        return;
                    }
                    if (kind === 'number') {
                        args[name] = Number(raw);
                    } else if (kind === 'list') {
                        args[name] = raw.split(',').map(function (v) {
                            return v.trim();
                        }).filter(Boolean);
                    } else {
                        args[name] = raw;
                    }
                },
                write: function (args) {
                    var value = args[name];

                    if (kind === 'boolean') {
                        el.checked = !!value;
                        return;
                    }
                    if (kind === 'multi') {
                        var wanted = value === undefined ? [] : [].concat(value).map(String);
                        Array.prototype.forEach.call(el.options, function (option) {
                            option.selected = wanted.indexOf(option.value) !== -1;
                        });
                        return;
                    }
                    if (value === undefined) {
                        el.value = '';
                        return;
                    }
                    if (kind === 'list') {
                        el.value = [].concat(value).join(', ');
                        return;
                    }
                    // Only a value the schema still offers: a stale example must
                    // not put the form into a state the endpoint will reject.
                    if (el.tagName === 'SELECT' && !hasOption(el, String(value))) {
                        el.value = '';
                        return;
                    }
                    el.value = String(value);
                }
            };
        }

        // --- the advanced form's rows --------------------------------------------

        var OP_LABELS = {
            AND: 'all of these words',
            OR: 'any of these words',
            phrase: 'this exact phrase',
            begins_with: 'begins with'
        };

        // A query, the field to search it in, how its words are matched, and --
        // from the second row down -- how it joins to the row above. The endpoint
        // wants `rows` and `booleans` as two parallel arrays; to a person that is
        // one thing, so it is one widget here, and keeping them together is what
        // makes the two impossible to misalign.
        function rowsWidget(spec, props) {
            var item = spec.items.properties || {};
            var fields = (item.field || {}).enum || [];
            var ops = (item.op || {}).enum || [];
            var joins = ((props.booleans || {}).items || {}).enum || ['AND', 'OR', 'NOT'];
            var max = spec.maxItems || 10;

            var list = document.createElement('div');
            list.className = 'vstack gap-2';

            var add = document.createElement('button');
            add.type = 'button';
            add.className = 'btn btn-sm btn-outline-secondary mt-2';
            add.appendChild(icon('plus', 'me-1'));
            add.appendChild(document.createTextNode('Add row'));
            add.addEventListener('click', function () {
                addRow();
                refresh();
            });

            var el = document.createElement('div');
            el.appendChild(list);
            el.appendChild(add);

            function addRow(value, join) {
                var row = document.createElement('div');
                row.className = 'row g-2 align-items-center';

                // Always present, hidden on the first row, so every row's columns
                // stay lined up with each other.
                var boolean = picker(joins, join || 'AND', 'form-select form-select-sm');
                boolean.dataset.role = 'boolean';
                row.appendChild(cell('col-auto mcp-join', boolean));

                var query = document.createElement('input');
                query.type = 'text';
                query.className = 'form-control form-control-sm';
                query.placeholder = 'words to search for';
                query.dataset.role = 'query';
                query.value = (value && value.query) || '';
                row.appendChild(cell('col-12 col-sm', query));

                var field = picker(fields, (value && value.field) || fields[0], 'form-select form-select-sm');
                field.dataset.role = 'field';
                row.appendChild(cell('col-auto', field));

                var op = picker(ops, (value && value.op) || ops[0], 'form-select form-select-sm', OP_LABELS);
                op.dataset.role = 'op';
                row.appendChild(cell('col-auto', op));

                var remove = document.createElement('button');
                remove.type = 'button';
                remove.className = 'btn btn-sm btn-outline-secondary';
                remove.dataset.role = 'remove';
                remove.title = 'Remove this row';
                remove.appendChild(icon('times'));
                remove.addEventListener('click', function () {
                    list.removeChild(row);
                    refresh();
                });
                row.appendChild(cell('col-auto', remove));

                list.appendChild(row);
                return row;
            }

            // The first row joins to nothing, and the last row standing cannot be
            // removed -- a search with no rows at all is not a thing to build.
            function refresh() {
                Array.prototype.forEach.call(list.children, function (row, index) {
                    row.querySelector('.mcp-join').classList.toggle('invisible', index === 0);
                    row.querySelector('[data-role=remove]').disabled = list.children.length === 1;
                });
                add.disabled = list.children.length >= max;
            }

            function reset(values, booleans) {
                list.innerHTML = '';
                var rows = values && values.length ? values : [null];
                rows.forEach(function (value, index) {
                    addRow(value, index > 0 ? (booleans || [])[index - 1] : null);
                });
                refresh();
            }

            reset();

            return {
                el: el,
                wide: true,
                hint: 'Rows are combined left to right: A, B, C joined by AND then OR means ' +
                    '((A AND B) OR C). A row with no words in it is left out.',
                read: function (args) {
                    var kept = [];

                    Array.prototype.forEach.call(list.children, function (row) {
                        var query = row.querySelector('[data-role=query]').value.trim();
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

                    args.rows = kept.map(function (entry) {
                        return entry.row;
                    });

                    // One fewer than the rows, and only for the rows that survived,
                    // so dropping an empty row cannot shift the operators.
                    var operators = kept.slice(1).map(function (entry) {
                        return entry.join;
                    });
                    if (operators.length) {
                        args.booleans = operators;
                    }
                },
                write: function (args) {
                    reset(args.rows, args.booleans);
                }
            };
        }

        // --- facet filters -------------------------------------------------------

        var facetValues = {};
        var CUSTOM_VALUE = ' custom';

        // Which facets an argument accepts, from the argument's own schema.
        //
        // Borrowing the list from somewhere else is exactly how `ranges` came to
        // offer Format and Library Location: it was handed the *filterable*
        // facets, which by definition are the ones that are not ranges. Only the
        // schema for this argument knows what this argument takes.
        function facetNames(spec) {
            var named = (spec.propertyNames || {}).enum;
            if (named && named.length) {
                return named;
            }

            // Older deployments describe them in prose instead, quoted.
            return ((spec.description || '').match(/"([^"]+)"/g) || []).map(function (quoted) {
                return quoted.slice(1, -1);
            });
        }

        // Asks the endpoint what values a facet actually has, once per facet per
        // page load. This is the console doing what an assistant does: calling
        // facet_values so nobody has to guess at a spelling.
        function loadFacetValues(facet) {
            if (facetValues[facet]) {
                return Promise.resolve(facetValues[facet]);
            }

            return callTool('facet_values', {field: facet}, {silent: true}).then(function (payload) {
                facetValues[facet] = payload.values || [];
                return facetValues[facet];
            }).catch(function () {
                return [];
            });
        }

        // A facet value: a dropdown of what the facet actually has, with a text
        // box behind "Type a value" for anything further down the list than
        // facet_values returned. Shared by the filter builder and by the
        // shortcut arguments (formats, languages), which are the same choice.
        function valueCell(row, chosen) {
            var values = document.createElement('select');
            values.className = 'form-select form-select-sm';
            values.dataset.role = 'value';

            var typed = document.createElement('input');
            typed.type = 'text';
            typed.className = 'form-control form-control-sm';
            typed.placeholder = 'value';
            typed.dataset.role = 'typed';
            typed.hidden = true;

            // Shown straight away, so the value is readable the moment this
            // returns: a preset runs the search immediately, long before
            // facet_values answers. fillValues upgrades it to the dropdown once
            // the real values arrive.
            if (chosen !== undefined && chosen !== null) {
                typed.value = String(chosen);
                typed.hidden = false;
                values.hidden = true;
            }

            values.addEventListener('change', function () {
                var custom = values.value === CUSTOM_VALUE;
                typed.hidden = !custom;
                values.hidden = custom;
                if (custom) {
                    typed.focus();
                }
            });

            var holder = cell('col', values);
            holder.appendChild(typed);
            row.appendChild(holder);
            return {values: values, typed: typed};
        }

        function fillValues(row, facet, chosen) {
            var select = row.querySelector('[data-role=value]');
            select.innerHTML = '';
            select.appendChild(new Option('loading...', ''));
            select.disabled = true;

            loadFacetValues(facet).then(function (values) {
                select.innerHTML = '';
                select.disabled = false;
                select.appendChild(new Option('', ''));

                values.forEach(function (entry) {
                    select.appendChild(
                        new Option(entry.value + '  (' + number(entry.count) + ')', entry.value));
                });
                select.appendChild(new Option('Type a value...', CUSTOM_VALUE));

                if (chosen === undefined || chosen === null) {
                    return;
                }

                // A value the facet no longer lists is still what the caller
                // asked for, so it stays in the text box rather than vanishing.
                if (hasOption(select, String(chosen))) {
                    select.value = String(chosen);
                    select.hidden = false;

                    var box = row.querySelector('[data-role=typed]');
                    box.hidden = true;
                    box.value = '';
                }
            });
        }

        function readValue(row) {
            var typed = row.querySelector('[data-role=typed]');
            var select = row.querySelector('[data-role=value]');
            var value = (typed.hidden ? select.value : typed.value).trim();
            return value === CUSTOM_VALUE ? '' : value;
        }

        // A remove button that takes its row out of a list.
        function removeButton(list, row, title) {
            var button = document.createElement('button');
            button.type = 'button';
            button.className = 'btn btn-sm btn-outline-secondary';
            button.title = title;
            button.appendChild(icon('times'));
            button.addEventListener('click', function () {
                list.removeChild(row);
            });
            return cell('col-auto', button);
        }

        function adder(label, onClick) {
            var button = document.createElement('button');
            button.type = 'button';
            button.className = 'btn btn-sm btn-outline-secondary mt-2';
            button.appendChild(icon('plus', 'me-1'));
            button.appendChild(document.createTextNode(label));
            button.addEventListener('click', onClick);
            return button;
        }

        // formats and languages are shortcuts for one facet each, so they are a
        // list of that facet's values -- the same control as a filter row, minus
        // the facet picker. `x-facet` on the argument says which facet.
        function facetValuesWidget(name, facet) {
            var list = document.createElement('div');
            list.className = 'vstack gap-2';

            var add = adder('Add ' + name.replace(/s$/, ''), function () {
                addValue();
            });

            var el = document.createElement('div');
            el.appendChild(list);
            el.appendChild(add);

            function addValue(chosen) {
                var row = document.createElement('div');
                row.className = 'row g-2 align-items-center';

                valueCell(row, chosen);
                row.appendChild(removeButton(list, row, 'Remove this ' + name.replace(/s$/, '')));

                list.appendChild(row);
                fillValues(row, facet, chosen);
            }

            return {
                el: el,
                wide: true,
                hint: 'Values are OR-ed, and come from the ' + facet + ' facet.',
                read: function (args) {
                    var chosen = [];
                    Array.prototype.forEach.call(list.children, function (row) {
                        var value = readValue(row);
                        if (value) {
                            chosen.push(value);
                        }
                    });
                    if (chosen.length) {
                        args[name] = chosen;
                    }
                },
                write: function (args) {
                    list.innerHTML = '';
                    [].concat(args[name] || []).forEach(function (value) {
                        addValue(value);
                    });
                }
            };
        }

        function filtersWidget(name, spec) {
            var facets = facetNames(spec);

            var list = document.createElement('div');
            list.className = 'vstack gap-2';

            var add = adder('Add filter', function () {
                addFilter();
            });

            var el = document.createElement('div');
            el.appendChild(list);
            el.appendChild(add);

            function addFilter(facet, value) {
                var row = document.createElement('div');
                row.className = 'row g-2 align-items-center';

                var which = picker(facets, facet || facets[0], 'form-select form-select-sm');
                which.dataset.role = 'facet';
                row.appendChild(cell('col-12 col-sm-5', which));

                var controls = valueCell(row, value);
                row.appendChild(removeButton(list, row, 'Remove this filter'));

                which.addEventListener('change', function () {
                    controls.typed.hidden = true;
                    controls.typed.value = '';
                    controls.values.hidden = false;
                    fillValues(row, which.value);
                });

                list.appendChild(row);
                fillValues(row, which.value, value);
            }

            return {
                el: el,
                wide: true,
                hint: name === 'filters_all'
                    ? 'Every value must be present on a record for it to match.'
                    : 'Values are OR-ed. Two rows naming the same facet are one filter with two ' +
                    'values, which is what ticking two boxes does on the site.',
                read: function (args) {
                    var chosen = {};

                    Array.prototype.forEach.call(list.children, function (row) {
                        var facet = row.querySelector('[data-role=facet]').value;
                        var value = readValue(row);
                        if (!facet || !value) {
                            return;
                        }

                        // Two rows naming the same facet are one filter with two
                        // values, which is what ticking two boxes does on the site.
                        chosen[facet] = (chosen[facet] || []).concat(value);
                    });

                    if (Object.keys(chosen).length) {
                        args[name] = chosen;
                    }
                },
                write: function (args) {
                    list.innerHTML = '';
                    var value = args[name];
                    if (!value) {
                        return;
                    }

                    Object.keys(value).forEach(function (facet) {
                        [].concat(value[facet]).forEach(function (entry) {
                            addFilter(facet, entry);
                        });
                    });
                }
            };
        }

        // --- year ranges ---------------------------------------------------------

        function yearInput(placeholder) {
            var el = document.createElement('input');
            el.type = 'number';
            el.className = 'form-control form-control-sm';
            el.placeholder = placeholder;
            return el;
        }

        // date_range is one pair of years and needs no facet picker.
        function yearRangeWidget(name) {
            var begin = yearInput('from');
            var end = yearInput('to');

            var el = document.createElement('div');
            el.className = 'row g-2';
            el.appendChild(cell('col', begin));
            el.appendChild(cell('col', end));

            return {
                el: el,
                hint: 'Both years are required; the catalog ignores a half-open range.',
                read: function (args) {
                    if (begin.value && end.value) {
                        args[name] = {begin: Number(begin.value), end: Number(end.value)};
                    }
                },
                write: function (args) {
                    var value = args[name] || {};
                    begin.value = value.begin === undefined ? '' : value.begin;
                    end.value = value.end === undefined ? '' : value.end;
                }
            };
        }

        // `ranges` is the same pair of years, keyed by which range facet.
        function rangesWidget(name, spec) {
            var facets = facetNames(spec);

            var list = document.createElement('div');
            list.className = 'vstack gap-2';

            var add = adder('Add range', function () {
                addRange();
            });

            var el = document.createElement('div');
            el.appendChild(list);
            el.appendChild(add);

            function addRange(facet, bounds) {
                var row = document.createElement('div');
                row.className = 'row g-2 align-items-center';

                var which = picker(facets, facet || facets[0], 'form-select form-select-sm');
                which.dataset.role = 'facet';
                row.appendChild(cell('col-12 col-sm-5', which));

                var begin = yearInput('from');
                var end = yearInput('to');
                begin.dataset.role = 'begin';
                end.dataset.role = 'end';
                if (bounds) {
                    begin.value = bounds.begin === undefined ? '' : bounds.begin;
                    end.value = bounds.end === undefined ? '' : bounds.end;
                }
                row.appendChild(cell('col', begin));
                row.appendChild(cell('col', end));

                row.appendChild(removeButton(list, row, 'Remove this range'));

                list.appendChild(row);
            }

            return {
                el: el,
                wide: true,
                read: function (args) {
                    var chosen = {};

                    Array.prototype.forEach.call(list.children, function (row) {
                        var facet = row.querySelector('[data-role=facet]').value;
                        var begin = row.querySelector('[data-role=begin]').value;
                        var end = row.querySelector('[data-role=end]').value;
                        if (facet && begin && end) {
                            chosen[facet] = {begin: Number(begin), end: Number(end)};
                        }
                    });

                    if (Object.keys(chosen).length) {
                        args[name] = chosen;
                    }
                },
                write: function (args) {
                    list.innerHTML = '';
                    var value = args[name];
                    if (!value) {
                        return;
                    }
                    Object.keys(value).forEach(function (facet) {
                        addRange(facet, value[facet]);
                    });
                }
            };
        }

        // --- widget plumbing -----------------------------------------------------

        function cell(className, child) {
            var el = document.createElement('div');
            el.className = className;
            el.appendChild(child);
            return el;
        }

        function picker(values, chosen, className, labels) {
            var el = document.createElement('select');
            el.className = className;
            values.forEach(function (value) {
                el.appendChild(new Option((labels || {})[value] || value, value));
            });
            if (chosen && hasOption(el, String(chosen))) {
                el.value = String(chosen);
            }
            return el;
        }

        function hasOption(select, value) {
            return Array.prototype.some.call(select.options, function (option) {
                return option.value === value;
            });
        }

        function selectedValues(select) {
            return Array.prototype.filter.call(select.options, function (option) {
                return option.selected;
            }).map(function (option) {
                return option.value;
            });
        }

        function collectArgs() {
            var args = {};
            widgets.forEach(function (widget) {
                widget.read(args);
            });
            return args;
        }

        // --- rendering what came back --------------------------------------------

        function render(toolName, payload) {
            $results.innerHTML = '';
            if (toolName === 'search' || toolName === 'advanced_search') {
                return renderSearch(payload);
            }
            if (toolName === 'check_availability') {
                return renderAvailability(payload.records || [], payload.not_found);
            }
            if (toolName === 'facet_values') {
                return renderFacetValues(payload);
            }
            if (toolName === 'get_record' || toolName === 'fetch') {
                return renderRecord(payload);
            }
            return renderJson(payload);
        }

        // Every result block is a Bootstrap card; callers get the body to fill.
        function panel() {
            var card = document.createElement('div');
            card.className = 'card mb-4';

            var body = document.createElement('div');
            body.className = 'card-body';
            card.appendChild(body);

            $results.appendChild(card);
            return body;
        }

        // Font Awesome 4.7 -- the icon set the rest of the catalog uses.
        function icon(glyph, extra) {
            var el = document.createElement('i');
            el.className = 'fa fa-' + glyph + (extra ? ' ' + extra : '');
            el.setAttribute('aria-hidden', 'true');
            return el;
        }

        var SUMMARY = 'd-flex justify-content-between align-items-baseline ' +
            'border-bottom pb-2 mb-3 small text-body-secondary';


        var PRE = 'bg-body-tertiary border rounded p-3 small mb-0 mt-2';

        function renderSearch(payload) {
            if (payload.explain) {
                return renderJson(payload);
            }

            var box = panel();
            var docs = payload.documents || [];

            var head = document.createElement('div');
            head.className = SUMMARY;
            head.innerHTML = '<span>' + number(payload.total) + ' result' + (payload.total === 1 ? '' : 's') +
                '</span><span>page ' + payload.page + ' of ' + number(payload.total_pages) + '</span>';
            box.appendChild(head);

            if (!docs.length) {
                box.appendChild(text('p', 'small text-body-secondary mb-0', 'Nothing matched. Try fewer filters, or a broader query.'));
                return;
            }

            rememberIds(docs);
            docs.forEach(function (doc) {
                box.appendChild(recordCard(doc));
            });
            enrichAvailability(docs);
        }

        function recordCard(doc) {
            var rec = document.createElement('div');
            rec.className = 'mcp-rec py-3 border-bottom';
            rec.dataset.id = doc.id;

            var head = document.createElement('div');
            head.className = 'd-flex justify-content-between gap-3 align-items-baseline';

            var title = document.createElement('div');
            title.className = 'fw-semibold';
            if (doc.url) {
                var link = document.createElement('a');
                link.href = doc.url;
                link.target = '_blank';
                link.rel = 'noopener';
                link.textContent = doc.title || '(untitled)';
                title.appendChild(link);
            } else {
                title.textContent = doc.title || '(untitled)';
            }
            head.appendChild(title);
            head.appendChild(text('div', 'small text-body-secondary text-nowrap', doc.publication_year || ''));
            rec.appendChild(head);

            var meta = [doc.author, doc.format, doc.call_number].filter(Boolean).join(' \u00b7 ');
            if (meta) {
                rec.appendChild(text('div', 'small text-body-secondary mt-1', meta));
            }

            var slot = document.createElement('div');
            slot.className = 'small mt-1 text-body-secondary';
            slot.dataset.slot = doc.id;
            rec.appendChild(slot);

            // Reading a record otherwise means copying the id, switching tools and
            // pasting it back -- the most tedious thing about using this by hand.
            var recordTool = tools.fetch ? 'fetch' : 'get_record';
            if (tools[recordTool]) {
                var actions = document.createElement('div');
                actions.className = 'mt-2 d-flex gap-3';

                var button = document.createElement('button');
                button.type = 'button';
                button.className = 'btn btn-link btn-sm p-0 align-baseline text-decoration-none';
                button.appendChild(icon('file-text-o', 'me-1'));
                button.appendChild(document.createTextNode('Full record'));
                button.addEventListener('click', function () {
                    runWith(recordTool, {id: String(doc.id)});
                });

                actions.appendChild(button);
                rec.appendChild(actions);
            }

            return rec;
        }

        // A second tool call, the way an assistant would chain them: search says what
        // exists, check_availability says whether you can walk up and take it.
        function enrichAvailability(docs) {
            var ids = docs.map(function (doc) {
                return String(doc.id);
            }).slice(0, 10);
            if (!ids.length) {
                return;
            }

            callTool('check_availability', {ids: ids}, {silent: true}).then(function (payload) {
                (payload.records || []).forEach(function (record) {
                    var slot = $results.querySelector('[data-slot="' + cssEscape(String(record.id)) + '"]');
                    if (slot) {
                        fillAvailability(slot, record);
                    }
                });
            }).catch(function () {
                // The search results stand on their own; a failed follow-up is not worth
                // shouting about.
            });
        }

        // Colour is never the only signal: the icon and the sentence say the same
        // thing, so this reads the same to anyone who cannot tell them apart.
        function fillAvailability(el, record) {
            var on = record.available_now === true;
            var out = record.available_now === false;

            el.className = 'small mt-1 ' + (on ? 'text-success' : (out ? 'text-danger' : 'text-body-secondary'));
            el.innerHTML = '';
            el.appendChild(icon(on ? 'check-circle' : (out ? 'clock-o' : 'question-circle-o'), 'me-1'));
            el.appendChild(document.createTextNode(record.summary || 'No availability reported'));

            var where = (record.copies || []).map(function (copy) {
                return [copy.library, copy.call_number].filter(Boolean).join(' \u2014 ');
            }).filter(Boolean);
            if (where.length) {
                el.appendChild(text('div', 'text-body-secondary', where.join(' \u00b7 ')));
            }
        }

        function renderAvailability(records, notFound) {
            var box = panel();
            if (!records.length) {
                box.appendChild(text('p', 'small text-body-secondary mb-0', 'No records came back.'));
            }

            records.forEach(function (record) {
                var rec = document.createElement('div');
                rec.className = 'mcp-rec py-3 border-bottom';

                var head = document.createElement('div');
                head.className = 'd-flex justify-content-between gap-3 align-items-baseline';
                head.appendChild(text('div', 'fw-semibold', record.title || record.id));
                head.appendChild(text('div', 'small text-body-secondary text-nowrap', record.publication_year || ''));
                rec.appendChild(head);

                var slot = document.createElement('div');
                slot.className = 'small mt-1 text-body-secondary';
                fillAvailability(slot, record);
                rec.appendChild(slot);

                (record.online_access || []).forEach(function (link) {
                    var p = document.createElement('div');
                    p.className = 'small mt-1';
                    var a = document.createElement('a');
                    a.href = link.url;
                    a.target = '_blank';
                    a.rel = 'noopener';
                    a.textContent = link.description || link.url;
                    p.appendChild(a);
                    rec.appendChild(p);
                });

                (record.copies || []).forEach(function (copy) {
                    if (!copy.items || !copy.items.length) {
                        return;
                    }
                    var rows = copy.items.map(function (item) {
                        return [item.status, item.enumeration, item.copy ? 'copy ' + item.copy : null,
                            item.loan_type].filter(Boolean).join(' \u00b7 ');
                    });
                    rec.appendChild(text('div', 'small text-body-secondary mt-1 ps-3', rows.join(' \u00b7 ')));
                });

                box.appendChild(rec);
            });

            if (notFound && notFound.length) {
                box.appendChild(text('p', 'small text-danger mb-0', 'No such record: ' + notFound.join(', ')));
            }
        }

        function renderFacetValues(payload) {
            var box = panel();
            box.appendChild(text('div', SUMMARY,
                payload.facet + ' \u00b7 page ' + payload.page + (payload.has_more ? ' (more available)' : '')));

            var table = document.createElement('table');
            table.className = 'table table-sm align-middle mb-0';
            table.innerHTML = '<thead><tr><th>Value</th><th class="text-end">Records</th></tr></thead>';
            var body = document.createElement('tbody');
            (payload.values || []).forEach(function (row) {
                var tr = document.createElement('tr');
                tr.appendChild(text('td', '', row.value));
                tr.appendChild(text('td', 'text-end text-body-secondary', number(row.count)));
                body.appendChild(tr);
            });
            table.appendChild(body);
            box.appendChild(table);
        }

        function renderRecord(payload) {
            var box = panel();
            box.appendChild(text('div', SUMMARY, payload.title || payload.id || 'Record'));

            var list = document.createElement('dl');
            list.className = 'row small mb-0';
            Object.keys(payload).forEach(function (key) {
                if (key === 'record' || key === 'metadata') {
                    return;
                }
                var value = payload[key];
                if (value === null || value === undefined || value === '') {
                    return;
                }
                list.appendChild(text('dt', 'col-4 col-sm-3 fw-normal text-body-secondary', key));
                list.appendChild(text('dd', 'col-8 col-sm-9 mb-1',
                    typeof value === 'object' ? JSON.stringify(value) : String(value)));
            });
            box.appendChild(list);

            if (payload.record || payload.metadata) {
                var more = document.createElement('details');
                more.appendChild(text('summary', 'small text-body-secondary', 'Every stored field'));
                var pre = document.createElement('pre');
                pre.className = PRE;
                pre.textContent = JSON.stringify(payload.record || payload.metadata, null, 2);
                more.appendChild(pre);
                box.appendChild(more);
            }
        }

        function renderJson(payload) {
            var box = panel();
            var pre = document.createElement('pre');
            pre.className = PRE;
            pre.textContent = JSON.stringify(payload, null, 2);
            box.appendChild(pre);
        }

        // --- small helpers --------------------------------------------------------

        function text(tag, className, content) {
            var el = document.createElement(tag);
            if (className) {
                el.className = className;
            }
            el.textContent = content;
            return el;
        }

        function number(value) {
            return typeof value === 'number' ? value.toLocaleString() : value;
        }

        function cssEscape(value) {
            return value.replace(/["\\]/g, '\\$&');
        }

        // --- filling the form in -------------------------------------------------

        // Fills the whole form from an arguments hash: every widget is written,
        // including the ones the hash says nothing about, so applying an example
        // leaves no leftovers from the last run. Widgets ignore values the live
        // schema no longer offers, so a stale example or an old link cannot put
        // the form into a state the endpoint will only reject.
        function setArgs(args) {
            widgets.forEach(function (widget) {
                widget.write(args || {});
            });
        }

        function runWith(name, args) {
            if (!tools[name]) {
                return;
            }
            $tool.value = name;
            selectTool(name);
            setArgs(args);
            run();
        }

        // Somewhere to start. These are examples, not vocabulary -- setArgs drops
        // anything the live schema does not accept.
        var PRESETS = {
            search: [
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
            ],
            advanced_search: [
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
            ],
            describe_search_options: [
                {label: 'What can I ask for?', args: {}},
                {label: 'Fields and facets only', args: {include_facet_values: false}}
            ]
        };

        // Ids from the last search, so an example for a tool that needs a record
        // can use one that actually exists.
        var recentIds = [];

        function rememberIds(docs) {
            recentIds = docs.map(function (doc) {
                return String(doc.id);
            }).filter(Boolean);
        }

        // Record ids to demonstrate with: whatever the last search turned up, or
        // else ask the endpoint for some. Never a bib number hardcoded here --
        // that would rot the first time the index was rebuilt.
        function sampleIds(count) {
            if (recentIds.length >= count) {
                return Promise.resolve(recentIds.slice(0, count));
            }

            // A term rather than an empty query: Solr computes facet counts over
            // whatever matched, and matching the whole index to borrow three ids
            // is a lot of work for a demonstration.
            return callTool('search', {query: 'library', per_page: count}, {silent: true}).then(function (payload) {
                return (payload.documents || []).map(function (doc) {
                    return String(doc.id);
                });
            });
        }

        // Every tool gets something to click. Most examples are written above;
        // the rest are derived from the tool's own schema, so a tool this file
        // has never heard of still gets one.
        function presetsFor(name) {
            var presets = (PRESETS[name] || []).slice();
            var properties = ((tools[name] || {}).inputSchema || {}).properties || {};

            // A facet name has to come from the endpoint, which is the authority
            // on what the facets are called.
            if (properties.field) {
                var fields = properties.field.enum || [];
                var field = fields.indexOf('Format') !== -1 ? 'Format' : fields[0];
                if (field) {
                    presets.push({label: 'Values of ' + field, args: {field: field}});
                    presets.push({label: 'The same, A to Z', args: {field: field, sort: 'index'}});
                }
            }

            // Anything that takes a record id needs one that exists, so these
            // examples look one up when clicked. Keyed off the schema rather than
            // the tool name, so get_record, fetch and check_availability are all
            // covered, and so is the next tool that takes an id.
            var from = recentIds.length ? 'your last search' : 'the catalog';

            if (properties.id && tools.search) {
                presets.push({
                    label: 'A record from ' + from,
                    finding: 'finding a record to try\u2026',
                    resolve: function () {
                        return sampleIds(1).then(function (ids) {
                            return ids.length ? {id: ids[0]} : null;
                        });
                    }
                });
            }

            if (properties.ids && tools.search) {
                presets.push({
                    label: 'Three records from ' + from,
                    finding: 'finding records to try\u2026',
                    resolve: function () {
                        return sampleIds(3).then(function (ids) {
                            return ids.length ? {ids: ids} : null;
                        });
                    }
                });
            }

            return presets;
        }

        // An example either has its arguments already or has to go and find them.
        // Either way the button reports what it is doing rather than sitting
        // there looking broken.
        function applyPreset(preset, button) {
            if (!preset.resolve) {
                setArgs(preset.args);
                run();
                return;
            }

            var label = button.innerHTML;
            button.disabled = true;
            button.innerHTML = '<span class="spinner-border spinner-border-sm" aria-hidden="true"></span>';
            setStatus(preset.finding || 'finding an example\u2026');

            preset.resolve().then(function (args) {
                if (!args) {
                    throw new Error('the catalog returned nothing to use as an example');
                }
                setArgs(args);
                run();
            }).catch(function (error) {
                setStatus(error.message, true);
            }).then(function () {
                button.disabled = false;
                button.innerHTML = label;
            });
        }

        function renderExamples(name) {
            $examples.innerHTML = '';
            var presets = presetsFor(name);
            if (!presets.length) {
                return;
            }

            var hint = text('span', 'small text-body-secondary me-1', ' Try:');
            hint.insertBefore(icon('lightbulb-o'), hint.firstChild);
            $examples.appendChild(hint);

            presets.forEach(function (preset) {
                var button = document.createElement('button');
                button.type = 'button';
                button.className = 'btn btn-sm btn-outline-secondary rounded-pill';
                button.textContent = preset.label;
                button.addEventListener('click', function () {
                    applyPreset(preset, button);
                });
                $examples.appendChild(button);
            });
        }

        // --- the address bar as state --------------------------------------------

        function saveState(name, args) {
            try {
                window.history.replaceState(null, '',
                    '#' + encodeURIComponent(JSON.stringify({tool: name, args: args})));
            } catch (e) {
                // A shareable URL is a convenience, not a requirement.
            }
        }

        function readState() {
            if (!window.location.hash) {
                return null;
            }
            try {
                return JSON.parse(decodeURIComponent(window.location.hash.slice(1)));
            } catch (e) {
                return null;
            }
        }

        function setStatus(message, isError) {
            $status.textContent = message || '';
            $status.className = 'small ' + (isError ? 'text-danger' : 'text-body-secondary');
        }

        // --- wiring ---------------------------------------------------------------

        function selectTool(name) {
            var tool = tools[name];
            if (!tool) {
                return;
            }
            $desc.textContent = (tool.description || '').trim();
            buildForm(tool);
            renderExamples(name);
        }

        function run() {
            var name = $tool.value;
            var args;
            try {
                args = collectArgs();
            } catch (e) {
                setStatus(e.message, true);
                return;
            }

            saveState(name, args);
            $run.disabled = true;
            $run.innerHTML = '<span class="spinner-border spinner-border-sm me-2" aria-hidden="true"></span>Running';
            setStatus('running\u2026');
            var started = performance.now();

            callTool(name, args).then(function (payload) {
                setStatus('done in ' + Math.round(performance.now() - started) + ' ms');
                render(name, payload);
            }).catch(function (error) {
                setStatus(error.message, true);
                $results.innerHTML = '';
            }).then(function () {
                $run.disabled = false;
                $run.innerHTML = RUN_LABEL;
            });
        }

        function copyCurl() {
            var name = $tool.value;
            var args;
            try {
                args = collectArgs();
            } catch (e) {
                setStatus(e.message, true);
                return;
            }

            var body = JSON.stringify({
                jsonrpc: '2.0', id: 1, method: 'tools/call',
                params: {name: name, arguments: args}
            });
            var command = "curl -s -X POST " + ENDPOINT +
                " \\\n  -H 'Content-Type: application/json'" +
                " \\\n  -H 'Accept: application/json, text/event-stream'" +
                " \\\n  -d '" + body.replace(/'/g, "'\\''") + "'";

            navigator.clipboard.writeText(command).then(function () {
                setStatus('curl command copied');
            }).catch(function () {
                setStatus('could not copy \u2014 the command is in the panel below', true);
                $rawWrap.hidden = false;
                $raw.textContent = command;
            });
        }

        $tool.addEventListener('change', function () {
            selectTool($tool.value);
        });
        $run.addEventListener('click', run);
        $curl.addEventListener('click', copyCurl);
        // Without this, Enter in a text field navigates away instead of searching.
        $args.addEventListener('submit', function (event) {
            event.preventDefault();
            run();
        });

        setStatus('asking the endpoint what it can do\u2026');
        rpc('tools/list').then(function (result) {
            $tool.innerHTML = '';
            (result.tools || []).forEach(function (tool) {
                tools[tool.name] = tool;
                order.push(tool.name);
                // The tool's own annotation title, so the dropdown reads as English
                // rather than as a list of method names.
                var title = (tool.annotations || {}).title;
                $tool.appendChild(new Option(title ? tool.name + ' \u2014 ' + title : tool.name, tool.name));
            });
            if (!order.length) {
                throw new Error('the endpoint reported no tools');
            }

            $run.disabled = false;
            setStatus(order.length + ' tools available');

            // A link to this page carries the call it was sharing.
            var state = readState();
            if (state && tools[state.tool]) {
                runWith(state.tool, state.args || {});
            } else {
                selectTool(order[0]);
            }
        }).catch(function (error) {
            setStatus('could not reach the endpoint: ' + error.message, true);
        });
    })();
