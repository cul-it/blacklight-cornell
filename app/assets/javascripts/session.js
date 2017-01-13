function sessionAlert() {
    bootbox.confirm({
    message: "Press OK to refresh session. Otherwise it will reset in 2 minutes.",
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
