function sessionAlert() {
    bootbox.confirm({
    message: "Press OK to refresh session. Otherwise it will reset in 30 seconds.",
    backdrop: true,
    buttons: {
        confirm: {
            label: 'Yes',
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
window.setTimeout(sessionAlert, (1000*60*60*4)-(30*1000));
