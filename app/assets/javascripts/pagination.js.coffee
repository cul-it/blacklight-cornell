// Extend jQuery to determine how many pixels are below the passed element
$.fn.scrollBottom = function() {
  return $(document).height() - this.scrollTop() - this.height();
};

$(document).ready(function() {
  // Make sure "#sticky" element exists
  if ($('#sticky').length) {
    var el = $('#sticky');

    // Scroll event
    $(window).scroll(function() {
      var windowBottom = $(window).scrollBottom();
      var footerHeight = $('footer').height();

      if (footerHeight > windowBottom) {
        // Footer is visible, so keep sticky pagination pinned above it
        var diff = footerHeight - windowBottom;
        el.css({bottom: diff});
      }
      else {
        // Otherwise keep pagination pinned at bottom of window
        el.css({bottom:'0'});
      }
    });
  }
});
