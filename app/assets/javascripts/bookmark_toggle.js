// This file is copied from blacklight gem for the sole purpose of changing
// "Bookmark" language to "Selected items"

//= require blacklight/core
//= require blacklight/checkbox_submit
(function($) {
//change form submit toggle to checkbox
    Blacklight.do_bookmark_toggle_behavior = function() {
      $(Blacklight.do_bookmark_toggle_behavior.selector).bl_checkbox_submit({
          checked_label: "Selected",
          unchecked_label: "Select",
          progress_label: "Saving...",
          //css_class is added to elements added, plus used for id base
          css_class: "toggle_bookmark"
      });
    };
    Blacklight.do_bookmark_toggle_behavior.selector = "form.bookmark_toggle";

$(document).ready(function() {
  Blacklight.do_bookmark_toggle_behavior();
});


})(jQuery);
