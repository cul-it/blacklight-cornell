// #########################################################
// ##  Advanced Search Publication Year Range Validation  ##
// #########################################################

// Circle exclamation icon
const createAlertIconMarkup = () => `<svg class="advanced-search-alert__icon" viewBox="0 0 16 16" xmlns="http://www.w3.org/2000/svg" aria-hidden="true"><path fill="currentColor" d="M8 15A7 7 0 1 1 8 1a7 7 0 0 1 0 14Zm0-4a1 1 0 1 0 0 2 1 1 0 0 0 0-2Zm1-6a1 1 0 1 0-2 0v5a1 1 0 0 0 2 0V5Z"/></svg>`;

// Group row (label + inputs)
const findGroupRow = ($element) => {
    const $group = $element.closest('.blacklight-date-range, fieldset, .range_limit, .form-group, .row');
    return $group.length ? $group : $element.closest('form');
};

// Per-field invalid helpers
const setInvalidState = ($element, message) => {$element.addClass('is-invalid').attr({title: message, 'aria-invalid': 'true'});};
const setValidState = ($element) => {$element.removeClass('is-invalid').removeAttr('title aria-invalid');};

// Treat whole-number years with optional leading minus as valid (1–4 digits)
const isWholeYear = (value) => /^-?\d{1,4}$/.test(String(value || '').trim());

// Suppress ordering errors while the user is still typing in the focused box
const isPartialYearWhileFocused = ($input, value) => {
    if (!$input.is(':focus')) return false;
    const s = String(value || '').trim();
    if (s === '' || s === '-') return true; // just started typing
    const unsigned = s.startsWith('-') ? s.slice(1) : s;
    return /^\d{0,3}$/.test(unsigned); // 0–3 digits while focused counts as "still typing"
};

// IMPORTANT: Avoid JS "1900+year" quirk for years 0–99
const parseDateToUtcMillis = (value) => {
    if (isWholeYear(value)) {
        const year = parseInt(value, 10);
        const d = new Date(0);
        d.setUTCFullYear(year, 0, 1); // preserves years < 100 and negatives
        d.setUTCHours(0, 0, 0, 0);
        return d.getTime();
    }
    const timestamp = Date.parse(value);
    return Number.isNaN(timestamp) ? null : timestamp;
};

// Focus state to control when to show the "both-or-none" error
let startFieldIsFocused = false;
let endFieldIsFocused = false;

const validateDateRange = () => {
    const $startInput = $('#range_pub_date_facet_begin, [data-date-start]').first();
    const $endInput = $('#range_pub_date_facet_end, [data-date-end]').first();
    const $submitButton = $('#advanced_search');

    if ($startInput.length === 0 || $endInput.length === 0 || $submitButton.length === 0) return true;

    // Alert above the whole Publication Year Range section
    const $groupRowElement = findGroupRow($startInput);
    let $dateRangeErrorAlert = $('#date-range-error');
    if ($dateRangeErrorAlert.length === 0) {
        $dateRangeErrorAlert = $(`
        <div id="date-range-error" role="alert" aria-live="polite"
             class="advanced-search-alert" style="display:none">
          ${createAlertIconMarkup()}<span class="msg"></span>
        </div>
      `);
        $groupRowElement.before($dateRangeErrorAlert);
    }

    // Submit button error message above Search
    let $submitButtonErrorMessage = $('#date-range-submit-msg');
    if ($submitButtonErrorMessage.length === 0) {
        $submitButtonErrorMessage = $(`
        <div id="date-range-submit-msg" role="alert" aria-live="polite" class="advanced-search-alert" style="display:none">
          ${createAlertIconMarkup()}
          <span class="msg">Fix the publication year range above to enable Search.</span>
        </div>
      `);
        $submitButton.before($submitButtonErrorMessage);
    }

    const startValue = $.trim($startInput.val() || '');
    const endValue = $.trim($endInput.val() || '');
    const hasStart = !!startValue;
    const hasEnd = !!endValue;
    const anyFieldFocused = startFieldIsFocused || endFieldIsFocused;

    let errorMessage = '';

    // Reset prior per-field states
    setValidState($startInput);
    setValidState($endInput);

    // Show "both-or-none" only when the user has left the pair (no focus on either)
    if ((hasStart ^ hasEnd) && !anyFieldFocused) {
        if (hasStart && !hasEnd) {
            errorMessage = 'Please enter an end date.';
            setInvalidState($endInput, errorMessage);
        } else if (!hasStart && hasEnd) {
            errorMessage = 'Please enter a start date.';
            setInvalidState($startInput, errorMessage);
        }
    }

    // If both present, validate ordering (but skip while a focused field is still being typed)
    if (!errorMessage && hasStart && hasEnd) {
        if (!isPartialYearWhileFocused($startInput, startValue) &&
            !isPartialYearWhileFocused($endInput, endValue)) {
            const startTime = parseDateToUtcMillis(startValue);
            const endTime = parseDateToUtcMillis(endValue);
            if (startTime != null && endTime != null) {
                if (startTime > endTime) {
                    errorMessage = 'Start date must be earlier than or equal to end date.';
                    setInvalidState($startInput, errorMessage);
                    setInvalidState($endInput, errorMessage);
                }
            }
        }
    }

    // Apply group + submit UI state
    if (errorMessage) {
        $dateRangeErrorAlert.find('.msg').text(errorMessage);
        $dateRangeErrorAlert.show();
        $submitButtonErrorMessage.show();
        $submitButton.prop('disabled', true).addClass('is-disabled').attr('aria-disabled', 'true');
        return false;
    } else {
        $dateRangeErrorAlert.hide().find('.msg').text('');
        $submitButtonErrorMessage.hide();
        $submitButton.prop('disabled', false).removeClass('is-disabled').removeAttr('aria-disabled');
        return true;
    }
};

// Wire-up with focus tracking
$(() => {
    const $startInput = $('#range_pub_date_facet_begin, [data-date-start]').first();
    const $endInput = $('#range_pub_date_facet_end, [data-date-end]').first();
    const $submitButton = $('#advanced_search');

    if (!($startInput.length && $endInput.length && $submitButton.length)) return;

    // Initialize
    validateDateRange();

    // Track focus/blur on the pair; defer blur handling to see if focus moved to the other box
    $startInput.on('focusin', () => { startFieldIsFocused = true });
    $startInput.on('focusout', () => {
        startFieldIsFocused = false;
        setTimeout(validateDateRange, 0);
    });

    $endInput.on('focusin', () => { endFieldIsFocused = true });
    $endInput.on('focusout', () => {
        endFieldIsFocused = false;
        setTimeout(validateDateRange, 0);
    });

    // Live checks
    $startInput.on('input change', validateDateRange);
    $endInput.on('input change', validateDateRange);

    // Final gate on submit
    $submitButton.closest('form').on('submit', (event) => { if (!validateDateRange()) event.preventDefault() });
});
