holdings =
  # Initial setup
  onLoad: () ->
    this.initObjects()
    this.loadSpinner()
    this.bindHoldingService()
    this.bindEventListener()

  # Create references to frequently used elements for convenience
  initObjects: () ->
    this.availabilityHeading = $('.availability h3')

  # Add a spinner to indicate that data is loading
  loadSpinner: () ->
    $.fn.spin.presets.holdings =
      lines: 9,
      length: 4,
      width: 3,
      radius: 4,
      color: '#b31b1b'
    this.availabilityHeading.spin('holdings')

  # Define calls to holding service. Called on page load
  bindHoldingService: () ->
    # Using body class as selector to make these triggers page specific
    # appears to be an acceptable approach (one of several) in Rails 3
    # with Assets Pipeline. More info here:
    # http://railsapps.github.com/rails-javascript-include-external.html
    $('body.blacklight-catalog-index .document, body.blacklight-bookmarks-index .document').each ->
      bibId = $(this).data('bibid')
      holdings.loadHoldingsShort(bibId)

    $('body.blacklight-catalog-show .holdings').each ->
      bibId = $(this).data('bibid')
      holdings.loadHoldings(bibId)

  loadHoldings: (id) ->
    $(".holdings .holdings-error").hide()

    $.ajax
      url: '/backend/holdings/' + id
      success: (data) ->
        $('.holdings').html(data)
        # Need to setup modal again for injected share links
        Blacklight.setup_modal("a.lightboxLink", "#ajax-modal form.ajax_form", true);
      error: (data) ->
        $('.holdings .holdings-error').show()
      complete: (data) ->
        # Stop and remove the spinner
        holdings.availabilityHeading.spin(false)

  loadHoldingsShort: (id) ->
    $.ajax
      url: '/backend/holdings_shorth/' + id
      success: (data) ->
        $('#blacklight-avail-'+id).html(data)
      error: (data) ->
        $('#blacklight-avail-'+id).html('<i class="icon-warning-sign"></i> <span class="location">Unable to retrieve availability</span>')

  # Event listener called on page load
  bindEventListener: () ->
    $('.retry-availability').click ->
      holdings.loadSpinner()
      holdings.loadHoldings($('body.blacklight-catalog-show .holdings').data('bibid'))
      return false

$(document).ready ->
  holdings.onLoad()
