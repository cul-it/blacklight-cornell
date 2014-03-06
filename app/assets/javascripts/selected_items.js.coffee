selectedItems =
  # Initial setup
  onLoad: () ->
    this.overrideBlacklightDefaults()

  # Pass options to Blacklight bl_checkbox_submit jQuery plugin
  # -- see checkbox_submit.js for details
  overrideBlacklightDefaults: () ->
    $('form.list_toggle').bl_checkbox_submit
      checked_label: "Selected",
      unchecked_label: "Select",
      progress_label: "Saving...",
      # css_class is added to elements added, plus used for id base
      css_class: "toggle_list",
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

    $('form.bookmark_toggle_all').bl_checkbox_submit
       checked_label: "Remove all",
       unchecked_label: "Select all",
       progress_label: "Saving...",
       css_class: "toggle_all_bookmarks",
       
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
            newCount = currentCount + (parseInt($("input[type=checkbox]").length) - parseInt($("input[type=checkbox]:checked").length)) - 1 
          else if currentCount > 0
            newCount = currentCount - parseInt($("input[type=checkbox]").length) + 2 #parseInt($("input[type=checkbox]:checked").length) 
#  #        if($("input[type=checkbox]:checked").length > 0)
#  #          alert("testing1 " + $("input[type=checkbox]").length);
#  #          return true;
#  #          alert("testing2" + $("input[type=checkbox]").length);
#  #          return false;
          if newCount > 0
            selectedItems.html('(' + newCount + ')')
          else
            selectedItems.empty()
           

$(document).ready ->
  selectedItems.onLoad()

