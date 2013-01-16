$(document).ready ->
  # Using body class as selector to make these triggers page specific
  # appears to be an acceptable approach (one of several) in Rails 3
  # with Assets Pipeline. More info here:
  # http://railsapps.github.com/rails-javascript-include-external.html
  $('body.blacklight-catalog-index .document, body.blacklight-bookmarks-index .document').each ->
    bibId = $(this).data('bibid')
    load_holdings_short(bibId)

  $('body.blacklight-catalog-show .holdings').each ->
    bibId = $(this).data('bibid')
    load_holdings(bibId);

root = exports ? this
root.load_holdings = (id) ->
  $("holding-spinner").show()
  $(".holdings .holdings-error").hide()

  $.ajax
    url: '/backend/holdings/' + id

    success: (data) ->
        $("#holding-spinner").hide()
        $('.holdings').html(data)

    error: (data) ->
        $("#holding-spinner").hide()
        $('.holdings .holdings-error').show()

root.load_holdings_short = (id) ->
  $.ajax
    url: '/backend/holdings_shorth/' + id
    success: (data) ->
        $('#blacklight-avail-'+id).html(data)
    error: (data) ->
        $('#blacklight-avail-'+id).html('<i class="icon-warning-sign"></i> <span class="location">Unable to retrieve availability</span>')
