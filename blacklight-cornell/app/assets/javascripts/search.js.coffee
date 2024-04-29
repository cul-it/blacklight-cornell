# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
search =
  # Initial setup
  onLoad: () ->
    this.initObjects()
    this.bindEventListener()

  # Create references to frequently used elements for convenience
  initObjects: () ->
    this.paneToggle = $('.display-toggle')

  # Event listener called on page load
  bindEventListener: () ->
    this.paneToggle.on('switch-change', this.toggleDisplay)

  # Toggle between dynamic and fixed panes
  toggleDisplay: () ->
    $('#toggle-panes').submit()
    return false

$(document).ready ->
  search.onLoad()
