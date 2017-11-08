`if (!Object.keys) Object.keys = function(o) {
  if (o !== Object(o))
    throw new TypeError('Object.keys called on a non-object');
  var k=[],p;
  for (p in o) if (Object.prototype.hasOwnProperty.call(o,p)) k.push(p);
  return k;
}
function checkVisible(elm) {
  var rect = elm.getBoundingClientRect();
  var viewHeight = Math.max(document.documentElement.clientHeight, window.innerHeight);
  return !(rect.bottom < 0 || rect.top - viewHeight >= 0);
}
`

inviews = []

holdings =
  # Initial setup
  onLoad: () ->
    this.initObjects()
    this.loadSpinner()
    this.bindHoldingService()
    this.bindEventListener()

  # Create references to frequently used elements for convenience
  initObjects: () ->
    this.availabilityHeading = $('.XXavailability h3')
    this.resultsAvailability = $('.preloader')

  # Add spinners to indicate that data is loading
  loadSpinner: () ->
    # Search results view
    this.resultsAvailability.each ->
        elWidth = $(this).width()
        $.fn.spin.presets.holdings =
          lines: 9,
          length: 3,
          width: 2,
          radius: 3,
          top: 2,
          left: elWidth + 5
        $(this).spin('holdings')

    # Item view
    this.availabilityHeading.each ->
      headingWidth = $(this).width()
      $.fn.spin.presets.holdings =
        lines: 9,
        length: 4,
        width: 3,
        radius: 4,
        color: '999',
        left: headingWidth - (headingWidth/3)
      $(this).spin('holdings')

  loadHoldingsShortmInv: (id) ->
    $.ajax
      dataType: "json"
      url: '/backend/holdings_shorthm/' + id
      success: (data) ->
        bids = Object.keys(data)
        inv = (i for i in inviews when i.bibs is id)[0]
        if inv && inv.waypoint
          inv.waypoint.destroy()
        for i in bids
          $('#blacklight-avail-'+i).html(data[i])
      error: (data) ->
        # If holdings service is unavailable, create array of batched bibs
        # from original string sent to service
        bids = id.split('/')
        $.each bids, (i, bibid) ->
          $('#blacklight-avail-'+bibid).html('<i class="fa fa-warning"></i> <span class="location">Unable to retrieve availability</span>')

  # Define calls to holding service. Called on page load
  bindHoldingService: () ->
    # Using body class as selector to make these triggers page specific
    # appears to be an acceptable approach (one of several) in Rails 3
    # with Assets Pipeline. More info here:
    # http://railsapps.github.com/rails-javascript-include-external.html
    tibids = []
    that = this
    batchf = 4
    n = 0
    $('body.book_bags-index .document,  body.catalog-index .document, body.bookmarks-index .document, .bento_item').each ->
      bibId = $(this).data('bibid')
      online = $(this).data('online')
      atl = $(this).data('atl')
      if !online?
        online = 'no'
      if  (bibId? and atl == 'yes')
        tibids.push bibId
        that = this
        n++
      if ((n % batchf) == 0 )
        $(this).data("showbibs",tibids.join('/'))
        first = tibids[0]
        showbibs =  $(this).data("showbibs")
        tibids = []
        if (showbibs != '')
          if (checkVisible(this))
            holdings.loadHoldingsShortmInv(showbibs)
          else
            inview = new Waypoint.Inview({
              element: $('#blacklight-avail-'+first)
              entered:  (direction) -> holdings.loadHoldingsShortmInv(showbibs)
            })
            inviews.push { bibs: showbibs, waypoint: inview}
    # remainder that were not processed in above  loop
    if tibids.length > 0
      $(that).data("showbibs",tibids.join('/'))
      showbibs =  $(that).data("showbibs")
      first = tibids[0]
      tibids = []
      if (showbibs != '')
        inview = new Waypoint.Inview({
          element: $('#blacklight-avail-'+first)
          entered:  (direction) -> holdings.loadHoldingsShortmInv(showbibs)
         })
        inviews.push { bibs: showbibs, waypoint: inview}

  loadHoldings: (id) ->
    $(".holdings .holdings-error").hide()

    $.ajax
      type: "POST"
      url: '/backend/holdings/' + id
      data: { counter: $("#id_current_counter").text() }
      success: (data) ->
        $('.holdings').html(data)
        # Need to setup modal again for injected share links
        Blacklight.setup_modal("a.lightboxLink", "#ajax-modal form.ajax_form", true);
      error: (data) ->
        $('.holdings').html('<div class="holdings-error"><i class="fa fa-warning"></i> Unable to retrieve availability <a href="#" class="retry-availability">Retry?</a></div>')
        # Bind event listener for retry link
        holdings.bindEventListener()
      complete: (data) ->
        # Stop and remove the spinner
        holdings.availabilityHeading.spin(false)

  xxxloadHoldingsShort: (id) ->
    $.ajax
      url: '/backend/holdings_shorth/' + id
      success: (data) ->
        $('#blacklight-avail-'+id).html(data)
      error: (data) ->
        $('#blacklight-avail-'+id).html('<i class="fa fa-warning"></i> <span class="location">Unable to retrieve availability</span>')
      complete: (data) ->
        # Stop and remove the spinner
        holdings.resultsAvailability.spin(false)


  loadHoldingsShortm: (id) ->
    $.ajax
      dataType: "json"
      url: '/backend/holdings_shorthm/' + id
      success: (data) ->
        bids = Object.keys(data)
        for i in bids
          $('#blacklight-avail-'+i).html(data[i])
      error: (data) ->
        # If holdings service is unavailable, create array of batched bibs
        # from original string sent to service
        bids = id.split('/')
        $.each bids, (i, bibid) ->
          $('#blacklight-avail-'+bibid).html('<i class="fa fa-warning"></i> <span class="location">Unable to retrieve availability</span>')

  # Event listener called on page load
  bindEventListener: () ->
    $('.retry-availability').click ->
      holdings.loadSpinner()
      holdings.loadHoldings($('body.blacklight-catalog-show .holdings').data('bibid'))
      return false

    # Set up 'loading' spinner for when request button is clicked
    $('#id_request').click (e) ->
      e.preventDefault()
      e.stopPropagation()
      $.fn.spin.presets.requesting =
        lines: 9,
        length: 3,
        width: 2,
        radius: 6,
      $('#request-loading-spinner').spin('requesting')
      # Next line is necessary to get spinner to appear. If there is no
      # delay before the redirect, it simply does not happen.
      setTimeout (-> window.location.href=$('#id_request').attr('href')), 100

$(document).ready ->
  holdings.onLoad()
  $(".holdings").on "click", "#id_request", (event) ->
    f = document.createElement("form")
    f.style.display = "none"
    @parentNode.appendChild f
    f.method = "POST"
    f.action = $(this).attr("href")
    f.target = "_blank"  if event.metaKey or event.ctrlKey
    d = document.createElement("input")
    d.setAttribute "type", "hidden"
    d.setAttribute "name", "counter"
    d.setAttribute "value", $(this).data("counter")
    f.appendChild d
    m = document.createElement("input")
    m.setAttribute "type", "hidden"
    m.setAttribute "name", "_method"
    m.setAttribute "value", "put"
    f.appendChild m
    m = document.createElement("input")
    m.setAttribute "type", "hidden"
    m.setAttribute "name", $("meta[name=\"csrf-param\"]").attr("content")
    m.setAttribute "value", $("meta[name=\"csrf-token\"]").attr("content")
    f.appendChild m
    f.submit()
    false
