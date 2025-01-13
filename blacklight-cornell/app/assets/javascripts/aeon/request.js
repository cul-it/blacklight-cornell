/**
 * Clears the form by resetting the form fields and removing the selected items.
 * @param {Event} event - The event object.
 */
function clearForm(event) {
  $("form")[0].reset();
  itemCount = $('.ItemNo').length;
  if ($('.ItemNo').length === 1) {
    $("#num-selections").text('1');
  } else {
    $("#num-selections").text('0');
    $("#selections").html('');
  }
}

/**
 * Builds the request for the selected item and appends the necessary hidden input fields to the form.
 * @param {number} _ - The index of the element in the jQuery collection.
 * @param {HTMLElement} element - The DOM element.
 * @param {boolean} multipleFlag - Whether multiple items will be submitted in the request.
 */
function buildRequestForItem(_, element, multipleFlag) {
  let req = $(element).attr('name');  
  // if the itemdata key doesn't exist, use "iid-" prefix for items without a barcode
  if (!itemdata[req]) {
    req = `iid-${req}`;
  }
  if ($(element).is(':checked')) {
    const {
      enumeration = '',
      barcode = '',
      chron = '',
      cslocation = '',
      location = '',
      callnumber = '',
      copy = '',
    } = itemdata[req] ?? {};

    const fields = [
      { name: `ItemVolume`, value: `${enumeration} ${chron}` },
      { name: `Location`, value: cslocation + ' ' + location},
      { name: `CallNumber`, value: callnumber },
      { name: `ItemInfo1`, value: chron },
      { name: `ItemNumber`, value: barcode },
      { name: `ItemIssue`, value: copy }
    ];
    $("#RequestForm").append(`<input type="hidden" class="dynamic-input" name="Request" value="${req}">`);
    const ext = multipleFlag ? `_${req}` : '';
    fields.forEach(field => {
      $("#RequestForm").append(`<input type="hidden" class="dynamic-input" name="${field.name}${ext}" value="${field.value}">`);
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

  if (!numSelected || numSelected == "0") {
    alert("Please select an item or items for your request.");
    return false;
  }

  if(numSelected == "1") { 
    // for a single item request, hidden input field names can NOT have that ID appended
    $('.ItemNo').each((_, element) => buildRequestForItem(_, element, false));
  } else {
    // for requests w/multiple items, hidden input field names must have '_item#' appended
    $('.ItemNo').each((_, element) => buildRequestForItem(_, element, true));
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
    copy = ''
  } = itemdata[id] || itemdata[`iid-${id}`];

  $("#ItemNumber").val(id);
  $("#Location").val(location);
  $("#CallNumber").val(callnumber);
  $("#ItemVolume").val(enumeration);
  $("#ItemIssue").val(copy);

  if ($(this).is(":checked") && ($('.ItemNo').length > 1)) {
    const remId = `tremid${id}`;
    appendItemToSelection(id, true);

    let numSelections = $("#num-selections").text();
    $("#num-selections").text(++numSelections);

    // Bind a click event to the remove icon to give us a way to remove the item from the list
    $(`#${remId}`).click(() => {
      let numSelections = parseInt($("#num-selections").text());
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
  } = itemdata[id] || itemdata[`iid-${id}`];
  const copyString = copy ? `c. ${copy}` : '';
  const remId = `tremid${id}`;
  const remSpan = removable ? `<span id='${remId}'>&nbsp;<image src='/img/cross-small.png' alt='Remove'>&nbsp;</span>` : '';
  const itemDiv = `<div id='t${id}'> <li>${callnumber} ${copyString} ${enumeration} ${chron} ${remSpan}</li></div>`;
  $("#selections").append(itemDiv);
}

/**
 * Sets up the click event handlers for the page 
 * and selects the item by default if there is only 1 item to select
*/
$(document).ready(function () {
  $(".dynamic-input").remove().length;
  $("#num-selections").text('0');
  $('#clear').click(clearForm);
  $('#RequestForm').submit(doSubmit);
  $('.ItemNo').each((_, element) => $(element).click(doClick));
  if ($('.ItemNo').length === 1) {
    const item = $('.ItemNo').first();
    item.click().unbind('click');
    // set the checked attribute so the form reset works as expected
    item.attr('checked', 'checked'); 
    $("#num-selections").text('1');
    // Append the item to the selected items box; 'false' indicates that the item is not removable
    appendItemToSelection(item.val(), false);
    // Disable the checkbox so that it matches the non-removable behavior of the single selected item
    $('.ItemNo').prop('disabled', true)
    $('#clearBtnSpan').remove();
  }
});

/* if the user navigates back to the form...
 * update the selected items box so its in sync with the checked items
 * and remove all dynamically added inputs to avoid double submission
 */
$(window).on('pageshow', function() {
  $(".dynamic-input").remove().length;
  if ($('.ItemNo').length > 1) {
    // make sure shopping cart items are in sync with checked items
    const checkedItems = $('.ItemNo:checked');
    if (checkedItems.length > 0) {
      checkedItems.each((_, element) => {
        const item = $(element);
        // add any missing checked items to selected items box
        if ($("#selections").find(`div[id='t${item.val()}']`).length === 0) {
          appendItemToSelection(item.val(), true);
          $("#num-selections").text(parseInt($("#num-selections").text()) + 1);
        } 
      });
    }
  }
});