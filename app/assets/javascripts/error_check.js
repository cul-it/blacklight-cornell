window.addEventListener("error", (event) => {
    var count = parseInt(document.getElementById('js_error_report').innerHTML);
    document.getElementById('js_error_report').innerHTML = ++count;
});