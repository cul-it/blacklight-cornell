(function () {
    var drawer, backdrop, toggleBtn, closeBtn, content, form;
    var open = false;
    var currentHighlighted;

    function openDrawer() {
        if (open) return;
        open = true;
        drawer.classList.add('is-open');
        drawer.setAttribute('aria-hidden', 'false');
        backdrop.hidden = false;
        toggleBtn.setAttribute('aria-expanded', 'true');
    }

    function closeDrawer() {
        if (!open) return;
        open = false;
        drawer.classList.remove('is-open');
        drawer.setAttribute('aria-hidden', 'true');
        backdrop.hidden = true;
        toggleBtn.setAttribute('aria-expanded', 'false');
        clearHighlight();
    }

    function clearHighlight() {
        if (currentHighlighted) {
            currentHighlighted.classList.remove('help-target');
            currentHighlighted = null;
        }
    }

    function updateHelpFrom(el) {
        var target = el && el.closest('[data-help]');
        if (!target) return;
        if (currentHighlighted !== target) {
            clearHighlight();
            currentHighlighted = target;
            currentHighlighted.classList.add('help-target');
        }
        var txt = target.getAttribute('data-help') || 'No help available for this field.';
        content.textContent = txt;
    }

    function onPointerOver(e) {
        if (!open) return;
        updateHelpFrom(e.target);
    }

    function onFocusIn(e) {
        if (!open) return;
        updateHelpFrom(e.target);
    }

    function onClickInside(e) {
        if (!open) return;
        updateHelpFrom(e.target);
    }

    function onKeyDown(e) {
        if (e.key === 'Escape') closeDrawer();
    }

    function init() {

        // ---- Dynamic tip dictionaries (from your docs) ----
        var TIP_OP = {
            // op_row[] (how words in THIS box relate)
            AND: 'all: Every word in this box must appear (order not required).',
            OR: 'any: At least one of the words in this box must appear.',
            begins_with: 'begins with: Matches fields that start with these words.',
            phrase: 'phrase: Matches all words in this box in this exact order.'
        };

        var TIP_BOOL = {
            // boolean_row[] (how THIS row relates to other rows)
            AND: 'and: Results must include terms from this row AND previous rows (narrows).',
            OR: 'or: Results may include terms from this row OR previous rows (broadens). Put OR rows first.',
            NOT: 'not: Exclude records that match this row (narrows by omission).'
        };

// Normalize option label text → tip key
        function norm(s) {
            return String(s || '').trim().toLowerCase();
        }

// search_field_row[] label-based tips (map by visible text, not value)
        var TIP_FIELD = {
            'all fields': 'Search anywhere in the record. Great starting point; refine with facets if needed.',
            'title': 'Words in the title of the work.',
            'journal title': 'Title of a journal/newspaper/serial (not individual articles).',
            'title begins with': 'Title fields that start with your terms.',
            'author': 'Names of creators/contributors. Use “Last, First” for browse; quotes for exact phrases.',
            'author browse (a-z) sorted by name': 'Browse authors alphabetically by name (use “Last, First”).',
            'author browse (a-z) sorted by title': 'Browse authors alphabetically, results grouped by title.',
            'subject': 'Library-assigned subject headings (broader/more precise than keywords).',
            'subject browse (a-z)': 'Browse subjects alphabetically; try broad terms.',
            'call number': 'Find items by call number; nearby results show related topics.',
            'series': 'Series title (e.g., “Lecture Notes in Computer Science”).',
            'publisher': 'Publisher name.',
            'place of publication': 'Geographic place of publication.',
            'publisher number/other identifier': 'Publisher or other identifying numbers.',
            'isbn/issn': 'Standard identifiers: ISBN for books; ISSN for serials.',
            'notes': 'Notes fields (e.g., contents, description).',
            'donor name': 'Name of a donor associated with the item.'
        };

// Extra high-level tips you referenced
        var TIP_MISC = {
            basic: 'General keyword search. Use quotes for exact phrases. Truncation/wildcards not supported; common suffixes are auto-searched (star → stars, starred, starring).',
            facets: 'After searching, use facets (left side) to refine by date, language, format, location, etc.',
            expand: 'Not finding it? Use “Looking for more” to search WorldCat (Libraries Worldwide) or Articles & Full Text.',
            save: 'Select items in results, then use “Selected Items” to print, email, or export (EndNote/RIS).'
        };

// ---- Dynamic updater ----
        function updateDynamicTip(target) {
            if (!target) return false;
            var dyn = target.getAttribute('data-help-dynamic');
            if (!dyn) return false;

            // op_row[]
            if (dyn === 'op') {
                var val = target.value; // AND/OR/begins_with/phrase
                if (TIP_OP[val]) {
                    content.textContent = TIP_OP[val];
                    return true;
                }
            }

            // boolean_row[]
            if (dyn === 'bool') {
                var bval = target.value; // AND/OR/NOT
                if (TIP_BOOL[bval]) {
                    content.textContent = TIP_BOOL[bval];
                    return true;
                }
            }

            // search_field_row[] (by option text)
            if (dyn === 'field') {
                var label = target.options[target.selectedIndex]?.text || '';
                var key = norm(label);
                if (TIP_FIELD[key]) {
                    content.textContent = TIP_FIELD[key];
                    return true;
                }
            }

            return false;
        }

// Hook dynamic updates:
// 1) on change
        document.addEventListener('change', function(e) {
            if (!open) return;
            if (e.target.matches('[data-help-dynamic]')) {
                if (!updateDynamicTip(e.target)) {
                    // fall back to static data-help
                    updateHelpFrom(e.target);
                }
            }
        }, true);

// 2) on hover/focus/click, prefer dynamic if present
        var prevUpdateHelpFrom = updateHelpFrom;
        updateHelpFrom = function(el) {
            if (el && el.closest('[data-help-dynamic]')) {
                if (updateDynamicTip(el.closest('[data-help-dynamic]'))) return;
            }
            prevUpdateHelpFrom(el);
        };


        drawer   = document.getElementById('help-drawer');
        backdrop = document.getElementById('help-backdrop');
        toggleBtn= document.getElementById('help-toggle');
        closeBtn = document.getElementById('help-close');
        content  = document.getElementById('help-content');
        form     = document.getElementById('advanced-search-form');

        if (!drawer || !toggleBtn) return;

        toggleBtn.addEventListener('click', function (e) {
            e.preventDefault();
            open ? closeDrawer() : openDrawer();
        });

        closeBtn && closeBtn.addEventListener('click', function () { closeDrawer(); });
        backdrop && backdrop.addEventListener('click', function () { closeDrawer(); });

        // Event delegation so dynamically-added rows work automatically
        document.addEventListener('mouseover', onPointerOver, true);
        document.addEventListener('focusin', onFocusIn, true);
        document.addEventListener('click', onClickInside, true);
        document.addEventListener('keydown', onKeyDown, true);
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
