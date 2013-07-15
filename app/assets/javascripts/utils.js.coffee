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

$(document).ready ->
  utils.onLoad()
