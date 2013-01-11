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

  $('#req').submit( function(e) {
    return false;
  });
  $('#request_sumbit').click(function(e) {
    var hu = $('#req').attr('action') + '/' + $('#PICK').val();
    $('#result').html("Working....");
    $.ajax({
      type: 'POST',
      data: {
        "reqnna": $('#year').val()+"-"+$('#mo').val()+"-"+$('#da').val()
      },
      url:hu,
      dataType: 'json',
      success: function(data) {
        var st=data.status;
        var desc= (st == 'success') ? 'succeeded' : 'failed';  
        $('#result').html("Your request for delivery has "+desc);
      }
    });
    return false; // should block the submit
  });
});