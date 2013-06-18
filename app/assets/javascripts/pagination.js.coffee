# Extend jQuery to determine how many pixels are below the passed element
$.fn.scrollBottom = () ->
  return $(document).height() - this.scrollTop() - this.height()

pagination =
  # Initial setup
  onLoad: () ->
    this.initObjects()
    # Only add the event listeners if sticky pagination exists
    if this.sticky.length
      this.bindEventListeners()

  # Create references to frequently used elements for convenience
  initObjects: () ->
    this.sticky = $('#sticky')

  # Event listeners. Called on page load
  bindEventListeners: () ->
    $(window).scroll ->
      windowBottom = $(window).scrollBottom()
      footerHeight = $('footer').height()

      if footerHeight > windowBottom
        # Footer is visible, so keep sticky pagination pinned above it
        diff = footerHeight - windowBottom
        pagination.sticky.css({bottom: diff})
      else
        # Otherwise keep pagination pinned at bottom of window
        pagination.sticky.css({bottom:'0'})

$(document).ready ->
  pagination.onLoad()
