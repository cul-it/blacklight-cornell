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
    var footerHeight = $('footer').height();
    $('.navbar-fixed-bottom').css({bottom: footerHeight});
  }
  else $('.navbar-fixed-bottom').css({bottom:'0'})
});
