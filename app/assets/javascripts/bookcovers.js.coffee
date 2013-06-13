bookcovers =
  # Initial setup
  onLoad: () ->
    this.initObjects()
    this.fetchCovers()

  # Create references to frequently used elements for convenience
  initObjects: () ->
    this.results = $('.bookcover')

  # Retrieve covers via Google API
  fetchCovers: () ->
    resultsIsbn = []
    this.results.each ->
      isbn = $(this).data('isbn')
      if (isbn)
        resultsIsbn.push(isbn)

    url = "http://books.google.com/books?bibkeys=#{resultsIsbn}&jscmd=viewapi&callback=?"
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
          '<img class="bookcover img-polaroid" src="' + thumbnail + '">'

$(document).ready ->
  bookcovers.onLoad()
