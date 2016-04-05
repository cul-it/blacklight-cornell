$('#browse_type').on('change', function() {
    var placeholder = $(this).find(':selected').data('placeholder');
    $('#authq').attr('placeholder', placeholder);
});