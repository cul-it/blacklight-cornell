utils =
  # Initial setup
  onLoad: () ->
    this.initObjects()
    this.bindEventListener()
    this.measureHeader()
    this.stickIt()

  # Create references to frequently used elements for convenience
  initObjects: () ->
    this.stickyHeader = $('#sticky-header')

  # Event listener called on page load
  bindEventListener: () ->
    $('.hierarchical').hover ->
      utils.toggleHierarchy(this)
    $(window).resize () ->
      utils.measureHeader()

  # Add class to mimic anchor hover state for ancestors in hierarchy
  toggleHierarchy: (activeLink) ->
    $(activeLink).prevUntil('br').toggleClass('active-hierarchy')

  # Set the wrapper to the height of the sticky header to avoid bouncing/fluttering
  measureHeader: () ->
    $("#sticky-header-wrapper").height(this.stickyHeader.height())

  # Affix the blacklight nav to the top of the page once you scroll past the header
  stickIt: () ->
    this.stickyHeader.affix(offset: 100)

$(document).ready ->
  utils.onLoad()
