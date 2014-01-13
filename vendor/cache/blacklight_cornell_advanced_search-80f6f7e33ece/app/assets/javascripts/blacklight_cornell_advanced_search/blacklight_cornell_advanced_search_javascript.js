$(document).ready(function() {

  /* Stuff for handling the checkboxes */
  /* When you click a checkbox, update readout */


  /* Pass in a jquery obj holding the "selected facet element" spans,  get back
     a string for display representing currently checked things. */
  function checkboxesToString(checkbox_elements) {
    var selectedLabels = new Array();
    checkbox_elements.each(function() {
        if ($(this).is(":checked")) {
          selectedLabels.push( $(this).next('.facet-value').text());
        }
    });
    return selectedLabels.join(" OR ");
  }

  //Pass in JQuery object of zero or more <div class="facet_item"> blocks,
  //that contain an h3, some checkboxes, and a span.adv_facet_selections for
  //display of current selections. Will update the span.
  function updateSelectedDisplay(facet_item) {
    var checkboxes = $(facet_item).find("input:checkbox");
    var displaySpan = $(facet_item).find("span.adv_facet_selections");
    var displayStr = checkboxesToString( checkboxes );

    displaySpan.text( displayStr );
    if (displayStr == "") {
      displaySpan.hide();
    } else {
      displaySpan.show();
    }


  }

  // on page load, set initial properly
  $(".facet_item").each(function() {
      updateSelectedDisplay(this);
  });

  //change on checkbox change
  $(".facet_item input:checkbox").change( function() {
      updateSelectedDisplay( $(this).closest(".facet_item"));
  });


});
