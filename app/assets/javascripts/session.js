
function sessionAlert() {
    ref = confirm("Press OK to refresh session.");
    if (ref)  location.reload(true);
}
window.setTimeout(sessionAlert, 1000*60*4);
