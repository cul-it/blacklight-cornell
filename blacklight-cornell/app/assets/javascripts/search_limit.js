Blacklight.onLoad( function() {
    if ( $('body').prop('className').indexOf("catalog-index") >= 0 ) {
        if ( search_exceeded ) {
            $("a[rel='next']").hide();
            current_page_found = false;
            $('ul.pagination li').each(function() {
                if ( current_page_found == true ) {
                    $(this).hide();
                }
                else if ( $(this).find('span').attr("aria-current") == "true" ) {
                    current_page_found = true;
                }
            });
        }
        
    }
});