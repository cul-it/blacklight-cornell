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
    console.log(resultsIsbn)

    url = "http://books.google.com/books?bibkeys=#{resultsIsbn}&jscmd=viewapi&callback=?"
    console.log(url)
    $.getJSON url, {}, this.insertCovers

  # Insert covers into the page
  insertCovers: (data) ->
    for id, values of data
      imgId = 'isbn_' + values.bib_key
      console.log(imgId)
      $("##{imgId}").attr("src", values.thumbnail_url)

$(document).ready ->
  bookcovers.onLoad()
