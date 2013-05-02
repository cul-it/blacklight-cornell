function getDocHeight() {
    var D = document;
    return Math.max(
        Math.max(D.body.scrollHeight, D.documentElement.scrollHeight),
        Math.max(D.body.offsetHeight, D.documentElement.offsetHeight),
        Math.max(D.body.clientHeight, D.documentElement.clientHeight)
    );
}

$(window).scroll(function() {
   if($(window).scrollTop() + $(window).height() == getDocHeight()) {
       $('.navbar-fixed-bottom').css({bottom:'100px'});
   }
   else $('.navbar-fixed-bottom').css({bottom:'0px'})
});
