// For musical recordings, used to bring in metadata from the Discogs site.
// The discogs_id variable is set in the show.html.erb template in a javascript_tag.
var remote = true;
getDiscogsDetails(discogs_id)
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
