selectedItems =
  # Initial setup
  onLoad: () ->
    this.overrideBlacklightDefaults()

  # Pass options to Blacklight bl_checkbox_submit jQuery plugin
  # -- see checkbox_submit.js for details
  overrideBlacklightDefaults: () ->
    $('form.bookmark_toggle').bl_checkbox_submit
      checked_label: "Selected",
      unchecked_label: "Select",
      progress_label: "Saving...",
      # css_class is added to elements added, plus used for id base
      css_class: "toggle_bookmark",
      # Update the selected items count in the header on successful toggle
      success: (toggleState) ->
        selectedItems = $('#bookmarks-count')
        if selectedItems
          currentVal = $.trim(selectedItems.html()) # Trim whitespace introduced by ruby
          if currentVal
            # Remove parentheses around count and covert string to integer
            currentCount = currentVal.substring(1, currentVal.length - 1)
            currentCount = parseInt(currentCount)
          else
            currentCount = 0

          if toggleState
            newCount = currentCount + 1
          else if currentCount > 0
            newCount = currentCount - 1

          if newCount > 0
            selectedItems.html('(' + newCount + ')')
          else
            selectedItems.empty()

$(document).ready ->
  selectedItems.onLoad()
