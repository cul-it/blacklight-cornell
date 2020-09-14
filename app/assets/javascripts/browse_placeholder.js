$('#browse_type').on('change', function() {
    var placeholder = $(this).find(':selected').data('placeholder');
    $('#authq').attr('placeholder', placeholder);
});
Blacklight.onLoad(function() {
    if ( $('body').prop('className').indexOf("browse-index") >= 0 ) {
         var placeholder = $('#browse_type').find(':selected').data('placeholder');
         $('#authq').attr('placeholder', placeholder);
         if ( !$('#outer-container').length && $('#authq').val() == "") {
             $('#authq').focus();
         }
    }
});  