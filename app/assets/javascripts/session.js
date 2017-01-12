
function sessionAlert() {
    ref = confirm("Press OK to refresh session. Otherwise it will reset in 30 seconds.");
    if (ref)  location.reload(true);
}
window.setTimeout(sessionAlert, (1000**60*60*4)-(30*1000));
