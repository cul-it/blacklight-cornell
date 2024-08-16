/**
 * Clears the form by resetting the form fields and removing the selected items.
 * @param {Event} event - The event object.
 */
function clearForm(event) {
  $("form")[0].reset();
  $("#num-selections").text('0');
  $("#selections").html('');
}

/**
 * Builds the request for the selected item and appends the necessary hidden input fields to the form.
 * @param {number} _ - The index of the element in the jQuery collection.
 * @param {HTMLElement} element - The DOM element.
 */
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
    const fields = [
      { name: "Request[]", value: req },
      { name: `ItemVolume_${req}`, value: `${enumeration} ${chron}` },
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
 * Submits the form after performing necessary validations and appending hidden input fields based on the document type.
 * @param {Event} _ - The event object.
 * @returns {boolean} - Returns true if the form is successfully submitted, false otherwise.
 */
function doSubmit(_) {
  const numSelected = $("#num-selections").text();
  const docType = $("#DocumentType").val();

  if (!numSelected || numSelected == "0") {
    alert("Please select an item or items for your request.");
    return false;
  }
  
  $('.ItemNo').each(buildRequestForItem);

  const fixed = ['SpecialRequest', 'ItemTitle', 'ItemInfo3'];
  fixed.forEach(item => {
    $("#EADRequest").append(`<input type="hidden" name="${item}_FIXED" value="${$('#' + item).val()}">`);
  });

  if (docType === 'Photoduplication') {
    const fields = ['ItemCitation', 'Notes', 'ServiceLevel', 'ShippingOption'];

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
 * Handles the click event on a checkbox.
 * Moves the item to the selected items box when a checkbox is checked or unchecked.
 * This function is bound to the checkbox click event only if there are more than 1 items that can be selected.
 * @param {Event} event - The event object.
 */
function doClick(event) {
  const id = $(this).val();
  const {
    location,
    callnumber,
    enumeration,
    copy = '',
    Restrictions
  } = itemdata[id];

  $("#ItemNumber").val(id);
  $("#Location").val(location);
  $("#CallNumber").val(callnumber);
  $("#ItemVolume").val(enumeration);
  $("#ItemIssue").val(copy);
  $("#Restrictions").val(Restrictions);

  if ($(this).is(":checked") && ($('.ItemNo').length > 1)) {
    const remId = `tremid${id}`;
    appendItemToSelection(id, true);

    let numSelections = $("#num-selections").text();
    $("#num-selections").text(++numSelections);

    // Bind a click event to the remove icon to give us a way to remove the item from the list
    $(`#${remId}`).click(() => {
      $("#num-selections").text(--numSelections);
      $(`#t${id}`).remove();
      $(`#${id}`).prop('checked', false);
    });
  } else {
    let numSelections = $("#num-selections").text();
    $("#num-selections").text(--numSelections);
    $(`#t${id}`).remove();
  }
}

/**
 * Appends the selected item to the selected items box.
 * 
 * @param {number} id - The item id.
 * @param {boolean} removable - Whether the item can be removed from the selected items box.
 */
const appendItemToSelection = (id, removable) => {
  const {
    callnumber,
    enumeration,
    copy,
    chron = '',
  } = itemdata[id];
  const copyString = copy ? `c. ${copy}` : '';
  const remId = `tremid${id}`;
  const remSpan = removable ? `<span id='${remId}'>&nbsp;<image src='/img/cross-small.png' alt='Remove'>&nbsp;</span>` : '';
  const itemDiv = `<div id='t${id}'> <li>${callnumber} ${copyString} ${enumeration} ${chron} ${remSpan}</li></div>`;
  $("#selections").append(itemDiv);
}

/**
 * Sets up the click event handlers for the page and selects the item by default if there is only 1 item to select.
 */
$(document).ready(function () {
  $("#num-selections").text('0');
  $('#clear').click(clearForm);
  $('#SubmitButton').click(doSubmit);
  $('.ItemNo').each((_, element) => $(element).click(doClick));
  if ($('.ItemNo').length === 1) {
    const item = $('.ItemNo').first();
    item.click().unbind('click');
    $("#num-selections").text('1');
    // Append the item to the selected items box; 'false' indicates that the item is not removable
    appendItemToSelection(item.val(), false);
    // Disable the checkbox so that it matches the non-removable behavior of the single selected item
    $('.ItemNo').prop('disabled', true)
  }
});
