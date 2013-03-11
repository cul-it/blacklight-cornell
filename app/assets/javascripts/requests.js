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

  // Form submit handler for most types of requests
  $('#request-submit').click(function(e) {
    var hu = $('#req').attr('action');// + '/' + $('#pickup-locations').val();
    $('#result').html("Working....");
    var reqnna = '';
    //reqnna =  $('#year').val()+"-"+$('#mo').val()+"-"+$('#da').val();
    reqnna = $('form [name="latest-date"]:radio:checked').val();
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

  // Form submit handler for purchase requests 
  $('#purch-request-submit').click(function(e) {

    var hu = $('#req').attr('action');// + '/' + $('#pickup-locations').val();
    $('#result').html("Working....");
    // var purchaseRequestForm = $('#req');
    // var formData = JSON.stringify(purchaseRequestForm.serializeArray());
    $.ajax({
      type: 'POST',
      data: {
        'name':         $('#reqname').val(),
        'email':        $('#reqemail').val(), 
        'status':       $('#reqstatus').val(),     
        'title':        $('#reqtitle').val(),  
        'author':       $('#reqauthor').val(),
        'series':       $('#reqseries').val(),
        'publication':  $('#reqpublication').val(),
        'identifier':   $('#reqidentifier').val(),
        'comments':     $('#reqcomments').val(),
        'notify':       $('#reqnotify').val(),

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