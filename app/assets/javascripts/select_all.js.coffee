$(window).load ->
  window.select_all_manager = new SelectAllManager
class SelectAllManager
  constructor: ->
    @element = $("#select_all_input")
    this.prepopulate_value()
    this.bind_element()
  prepopulate_value: ->
    if $("input.toggle-bookmark:checked").length == $("input.toggle-bookmark").length
      @element.prop('checked', true)
    else
      @element.prop('checked', false)
  bind_element: ->
    parent = this
    $("input.toggle-bookmark").click ->
      unless this.checked
        parent.element.prop('checked', false)
      else
        parent.prepopulate_value()
    @element.change ->
      if this.checked
        parent.bookmark_all()
      else
        parent.unbookmark_all()
  bookmark_all: ->
    $("input.toggle-bookmark:not(:checked)").click()
  unbookmark_all: ->
    $("input.toggle-bookmark:checked").click()
