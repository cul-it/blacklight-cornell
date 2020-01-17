var subjectBrowse = {
  onLoad: function() {
    this.bindCrossRefsToggle();  
  },
  
  bindCrossRefsToggle: function() {
    $("#cr-refs-toggle").click(function() {
      if ( $(".toggled-cr-refs").first().is(":visible") ) {
          $(".toggled-cr-refs").hide();
          $("#cr-refs-toggle").html("more &raquo;");
      }
      else {
          $(".toggled-cr-refs").show();
          $("#cr-refs-toggle").html("&laquo; less");
      }
      return false;
    });
  }
  
};  
Blacklight.onLoad(function() {
    if ( $('body').hasClass("browse-info") ) {
        subjectBrowse.onLoad();  
    }
});  
