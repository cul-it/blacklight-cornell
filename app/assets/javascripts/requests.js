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
  $('#request-submit').click(function(e) {
    var hu = $('#req').attr('action');// + '/' + $('#pickup-locations').val();
    $('#result').html("Working....");
    var reqnna = '';
    reqnna =  $('#year').val()+"-"+$('#mo').val()+"-"+$('#da').val();
    if (reqnna  == 'undefined-undefined-undefined') {
      reqnna = '';
    }
    $.ajax({
      type: 'POST',
      data: {
        "reqcomments": $('#reqcomments').val(),
        "reqnna": reqnna,
        "bid": $('#bid').val(),
        "library_id": $('#pickup-locations').val(),
        "holding_id": $("#req input[type='radio']:checked").val(),
        "request_action": $("#request_action").val()
      },
      url:hu,
      dataType: 'json',
      success: function(data) {
        var st=data.status;
        var desc= (st == 'success') ? 'succeeded' : 'failed';
        var act_desc= ($("#request_action").val() == 'callslip') ?'delivery':$("#request_action").val();
        $('#result').html("Your request for " + act_desc + " has "+desc);
      }
    });
    return false; // should block the submit
  });
});