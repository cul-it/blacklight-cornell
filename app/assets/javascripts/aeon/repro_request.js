
var repro_requested = "";

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
    var  valu = $(ele).text();
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
             + cnx + '">');
      $("#EADRequest").
             append('<input type=hidden name="ItemInfo1_' + req + '" value="'
             + crx + '">');
      $("#EADRequest").
             append('<input type=hidden name="ItemInfo2_' + req + '" value="'
             + frx + '">');
      //$("#EADRequest").
             //append('<input type=hidden name="ItemInfo5_' + req + '" value="'
             //+ nox + '">');
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
      var dx = $("#ScheduledDate").val(); 
      if (v === false || v == '' || v == "0" ||  v == 0) {
        alert("Please select an item or items for your request.");
        return false;
      }
      
      if (dt == 'Photoduplication' || v == 1)  {
         $("#AeonForm").val('PhotoduplicationRequest'); 
         $('.ItemNo').each(makeRequest);
         var fixed = ["ItemTitle", 
          "ItemPages", "ItemInfo3","ItemInfo5",
          "ItemPublisher","ItemPlace","ItemDate","Notes","SpecialRequest",
          "ItemEdition","ItemCitation","PageCount"];
          for (var i=0;i<fixed.length;i++) {
             $("#RequestForm").
             append('<input type=hidden name=' + fixed[i] + ' value="'
             + $('#'+fixed[i]).val() + '">');
          }
         var fixed2 = ["SpecialRexuest"]; 
          for (var i=0;i<fixed2.length;i++) {
             $("#RequestForm").
             append('<input type=hidden name="' + 'SpecialRequest' + '_FIXED" value="'
             + $('#SpecialRexuest').val() + '">');
        }
      }
      return true;
    //$(this).submit();
    }

// id of element in the selections div.

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
           var remspan = "<span id='"+remid+"'>&nbsp;<img src='/img/cross-small.png' alt='Remove'>&nbsp;</span>";
           //var remspan = "<span class='remove' id='"+remid+"'>&nbsp;(remove)&nbsp;</span>";
           v = 1;
           $("#num-selections").text(v);
           //$("#selections").append("<div id='t" + bc+"'> <li>" +loc+" "+cn+" "+co+" "+en+"  "+cr+ remspan +"</li></div>");
           var pbox  = "Pages:<label for='ItemPages'><span class='sr-only'>Pages</label><input type=text id='ItemPages'/>";
           var fobox = "Folder:<label for='ItemInfo5'><span class='sr-only'>Folder</label><input type=text id='ItemInfo5'/>";
           var new_bc =  bc; 
           if (repro_requested  != new_bc) {
             $("#t"+repro_requested).remove();
             $('#'+repro_requested).prop('checked',false); 
            }
           repro_requested = new_bc;
           $("#selections").append("<div id='t" + new_bc +  "'<li>" + cn + " "+co+" "+en+"  "+cr+ remspan + fobox + pbox + "</li></div>");
           $('#'+remid).click(function () {
             var v = $("#num-selections").text();
             v--;
             $("#num-selections").text(v);
             $("#t"+bc).remove();
             $('#'+bc).prop('checked',false); 
            });
        } else {
           var v = $("#num-selections").text();
           v = 0;
           $("#num-selections").text(v);
           $("#t"+bc).remove();
           repro_requested="";
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
      if (n == 1) { // only one item so we preselect.
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
        var pbox  = "Pages:<label for='ItemPages'><span class='sr-only'>Pages</label><input type=text id='ItemPages'/>";
        var fobox = "Folder:<label for='ItemInfo5'><span class='sr-only'>Folder</label><input type=text id='ItemInfo5'/>";
        $("#selections").append("<div id='t" + bc+"'> <li>"+loc+" "+cn+" "+co+" "+en+" "+cr+pbox+fobox+"</li></div>");
        });
      }
    });
} ());

