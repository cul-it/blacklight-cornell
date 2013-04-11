requests =
  # Initial setup
  onLoad: () ->
    this.bindEventListeners()

  # Event listeners. Called on page load
  bindEventListeners: () ->
    # Listeners for request button (submit request)
    $('#requests_button').click ->
      this.preventDefault()
      requests.formSetup()

    $('#req').submit ->
      return false

    # Listener for most types of requests
    $('#request-submit').click ->
      requests.submitForm()
      return false

    # Listener for purchase requests
    $('#purch-request-submit').click ->
      requests.submitPurchaseForm()
      return false

  # Get initial data for form
  formSetup: () ->
    pathComponents = window.location.pathname.split('/')
    id = pathComponents.pop()
    $.get "/backend/request_item/" + id, (data,status) ->
      $("#requests_button").hide()
      $("#delivery_option").html(data)

  # Submit form via AJAX
  submitForm: () ->
    hu = $('#req').attr('action')
    reqnna = ''
    reqnna = $('form [name="latest-date"]:radio:checked').val()
    if reqnna  == 'undefined-undefined-undefined'
      reqnna = ''
    $.ajax
      type: 'POST',
      data: $('#req').serialize(),
      url:hu,
      success: (data) ->
        # Make sure we're at the top of the page so the flash messge is visible
        $('html,body').animate({scrollTop:0},0)
        # Clear page on successful submission
        if data.indexOf('alert-success') != -1
          $('.request-type, .item-title-request, .request-author, #req').remove()
        $('.flash_messages').replaceWith(data)

  # Submit purchase form via AJAx
  # -- nac26 2013-04-10: I see no reason why we need both of these submit functions
  # -- will consult with Matt before refactoring
  submitPurchaseForm: () ->
    hu = $('#req').attr('action')
    $.ajax
      type: 'POST',
      data:
        'name':         $('#reqname').val(),
        'email':        $('#reqemail').val(),
        'status':       $('#reqstatus').val(),
        'title':        $('#reqtitle').val(),
        'author':       $('#reqauthor').val(),
        'series':       $('#reqseries').val(),
        'publication':  $('#reqpublication').val(),
        'identifier':   $('#reqidentifier').val(),
        'comments':     $('#reqcomments').val(),
        'notify':       $('#reqnotify').val(),

        "request_action": $("#request_action").val()
      url: hu,
      dataType: 'json',
      success: (data) ->
        st = data.status
        desc = (st == 'success') ? 'succeeded' : 'failed'
        act_desc = ($("#request_action").val() == 'callslip') ? 'delivery' : $("#request_action").val()
        $('#result').html("Your request for " + act_desc + " has " + desc)

$(document).ready ->
  requests.onLoad()
