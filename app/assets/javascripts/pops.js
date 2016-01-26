$('*[data-poload]').click(function() {
    var e=$(this);
     e.off('click');
    $.get(e.data('poload'),function(d) {
        e.popover({content: d, html:true, trigger:'focus'}).popover('show');
    });
});




