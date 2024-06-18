/*
* Schedule Date date picker
*/

(function () {
    "use strict";

    function noClick (event) {
    }

    function noSubmit (event) {
    return true;
    }

    function clearForm (event) {
    $("form")[0].reset();
    $("#num-selections").text('');
    $("#selections").html('');
    }
     
    function makeRequest(index,ele) {
    var  req = $(ele).attr('name');
    if ( $(ele).is(':checked'))  {
      var enx = itemdata[req].enumeration?itemdata[req].enumeration: ''; 
      var brx = itemdata[req].barcode?itemdata[req].barcode: ''; 
      var crx = itemdata[req].chron?itemdata[req].chron: ''; 
      var lox = itemdata[req].cslocation?itemdata[req].cslocation: ''; 
      var cnx = itemdata[req].callnumber?itemdata[req].callnumber: ''; 
      var frx = itemdata[req].free?itemdata[req].free: ''; 
      var nox = itemdata[req].note?itemdata[req].note: ''; 
      var co = itemdata[req].copy?itemdata[req].copy: ''; 
      var res = itemdata[req].Restrictions?itemdata[req].Restrictions: ''; 
      var en= enx + ' ' + crx; 
      $("#EADRequest").
        append('<input type=hidden name="Request[]" value="'
        + req +  '">');
      $("#EADRequest").
             append('<input type=hidden name="ItemVolume_' + req + '" value="'
             + en + '">');
      $("#EADRequest").
             append('<input type=hidden name="Location_' + req + '" value="'
             + lox + '">');
      $("#EADRequest").
             append('<input type=hidden name="CallNumber_' + req + '" value="'
             + cnx + '">');
      $("#EADRequest").
             append('<input type=hidden name="Restrictions_' + req + '" value="'
             + res + '">');
      $("#EADRequest").
             append('<input type=hidden name="ItemInfo1_' + req + '" value="'
             + crx + '">');
      $("#EADRequest").
             append('<input type=hidden name="ItemNumber_' + req + '" value="'
             + brx + '">');
      $("#EADRequest").
             append('<input type=hidden name="ItemIssue_' + req + '" value="'
             + co + '">');
    }
    }

    function doSubmit(event) {
      var v = $("#num-selections").text();
      var dt = $("#DocumentType").val();
      var ur = $("#UserReview").prop('checked'); 
      var ud = $("#UserDate").prop('checked'); 
      var dx = $("#ScheduledDate").val(); 
      if ( (!ur) &&  ( ud && dx === "") )  {
        alert("Please select select a date for your 'Scheduled Retrieval' ");
        return false;
      }
      if (v === false || v == '' || v == "0" ||  v == 0) {
        alert("Please select an item or items for your request.");
        return false;
      }

      if (dt == 'Manuscript' || v > 1)  {
         $("#AeonForm").val('EADRequest'); 
         $('.ItemNo').each(makeRequest);
         var fixed = ["ItemTitle", 
          "UserReview","ItemInfo3",
          "ItemPublisher","ItemPlace","ItemDate",
          "ItemEdition"];
          for (var i=0;i<fixed.length;i++) {
             $("#EADRequest").
             append('<input type=hidden name="' + fixed[i] + '_FIXED" value="'
             + $('#'+fixed[i]).val() + '">');
          }
          var fixed2 = ["SpecialRequest"]; 
          for (var i=0;i<fixed2.length;i++) {
              // first check to see if the field exists
              if ($('#' + fixed2[i]).length) { 
                  $("#EADRequest").
                  append('<input type="hidden" name="' + fixed2[i] + '_FIXED" value="'
                  + $('#' + fixed2[i]).val() + '">');
              }
          }
      }
      if (dt === 'Photoduplication') {
        if ($('#SpecialRequest').length) {
            $("#RequestForm").append('<input type="hidden" name="SpecialRequest" value="' + $('#SpecialRequest').val() + '">');
        }
        if ($('#ItemCitation').length) {
            $("#RequestForm").append('<input type="hidden" name="ItemPages" value="' + $('#ItemCitation').val() + '">');
        }
        if ($('#Notes').length) {
            $("#RequestForm").append('<input type="hidden" name="Notes" value="' + $('#Notes').val() + '">');
        }
        if ($('#ServiceLevel').length) {
            $("#RequestForm").append('<input type="hidden" name="ServiceLevel" value="' + $('#ServiceLevel').val() + '">');
        }
        if ($('#ShippingOption').length) {
            // this is the delivery method field (example: Digital file download: $0)
            $("#RequestForm").append('<input type="hidden" name="ShippingOption" value="' + $('#ShippingOption').val() + '">');
        }
        
      }
      return true;
    }

    /**
    * doClick handles the click event on a checkbox
    * 
    * When a checkbox is checked or unchecked, the item is moved
    * to the selected items box.
    *
    * This function is binded to the checkbox click event only if
    * there are more than 1 items that can be selected
    */
    function doClick (event) {
        var bc= $(this).val();
        var loc= itemdata[bc].location; 
        var cn = itemdata[bc].callnumber; 
        var en = itemdata[bc].enumeration; 
        var co = itemdata[bc].copy?itemdata[bc].copy: ''; 
        var cr = itemdata[bc].chron?itemdata[bc].chron: ''; 
        var pu = bibdata.items[0].publisher; 
        var pd = bibdata.items[0].publisher_date; 
        var pp = bibdata.items[0].pub_place; 
        var ed = bibdata.items[0].edition; 
        var res = itemdata[bc].Restrictions;
        $("#ItemNumber").val(bc); 
        $("#Location").val(loc); 
        $("#CallNumber").val(cn); 
        $("#ItemVolume").val(en); 
        $("#ItemPublisher").val(pu); 
        $("#ItemPlace").val(pp); 
        $("#ItemDate").val(pd); 
        $("#ItemEdition").val(ed); 
        $("#ItemIssue").val(co);
        $("#Restrictions").val(res); 
        if ($(this).is(":checked")) {
           var v = $("#num-selections").text();
           var remid='tremid' + bc;
           
           var remspan = "<span id='"+remid+"'>&nbsp;<image src='/img/cross-small.png' alt='Remove'>&nbsp;</span>";
           v++;
           $("#num-selections").text(v);
           $("#selections").append("<div id='t" + bc+"'> <li>" + cn + " " +co+" "+en+"  "+cr+ remspan +"</li></div>");
           $('#'+remid).click(function () {
             var v = 100;
             v--;
             $("#num-selections").text(v);
             $("#t"+bc).remove();
             $('#'+bc).prop('checked',false); 
            });
        } else {
           var v = $("#num-selections").text();
           v--;
           $("#num-selections").text(v);
           $("#t"+bc).remove();
        }
    }

    function bindClick (index,ele) {
       $(ele).click(doClick); 
    }

    function showReview () {
      $('#ReviewText').show();
      $('#ScheduledText').hide();
      $('#ScheduledDate').hide();
      $('#UserReview').prop("checked", true);
      $('#UserDate').prop("checked", false);
     }

    function showScheduled () {
      $('#ReviewText').hide();
      $('#ScheduledText').show();
      $('#ScheduledDate').show();
      $('#UserReview').prop("checked", false);
      $('#UserDate').prop("checked", true);
     }

    /**
     * Sets up the click event handlers for the page
     * and if there is only 1 item to select, it 
     * will be selected by default.
    */
    $(document).ready(function () {
      $('#ReviewText').hide();
      showScheduled();
      $('#UserReview').click(function () {
                showReview();
      });
      $('#UserDate').click(function () {
                showScheduled();
      });
      $('#clear').click(clearForm);
      $('#SubmitButton').click(doSubmit);
      $('#EADRequest').submit(noSubmit);
      $('.ItemNo').each(bindClick);
      var n = $('.ItemNo').length;
      if (n == 1) {
        $('.ItemNo').each(function(i,obj){
        $(obj).click();
        $(obj).unbind('click');
        $(obj).click(noClick); 
        $("#num-selections").text('1');
        var bc= $(obj).val();
        var loc= itemdata[bc].cslocation; 
        var cn = itemdata[bc].callnumber; 
        var en = itemdata[bc].enumeration; 
        var co = itemdata[bc].copy?itemdata[bc].copy: ''; 
        var cr = itemdata[bc].chron?itemdata[bc].chron: ''; 
        $("#selections").append("<div id='t" + bc+"'> <li>"+" "+cn+" "+co+" "+en+" "+cr+"</li></div>");
        });
      }
    });
} ());
