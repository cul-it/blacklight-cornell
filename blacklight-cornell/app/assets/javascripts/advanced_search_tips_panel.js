(function () {
    var drawer, backdrop, toggleBtn, content, announcer, form, endSentinel, chevronBtn;
    var open = false;
    var currentHighlighted, lastDescribed;

    // ---------------- Helpers ----------------
    function isEditable(el) {
        if (!el) return false;
        var tag = (el.tagName || '').toLowerCase();
        return (
            tag === 'input' ||
            tag === 'textarea' ||
            el.isContentEditable ||
            (tag === 'select')
        );
    }

    function setDescribedBy(el) {
        if (!el) return;
        if (lastDescribed && lastDescribed !== el) lastDescribed.removeAttribute('aria-describedby');
        el.setAttribute('aria-describedby', content.id);
        lastDescribed = el;
    }

    function announce(txt) {
        // Visible panel can use HTML for styling
        if (!txt) txt = 'No help available for this field.';
        content.innerHTML = txt;

        // Live region stays plain text for screen readers
        announcer.textContent = content.textContent;
    }

    function clearHighlight() {
        if (currentHighlighted) {
            currentHighlighted.classList.remove('help-target');
            currentHighlighted = null;
        }
    }

    function updateHelpFrom(el) {
        var target = el && el.closest('[data-help], [data-help-dynamic]');
        if (!target) return;
        if (currentHighlighted !== target) {
            clearHighlight();
            currentHighlighted = target;
            currentHighlighted.classList.add('help-target');
        }
        if (target.matches('[data-help-dynamic]') && updateDynamicTip(target)) {
            setDescribedBy(el); return;
        }
        announce(target.getAttribute('data-help'));
        setDescribedBy(el);
    }

    // ---------------- Tips ----------------
    var TIP_OP = {
        AND: '<strong class="help-key">All</strong>: Every word in this box must appear (order not required).',
        OR: '<strong class="help-key">Any</strong>: At least one of the words in this box must appear.',
        begins_with: '<strong class="help-key">Begins With</strong>: Matches fields that start with these words.',
        phrase: '<strong class="help-key">Phrase</strong>: Matches all words in this box in this exact order.'
    };

    var TIP_BOOL = {
        AND: '<strong class="help-key">AND</strong>: Results must include terms from this row AND previous rows (narrows).',
        OR: '<strong class="help-key">OR</strong>: Results may include terms from this row OR previous rows (broadens). Put OR rows first.',
        NOT: '<strong class="help-key">NOT</strong>: Exclude records that match this row (narrows by omission).'
    };

    var TIP_FIELD = {
        'all fields': '<strong class="help-key">All fields</strong>: Search anywhere in the record. Great starting point; refine with facets if needed.',
        'title': '<strong class="help-key">Title</strong>: Words in the title of the work.',
        'journal title': '<strong class="help-key">Journal title</strong>: Title of a journal/newspaper/serial (not individual articles).',
        'title begins with': '<strong class="help-key">Title begins with</strong>: Title fields that start with your terms.',
        'author': '<strong class="help-key">Author</strong>: Names of creators/contributors. Use “Last, First” for browse; quotes for exact phrases.',
        'author browse (a-z) sorted by name': '<strong class="help-key">Author browse (A–Z, by name)</strong>: Browse authors alphabetically by name (use “Last, First”).',
        'author browse (a-z) sorted by title': '<strong class="help-key">Author browse (A–Z, by title)</strong>: Browse authors alphabetically, results grouped by title.',
        'subject': '<strong class="help-key">Subject</strong>: Library-assigned subject headings (broader/more precise than keywords).',
        'subject browse (a-z)': '<strong class="help-key">Subject browse (A–Z)</strong>: Browse subjects alphabetically; try broad terms.',
        'call number': '<strong class="help-key">Call number</strong>: Find items by call number; nearby results show related topics.',
        'series': '<strong class="help-key">Series</strong>: Series title (e.g., “Lecture Notes in Computer Science”).',
        'publisher': '<strong class="help-key">Publisher</strong>: Publisher name.',
        'place of publication': '<strong class="help-key">Place of publication</strong>: Geographic place of publication.',
        'publisher number/other identifier': '<strong class="help-key">Publisher number / other identifier</strong>: Publisher or other identifying numbers.',
        'isbn/issn': '<strong class="help-key">ISBN/ISSN</strong>: Standard identifiers: ISBN for books; ISSN for serials.',
        'notes': '<strong class="help-key">Notes</strong>: Notes fields (e.g., contents description).',
        'donor/provenance': '<strong class="help-key">Donor/Provenance</strong>: Name of a donor associated with the item.'
    };

    function norm(s){return String(s||'').trim().toLowerCase();}

    function updateDynamicTip(target) {
        var dyn = target.getAttribute('data-help-dynamic');
        if (!dyn) return false;

        if (dyn === 'op') {
            var v = target.value;
            if (TIP_OP[v]) { announce(TIP_OP[v]); return true; }
        }

        if (dyn === 'bool') {
            var b = target.value;
            if (TIP_BOOL[b]) { announce(TIP_BOOL[b]); return true; }
        }

        if (dyn === 'field') {
            var label = target.options[target.selectedIndex]?.text || '';
            var key = norm(label);
            if (TIP_FIELD[key]) { announce(TIP_FIELD[key]); return true; }
        }
        return false;
    }

    // ------------- Drawer control -------------
    function openDrawer() {
        if (open) return;
        open = true;
        drawer.classList.add('is-open');
        drawer.setAttribute('aria-hidden', 'false');
        backdrop.hidden = false;
        toggleBtn.setAttribute('aria-expanded', 'true');
        chevronBtn && chevronBtn.setAttribute('aria-expanded', 'true');
        document.body.classList.add('help-open');
        updateHelpFrom(document.activeElement);
    }

    function closeDrawer() {
        if (!open) return;
        open = false;
        drawer.classList.remove('is-open');
        drawer.setAttribute('aria-hidden', 'true');
        backdrop.hidden = true;
        toggleBtn.setAttribute('aria-expanded', 'false');
        chevronBtn && chevronBtn.setAttribute('aria-expanded', 'false');
        document.body.classList.remove('help-open');
        if (lastDescribed) lastDescribed.removeAttribute('aria-describedby');
        clearHighlight();
    }

    function toggleDrawer() { open ? closeDrawer() : openDrawer(); }

    // ------------- Events -------------
    function onPointerOver(e){ if (open) updateHelpFrom(e.target); }
    function onFocusIn(e){ if (open) updateHelpFrom(e.target); }
    function onClickInside(e){ if (open) updateHelpFrom(e.target); }

    function onKeyDown(e) {
        // Esc closes
        if (e.key === 'Escape') { closeDrawer(); return; }

        // Enter/Space on toggle buttons
        if ((e.target === toggleBtn || e.target === chevronBtn) &&
            (e.key === 'Enter' || e.key === ' ')) {
            e.preventDefault(); toggleDrawer(); return;
        }

        // CMD + ?  (⌘ + ? ; browsers may report '?' or '/' with shift)
        if (e.metaKey && !e.ctrlKey && !e.altKey) {
            if (e.key === '?' || e.key === '/' /* allow even if shift not reported */) {
                e.preventDefault(); toggleDrawer(); return;
            }
        }

        // SHIFT + ?  (when NOT in an editable field)
        if (!e.metaKey && !e.ctrlKey && !e.altKey) {
            var inEditable = isEditable(e.target);
            var isShiftQuestion = (e.key === '?' || (e.key === '/' && e.shiftKey));
            if (!inEditable && isShiftQuestion) {
                e.preventDefault(); toggleDrawer(); return;
            }
        }
    }

    function init() {
        drawer     = document.getElementById('help-drawer');
        backdrop   = document.getElementById('help-backdrop');
        toggleBtn  = document.getElementById('help-toggle');
        content    = document.getElementById('help-content');
        announcer  = document.getElementById('help-announce');
        form       = document.getElementById('advanced-search-form');
        endSentinel= document.getElementById('form-end-sentinel');
        chevronBtn = document.getElementById('help-chev');

        if (!drawer || !toggleBtn || !content || !announcer) return;

        // Click toggles
        toggleBtn.addEventListener('click', function (e) { e.preventDefault(); toggleDrawer(); });
        chevronBtn && chevronBtn.addEventListener('click', function (e) { e.preventDefault(); toggleDrawer(); });

        // Clicking the PANEL closes it; clicking the page does NOT
        drawer.addEventListener('click', function(){ closeDrawer(); });

        // Live/dynamic updates
        document.addEventListener('mouseover', onPointerOver, true);
        document.addEventListener('focusin', onFocusIn, true);
        document.addEventListener('click', onClickInside, true);

        document.addEventListener('change', function (e) {
            if (!open) return;
            if (e.target.matches('[data-help-dynamic], [data-help]')) {
                if (!updateDynamicTip(e.target)) updateHelpFrom(e.target);
            }
        }, true);

        // Global keyboard (Esc, Enter/Space on buttons, CMD+?, SHIFT+?)
        document.addEventListener('keydown', onKeyDown, true);

        // Tab past form → chevron
        endSentinel && endSentinel.addEventListener('focus', function () {
            if (open && chevronBtn) chevronBtn.focus();
        });
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
