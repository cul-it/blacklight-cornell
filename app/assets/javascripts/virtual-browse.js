var _paq = _paq || [];
var current_previous = "current previous";
var current_next = "current next";
var  carouselActions = {
  onLoad: function() {
      carouselActions.et_scroll_home();
      carouselActions.bindEventListeners();
  },
  
  bindEventListeners: function() {
      // variables used in the scrolling calculations
      var oc_width = $('#outer-container').width();
      var oc_lo = $('#outer-container').offset().left;
      var oc_ro = (oc_width + oc_lo);

      $("#outer-container").scroll(function(){
          // When scrolling stops, map data from centered item to the preview box.
          clearTimeout($.data(this, 'scrollTimer'));
          	$.data(this, 'scrollTimer', setTimeout(function() {
                var count = 0;
                $("#outer-container").children(".inner-container").each(function() {
                    if ( $('.slides').length ) {
                        var p = $(this).position();
                        if ( $(window).width() > 991 ) {
                            if ( p.left > 0 ) {
                                count++;
                                if ( count == 2 ) {
                                    carouselActions.map_data_fields(this);
                                    $('.preview-container').css("display","block");  
                                    return false;
                                }
                            }
                        }
                        else {
                            if ( p.left > 0 ) {
                                carouselActions.map_data_fields(this);
                                $('.preview-container').css("display","block");
                                return false;
                             }
                        }
                    }
                    else if ( $('.slides-full').length ) {
                        var p = $(this).position();
                        if ( p.left > 0 ) {
                            count++;
                            if ( $(window).width() > 1185 && count == 3 ) {
                                carouselActions.map_data_fields(this);
                                $('.preview-container-full').css("display","block");  
                                return false;
                            }
                            if ( $(window).width() > 992 && $(window).width() < 1186 && count == 2 ) {
                                carouselActions.map_data_fields(this);
                                $('.preview-container-full').css("display","block");
                                return false;
                            }
                            if ( $(window).width() > 959 && $(window).width() < 993 && count == 1 ) {
                                carouselActions.map_data_fields(this);
                                $('.preview-container-full').css("display","block");
                                return false;
                            }
                            if ( $(window).width() > 767 && $(window).width() < 960 && count == 2) {
                                carouselActions.map_data_fields(this);
                                $('.preview-container-full').css("display","block");
                                return false;
                            }
                            if ( $(window).width() < 768 && count == 1 ) {
                                carouselActions.map_data_fields(this);
                                $('.preview-container-full').css("display","block");
                                return false;
                            }
                        }
                    }
                });
          	}, 66));
          	
          	// When scolling, check to see if we need to retrieve more and if the class heading needs to change.
          	if ( $('.inner-container-primary').offset().left > oc_ro ) {
              if ( carouselActions.isInViewport($('#outer-container').children().eq(3)) && $('#outer-container').children().eq(1).attr("id") != current_previous ) {
                  current_previous = $('#outer-container').children().eq(1).attr("id");
                  carouselActions.getPrevious($('.inner-container-primary').attr("data-callnumber"));
              }
              if ( $('.inner-container-primary').attr("data-status") == undefined ) { 
                $('.inner-container-primary').attr("data-status","not visible");
                $('.return-home').show();
              }
            }
            else if ( $('.inner-container-primary').offset().left < (oc_lo - $('.inner-container-primary').width()) ) {
                if ( carouselActions.isInViewport($('#outer-container').children("div:nth-last-child(4)")) && $('#outer-container').children("div:nth-last-child(2)").attr("id") != current_next ) {
                    current_next = $('#outer-container').children("div:nth-last-child(2)").attr("id");
                    carouselActions.getNext($('.inner-container-primary').attr("data-callnumber"));
                }
                if ( $('.inner-container-primary').attr("data-status") == undefined ) { 
                  $('.inner-container-primary').attr("data-status","not visible");
                  $('.return-home').show();
                }
            }
            else {
              if ( $('.inner-container-primary').attr("data-status") == "not visible" ) {
                $('.inner-container-primary').removeAttr("data-status");
                $('.return-home').hide();
              }
            }
            
      });
      
      $('#vb-scroll-left').click(function() {
          var leftPos = $('#outer-container').scrollLeft();
          $("#outer-container").animate({
              scrollLeft: leftPos - 200
          }, 800);
      });
      
      $('#call-number-sel').on('change', function() {
          carouselActions.fetch_new_carousel(this.value);
      });
      
      $('#vb-scroll-right').click(function() {
          var leftPos = $('#outer-container').scrollLeft();
          $("#outer-container").animate({
              scrollLeft: leftPos + 200
          }, 800);
      });

      $('a#return-home-link').click(function() {
          carouselActions.et_scroll_home();
      });

      $('a#vb-view-list').click(function() {
         $('#vb-view-type > i').removeClass("fa-th");
         $('#vb-view-type > i').addClass("fa-align-justify");
         authq = "authq=" + $('.inner-container-primary').data("callnumber").replace(/ /g,"+");
         url = "browse?authq=&start=0&browse_type=Call-Number&order=forward"
         window.location = url.replace("authq=",authq);
      });
  },

  // not currently used, but keeping in place for the time being (tlw72 9/20)
  setup_click_for_preview: function() {
      var leftPos = $('#outer-container').scrollLeft();
      $('div.inner-container').each(function() {
          $(this).unbind("click").click(function() {
               carouselActions.click_for_preview(this);
          });
      });
  },

  click_for_preview: function(object) {
      var leftPos = $('#outer-container').scrollLeft();
      if ( $('.slides').length ) {
          if ( $(window).width() > 535 && $(object).position().left < 50 ) {
              $("#outer-container").animate({
                    scrollLeft: leftPos - 200
              }, 800);
          }
          else if ( $(window).width() > 535 && $(object).position().left > 300 ){
               $("#outer-container").animate({
                     scrollLeft: leftPos + 200
               }, 800);
          }
          else if ( $(window).width() < 536 && $(object).position().left > 100 ) {
              $("#outer-container").animate({
                    scrollLeft: leftPos - 200
              }, 800);
          }
      }
      else if ( $('.slides-full').length ) {
          // console.log("window width - " + $(window).width());
          // console.log("scroll width - " + $('div#outer-container').width());
          // console.log("you clicked - " + $(object).position().left);
      } 
  },
  // scrolls the user to the starting point of the carousel
  et_scroll_home: function() {
      visCount = 0
      $('#outer-container').children().each(function() {
           if ( carouselActions.isInViewport(this) ) {
               visCount++ ;
           }
      });
      var divisor = 2;
      if ( visCount == 6 ) { divisor = 3; }
      if ( visCount == 4 ) { divisor = 4; }
      var adjustment = $('.inner-container-primary').offset().left - $('#outer-container').offset().left + $('#outer-container').scrollLeft();
      var containerWidth = $('#outer-container').width();
      var result = (containerWidth/divisor);
      $('#outer-container').scrollLeft(adjustment - result, 1000); 
  },
  
  map_data_fields: function(selected) {
      // first, set the classification in the top nav panel
      label = $(selected).attr("data-classification");
	  $('.vb-current-class').html(label.replace(/ : /g,' <i class="fa fa-caret-right class-caret"></i> '));
	  // add/remove highlighting
      carouselActions.remove_highlighting();
      $(selected).addClass("current-preview");
      // if this is the starting point (initially selected item), reset the red border color
      if ( $(selected).hasClass("inner-container-primary") ) {
          $(selected).attr("style","border-color: #b31b1b !important");
      }
      
      // now map data attributes to the preview panel
      $('#prev-title').html($(selected).data("title"));
      href_str = "/catalog/" + $(selected).attr("id")
      $('#prev-title').attr("href",href_str);
      if ( $(selected).data("author").length > 0 ) {        
          $('#prev-author').html($(selected).data("author"));
          $('#prev-author').show();
          $('#label-author').show();
      }
      else {
          $('#label-author').hide();
          $('#prev-author').hide();
      }
      if ( $(selected).data("publisher").length > 0 ) {        
          $('#prev-publisher').html($(selected).data("publisher"));
          $('#prev-publisher').show();
          $('#label-publisher').show();
      }
      else {
          $('#label-publisher').hide();
          $('#prev-publisher').hide();
      }
      if ( $(selected).data("pubdate") ) {  
          $('#prev-date').html($(selected).data("pubdate"));
          $('#prev-date').show();
          $('#label-date').show();
      }
      else {
          $('#label-date').hide();
          $('#prev-date').hide();
      }
      if ( $(selected).data("locations").length > 0 ) {        
          $('#prev-available').html($(selected).data("locations"));
          $('#prev-available').show();
          $('#label-available').show();
      }
      else {
          $('#label-available').hide();
          $('#prev-available').hide();
      }
  },
  
  remove_highlighting: function() {
      $('#outer-container').children().each(function() {
           $(this).removeClass("current-preview");
           // if this is the starting point (initially selected item), remove the red border color
           if ( $(this).hasClass("inner-container-primary") ) {
               $(this).attr("style","border-color: #dadada !important");
           }
      });
  },
  
  getPrevious: function(callnumber) {
      var prevCount = $('#classification').attr("data-prev-count");
      var keepCount = $('#classification').attr("data-keep-count");
      var fqLocation = "";
      if ( $('.inner-container-primary').attr("data-location-fq") != undefined && $('.inner-container-primary').attr("data-location-fq").length > 0 ) {
          fqLocation = "&fq=" + $('.inner-container-primary').attr("data-location-fq");
      }
      // If we've already retrieved previous docs twice, we're done;
      // so instead display a link to the main CN browse page.
      if ( prevCount == 3 && keepCount == "true" ) {
          $("#prev-reroute").show();
      }
      else {
        prevCount++;
        $('#classification').attr("data-prev-count",prevCount);
        var remote = true;
        setTimeout(function(){ $('#vb-time-indicator').show(); }, 1000);
        $.ajax({
          url : "/get_previous?callnum=" + callnumber + "&start=" + prevCount + fqLocation,
          type: 'GET',
          data: remote,
          dataType: "jsonp",
          jsonp: "json.wrf",
          complete: function(xhr, status) {
            // The first get_previous call on page load can cause the primary work to be off-center.
            // This re-centers it in the VSB.
             if ( prevCount < 2 && keepCount == "true" ) {
               carouselActions.et_scroll_home();
             }
            setTimeout(function(){ $('#vb-time-indicator').hide(); }, 3000);
            //carouselActions.setup_click_for_preview();
          }
        }); 
      } 
  },
  
  getNext: function(callnumber) {
      var nextCount = $('#classification').attr("data-next-count");
      var keepCount = $('#classification').attr("data-keep-count");
      var fqLocation = "";
      if ( $('.inner-container-primary').attr("data-location-fq") != undefined && $('.inner-container-primary').attr("data-location-fq").length > 0 ) {
          fqLocation = "&fq=" + $('.inner-container-primary').attr("data-location-fq");
      }
      // If we've already retrieved ensuing/next docs twice, we're done;
      // so instead display a link to the main CN browse page.
      if ( nextCount == 3 && keepCount == "true" ) {
          $("#next-reroute").show();
      }
      else {
        nextCount++;
        $('#classification').attr("data-next-count",nextCount);
        var remote = true;
        setTimeout(function(){ $('#vb-time-indicator').show(); }, 1000);
        $.ajax({
          url : "/get_next?callnum=" + callnumber + "&start=" + nextCount + fqLocation,
          type: 'GET',
          data: remote,
          dataType: "jsonp",
          jsonp: "json.wrf",
          complete: function(xhr, status) {
              setTimeout(function(){ $('#vb-time-indicator').hide(); }, 3000);
              //carouselActions.setup_click_for_preview();
          }
          
        }); 
     }
  },
    
  fetch_new_carousel: function(callnumber) {
      var remote = true;
      $('#vb-time-indicator').show();
      $.ajax({
        url : "/get_carousel?callnum=" + callnumber,
        type: 'GET',
        data: remote,
        complete: function(xhr, status) {
            setTimeout(function(){ $('#vb-time-indicator').hide(); }, 3000);
            carouselActions.et_scroll_home();
            $("#prev-reroute").hide();
            $("#next-reroute").hide();
            $('#classification').attr("data-next-count","0");
            $('#classification').attr("data-prev-count","0");
        }
      }); 
  },

  isInViewport: function(element) {
      var oc_width = $('#outer-container').width();
      var oc_lo = $('#outer-container').offset().left;
      var oc_ro = (oc_width + oc_lo);
      if ( $(element).offset().left > oc_ro || $(element).offset().left < (oc_lo - $(element).width()) ) {
          //console.log("not in the viewport");
          return false;
      }
      else {
          //console.log("in the viewport");
          return true;
      }
       
  }
};
Blacklight.onLoad(function() {
  if ( $('body').prop('className').indexOf("catalog-show") >= 0 ) {
    if ( $('div.vb-select').length ) {
      carouselActions.onLoad();
      carouselActions.getPrevious($('div.inner-container-primary').data("callnumber"));
      carouselActions.getNext($('div.inner-container-primary').data("callnumber"));
    }
  }
  if ( $('body').prop('className').indexOf("browse-index") >= 0 ) {
      if ( $('#outer-container').length ) {
          //$('#vb-view-type > i').removeClass("fa-align-justify");
          //$('#vb-view-type > i').addClass("fa-th");
          $('#browse_type').val("Call-Number");
          carouselActions.onLoad();
      }
      if ( window.location.href.indexOf("browse_type=Call-Number") > 0 ) {
          $('a#vb-view-virtual').click(function() {
              $('#vb-view-type > i').removeClass("fa-align-justify");
              $('#vb-view-type > i').addClass("fa-th");
              authq = "authq=" + $('#view-type-dropdown-cn').data("callnumber").replace(/ /g,"+");
              url = "browse?authq=&browse_type=virtual"
              window.location = url.replace("authq=",authq);
          });
      } 
  }
});