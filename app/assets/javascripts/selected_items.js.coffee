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
      css_class: "toggle_bookmark"

$(document).ready ->
  selectedItems.onLoad()
