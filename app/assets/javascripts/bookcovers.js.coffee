bookcovers =
  # Initial setup
  onLoad: () ->
    this.initObjects()
    this.fetchCoversOclc()

  # Create references to frequently used elements for convenience
  initObjects: () ->
    this.results = $('.bookcover')

  # Retrieve covers via Google API using OCLC #
  fetchCoversOclc: () ->
    resultsOclc = []
    this.results.each ->
      oclc = 'OCLC:' + $(this).data('oclc')
      if (oclc)
        resultsOclc.push(oclc)

    url = "https://books.google.com/books?bibkeys=#{resultsOclc}&jscmd=viewapi&callback=?"
    $.getJSON url, {}, this.insertCoversOclc

  # Insert covers into the page using OCLC #
  insertCoversOclc: (data) ->
    for id, values of data
      divId = values.bib_key.replace(':', '\\:') # Need to escape colon for jQuery
      thumbnail = values.thumbnail_url
      if (thumbnail)
        # Default response returns smallest thumbnail, swap out with largest
        thumbnail = values.thumbnail_url.replace('zoom=5','zoom=1')
        $("##{divId}").replaceWith ->
          '<img class="bookcover img-polaroid" alt="" src="' + thumbnail + '">'

  # Retrieve covers via Google API
  fetchCovers: () ->
    resultsIsbn = []
    this.results.each ->
      isbn = $(this).data('isbn')
      if (isbn)
        resultsIsbn.push(isbn)

    url = "https://books.google.com/books?bibkeys=#{resultsIsbn}&jscmd=viewapi&callback=?"
    $.getJSON url, {}, this.insertCovers

  # Insert covers into the page
  insertCovers: (data) ->
    for id, values of data
      divId = 'isbn_' + values.bib_key
      thumbnail = values.thumbnail_url
      if (thumbnail)
        # Default response returns smallest thumbnail, swap out with largest
        thumbnail = values.thumbnail_url.replace('zoom=5','zoom=1')
        $("##{divId}").replaceWith ->
          '<img class="bookcover img-polaroid" alt="" src="' + thumbnail + '">'

$(document).ready ->
  bookcovers.onLoad()
