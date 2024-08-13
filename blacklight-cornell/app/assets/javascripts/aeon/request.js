function noClick (event) {
}

/**
 * @function clearForm
 * @param {Event} event - The click event
 * @description Clears the form, resets the selection count, and removes the selected items
 */
function clearForm (event) {
  $("form")[0].reset();
  $("#num-selections").text('0');
  $("#selections").html('');
}

/**
 * @function buildRequestForItem
 * @param {number} _ - The index of the element in the array
 * @param {HTMLElement} element - The element being processed
 * @description Adds hidden input fields to the form for the selected item
 */
function buildRequestForItem(_, element) {
  var req = $(element).attr('name');
  if ($(element).is(':checked')) {
    const {
      enumeration = '',
      barcode = '',
      chron = '',
      cslocation = '',
      callnumber = '',
      free = '',
      note = '',
      copy = '',
      Restrictions = ''
    } = itemdata[req] ?? {};

    const en = `${enumeration} ${chron}`;
    const fields = [
      { name: "Request[]", value: req },
      { name: `ItemVolume_${req}`, value: en },
      { name: `Location_${req}`, value: cslocation },
      { name: `CallNumber_${req}`, value: callnumber },
      { name: `Restrictions_${req}`, value: Restrictions },
      { name: `ItemInfo1_${req}`, value: chron },
      { name: `ItemNumber_${req}`, value: barcode },
      { name: `ItemIssue_${req}`, value: copy }
    ];

    fields.forEach(field => {
      $("#EADRequest").append(`<input type="hidden" name="${field.name}" value="${field.value}">`);
    });
  }
}

/**
 * @function doSubmit
 * @param {Event} event - The click event
 * @returns {boolean} - Returns true if the form submission is allowed, false otherwise
 * @description Handles the form submission and performs validation checks
 */
function doSubmit(event) {
  console.log("doSubmit");
  var numSelected = $("#num-selections").text();
  var dt = $("#DocumentType").val();

  if (!numSelected || numSelected === "0") {
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
             var v = $("#num-selections").text();
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
  if (dt == 'Manuscript' || v > 1) {
    $("#AeonForm").val('EADRequest'); 
    $('.ItemNo').each(buildRequestForItem);
    var fixed = ["ItemTitle","ItemInfo3",
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

  return false;
}

/**
 * @function doClick
 * @param {Event} event - The click event
 * @description Handles the click event on a checkbox and moves the item to the selected items box
 */
function doClick (event) {
  console.log("doClick");
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
      var v = $("#num-selections").text();
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

/**
 * @function bindClick
 * @param {number} index - The index of the element in the array
 * @param {HTMLElement} ele - The element being processed
 * @description Binds the click event handler to each element in the array
 */
function bindClick (index,ele) {
  $(ele).click(doClick); 
}

/**
 * @function setupClickHandlers
 * @description Sets up the click event handlers for the page and selects the item by default if there is only one item
 */
function setupClickHandlers() {
  console.log("set up click handlers");
  $("#num-selections").text('0');
  $('#clear').click(clearForm);
  $('#SubmitButton').click(doSubmit);
  $('#EADRequest').submit(true);
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
}

// Immediately invoked function expression (IIFE) to encapsulate the code
(function () {
  "use strict";

  // Call the setupClickHandlers function when the document is ready
  $(document).ready(setupClickHandlers);
}());
