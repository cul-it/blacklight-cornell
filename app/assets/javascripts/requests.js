$(document).ready(function() {
  $("#requests_button").click(function(event) {
    event.preventDefault();
    pathComponents = window.location.pathname.split('/');
    id = pathComponents.pop();
    $.get("/backend/request_item/" + id,function(data,status){
      $("#requests_button").hide();
      $("#delivery_option").html(data);
    });
  });
});