var $loading = $('#loadingSpinner').hide();

$(".citationLink").click(function(){
    $loading.show();
});

$('#blacklight-modal').on('shown.bs.modal', function (e) {
    $loading.hide();
});