// For musical recordings, used to bring in metadata from the Discogs site.
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
              // console.log("getDiscogsDetails complete");
          }
        }); 
    }
}