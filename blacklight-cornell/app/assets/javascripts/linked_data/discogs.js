// For musical recordings, this ajax call brings in metadata from the Discogs site.
// The discogs_id variable is set in the show.html.erb template in a javascript_tag.
if ( $('body').prop('className').indexOf("catalog-show") >= 0 ) {
    var remote = true;
    if ( discogs_id != "" ) {
        getDiscogsDetails(discogs_id);
    }
    function getDiscogsDetails(id) {
        $.ajax({
          url : "/get_discogs?id=" + id,
          type: 'GET',
          data: remote,
          complete: function(xhr, status) {
              // We don't have to do anything here. The get_discogs method in the discogs.rb 
              // lib responds with a js format, and that references the get_discogs.js.erb file.
              // Everything is handled there.
          }
        }); 
    }
}