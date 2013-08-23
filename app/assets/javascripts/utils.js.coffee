utils =
  # Initial setup
  onLoad: () ->
    this.bindEventListener()

  # Event listener called on page load
  bindEventListener: () ->
    $('.hierarchical').hover ->
      utils.toggleHierarchy(this)

  # Add class to mimic anchor hover state for ancestors in hierarchy
  toggleHierarchy: (activeLink) ->
    $(activeLink).prevUntil('br').toggleClass('active-hierarchy')

  onLoad: () ->
    measureHeader

  bindEventListener: () ->
    $(window).resize () ->
      measureHeader

  measureHeader:
    ("#sticky-header-wrapper").height $("#sticky-header").height()


$("#sticky-header").affix offset: 100


$(document).ready ->
  utils.onLoad()
