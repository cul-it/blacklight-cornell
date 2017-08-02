var sessionCountDown = 120;
var dialog = null;

function sessionUpdateTime() {
    sessionCountDown = sessionCountDown -1 ; 
    if (sessionCountDown != 0 ){
      $("#sess_time").text(sessionCountDown);
      window.setTimeout(sessionUpdateTime, (1000));
    } else  {
      dialog.modal('hide');
      dialog = bootbox.alert({ message:"Your session has expired."});
    } 
}

function sessionAlert() {
    sessionCountDown = sessionCountDown -1 ; 
    window.setTimeout(sessionUpdateTime, (1000));
    dialog = bootbox.confirm({
    message: "<div id='sess_message' >Press OK to refresh session. Otherwise it will reset in <span id='sess_time'> 120</span> seconds",
    backdrop: true,
    buttons: {
        confirm: {
            label: 'OK',
            className: 'btn-success'
        },
        cancel: {
            label: 'No',
            className: 'btn-danger'
        }
    },
    callback: function (result) {
        if (result) { location.reload(true); }
    }
});
}
window.setTimeout(sessionAlert, (1000*60*60*4)-(120*1000));
// for testing
//window.setTimeout(sessionAlert, (1000*30)-(0));
