/*
* Schedule Date date picker
*/

(function () {
  "use strict";

  function clearForm (event) {
  $("form")[0].reset();
  $("#num-selections").text('0');
  $("#selections").html('');
  }
   
  function buildRequestForItem(_, element) {
    const req = $(element).attr('name');
    if ($(element).is(':checked')) {
      const {
        enumeration = '',
        barcode = '',
        chron = '',
        cslocation = '',
        callnumber = '',
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

  function doSubmit(_) {
    const numSelected = $("#num-selections").text();
    const docType = $("#DocumentType").val();

    if (!numSelected || numSelected == "0") {
      alert("Please select an item or items for your request.");
      return false;
    }

    if (docType == 'Manuscript' || numSelected > 1)  {
       $("#AeonForm").val('EADRequest'); 
       $('.ItemNo').each(buildRequestForItem);
       const fixed = ["ItemTitle","ItemInfo3",
        "ItemPublisher","ItemPlace","ItemDate",
        "ItemEdition"];
        for (let i=0;i<fixed.length;i++) {
           $("#EADRequest").
           append('<input type=hidden name="' + fixed[i] + '_FIXED" value="'
           + $('#'+fixed[i]).val() + '">');
        }
        const fixed2 = ["SpecialRequest"]; 
        for (let i=0;i<fixed2.length;i++) {
            // first check to see if the field exists
            if ($('#' + fixed2[i]).length) { 
                $("#EADRequest").
                append('<input type="hidden" name="' + fixed2[i] + '_FIXED" value="'
                + $('#' + fixed2[i]).val() + '">');
            }
        }
    }
    if (docType === 'Photoduplication') {
      const fields = ['SpecialRequest', 'ItemCitation', 'Notes', 'ServiceLevel', 'ShippingOption'];
      
      fields.forEach(field => {
        const $element = $(`#${field}`);
        if ($element.length) {
          $("#RequestForm").append(`<input type="hidden" name="${field}" value="${$element.val()}">`);
        }
      });
    }

    return true;
  }

  /**
  * doClick handles the click event on a checkbox
  * 
  * When a checkbox is checked or unchecked, the item is moved
  * to the selected items box.
  *
  * This function is bound to the checkbox click event only if
  * there are more than 1 items that can be selected
  */
  function doClick (event) {
    const id = $(this).val();
    const {
      location,
      callnumber,
      enumeration,
      copy = '',
      chron = '',
      Restrictions
    } = itemdata[id];
    const {
      publisher,
      publisher_date,
      pub_place,
      edition
    } = bibdata.items[0];

    $("#ItemNumber").val(id); 
    $("#Location").val(location); 
    $("#CallNumber").val(callnumber); 
    $("#ItemVolume").val(enumeration); 
    $("#ItemPublisher").val(publisher); 
    $("#ItemPlace").val(pub_place); 
    $("#ItemDate").val(publisher_date); 
    $("#ItemEdition").val(edition); 
    $("#ItemIssue").val(copy);
    $("#Restrictions").val(Restrictions); 
  
    if ($(this).is(":checked")) {
      const remId= `tremid${id}`;
      const remSpan = `<span id='${remId}'>&nbsp;<image src='/img/cross-small.png' alt='Remove'>&nbsp;</span>`;
      const itemDiv = `<div id='t${id}'> <li>${callnumber} ${copy} ${enumeration} ${chron} ${remSpan}</li></div>`;
      $("#selections").append(itemDiv);

      let numSelections = $("#num-selections").text();
      $("#num-selections").text(++numSelections);

      // Bind a click event to the remove icon to give us a way to remove the item from the list
      $(`#${remId}`).click(() => {
        $("#num-selections").text(--numSelections);
        $(`#t${id}`).remove();
        $(`#${id}`).prop('checked',false); 
      });
    } else {
      let numSelections = $("#num-selections").text();
      $("#num-selections").text(--numSelections);
      $(`#t${id}`).remove();
    }
  }

  /**
   * Sets up the click event handlers for the page
   * and if there is only 1 item to select, it 
   * will be selected by default.
  */
  $(document).ready(function () {
    $("#num-selections").text('0');
    $('#clear').click(clearForm);
    $('#SubmitButton').click(doSubmit);
    $('.ItemNo').each((_, element) => {
      $(element).click(doClick);
    });
    const n = $('.ItemNo').length;
    if (n == 1) {
      $('.ItemNo').each((_, obj) =>{
        $(obj).click();
        $(obj).unbind('click');
        $("#num-selections").text('1');
        var bc= $(obj).val();
        var cn = itemdata[bc].callnumber; 
        var en = itemdata[bc].enumeration; 
        var co = itemdata[bc].copy?itemdata[bc].copy: ''; 
        var cr = itemdata[bc].chron?itemdata[bc].chron: ''; 
        $("#selections").append("<div id='t" + bc+"'> <li>"+" "+cn+" "+co+" "+en+" "+cr+"</li></div>");
      });
    }
  });
} ());