$('#search_field').on('change', function() {
    var placeholder = $(this).find(':selected').data('placeholder');
    $('#q').attr('placeholder', placeholder);
});
