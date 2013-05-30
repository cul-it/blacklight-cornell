`if (!Object.keys) Object.keys = function(o) {
  if (o !== Object(o))
    throw new TypeError('Object.keys called on a non-object');
  var k=[],p;
  for (p in o) if (Object.prototype.hasOwnProperty.call(o,p)) k.push(p);
  return k;
}
`
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
    headingWidth = this.availabilityHeading.width()
    $.fn.spin.presets.holdings =
      lines: 9,
      length: 4,
      width: 3,
      radius: 4,
      color: '#b31b1b'
      left: headingWidth - (headingWidth/3)
    this.availabilityHeading.spin('holdings')

  # Define calls to holding service. Called on page load
  bindHoldingService: () ->
    # Using body class as selector to make these triggers page specific
    # appears to be an acceptable approach (one of several) in Rails 3
    # with Assets Pipeline. More info here:
    # http://railsapps.github.com/rails-javascript-include-external.html
    bibids = []
    tibids = []
    batchf = 4 
    n = 0
    $('body.blacklight-catalog-index .document, body.blacklight-bookmarks-index .document').each ->
      bibId = $(this).data('bibid')
      tibids.push bibId
      n++
      if ((n % batchf) == 0) 
        bibids.push tibids
        tibids = []
      #holdings.loadHoldingsShort(bibId)

    if tibids.length > 0
      bibids.push tibids
    for b in bibids 
      holdings.loadHoldingsShortm (b.join('/'))
      
    $('body.blacklight-catalog-show .holdings, body.blacklight-bookmarks-show .holdings').each ->
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

  xxxloadHoldingsShort: (id) ->
    $.ajax
      url: '/backend/holdings_shorth/' + id
      success: (data) ->
        $('#blacklight-avail-'+id).html(data)
      error: (data) ->
        $('#blacklight-avail-'+id).html('<i class="icon-warning-sign"></i> <span class="location">Unable to retrieve availability</span>')

  loadHoldingsShortm: (id) ->
    $.ajax
      dataType: "json"
      url: '/backend/holdings_shorthm/' + id
      success: (data) ->
        bids = Object.keys(data)
        for i in bids 
          $('#blacklight-avail-'+i).html(data[i])
      error: (data) ->
        bids = Object.keys(data)
        for i in bids 
          $('#blacklight-avail-'+i).html('<i class="icon-warning-sign"></i> <span class="location">Unable to retrieve availability</span>')

  # Event listener called on page load
  bindEventListener: () ->
    $('.retry-availability').click ->
      holdings.loadSpinner()
      holdings.loadHoldings($('body.blacklight-catalog-show .holdings').data('bibid'))
      return false

$(document).ready ->
  holdings.onLoad()
