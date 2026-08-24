var sessionCountDown = 120;
var dialog = null;

function buildModalElement(message, footerHtml) {
  var el = document.createElement('div');
  el.className = 'modal fade';
  el.tabIndex = -1;
  el.innerHTML =
    '<div class="modal-dialog">' +
      '<div class="modal-content">' +
        '<div class="modal-body pt-4">' + message + '</div>' +
        '<div class="modal-footer">' + footerHtml + '</div>' +
        '<button type="button" class="btn-close position-absolute top-0 end-0 m-3" data-bs-dismiss="modal" aria-label="Close"></button>' +
      '</div>' +
    '</div>';
  document.body.appendChild(el);
  el.addEventListener('hidden.bs.modal', function () { el.remove(); });
  return el;
}

// backdrop: 'static' so the expired-session notice can't be dismissed by clicking outside it
function sessionAlertModal(message) {
  var el = buildModalElement(
    message,
    '<button type="button" class="btn btn-primary" data-bs-dismiss="modal">OK</button>'
  );

  var modal = new bootstrap.Modal(el, { backdrop: 'static', keyboard: true });
  modal.show();
  return modal;
}

function sessionConfirmModal(message) {
  var el = buildModalElement(
    message,
    '<button type="button" class="btn btn-danger" data-bs-dismiss="modal">No</button>' +
      '<button type="button" class="btn btn-success" data-result="confirm">OK</button>'
  );
  el.querySelector('[data-result="confirm"]').addEventListener('click', function () {
    location.reload(true);
  });

  var modal = new bootstrap.Modal(el, { backdrop: true, keyboard: true });
  modal.show();
  return modal;
}

function sessionUpdateTime() {
    sessionCountDown = sessionCountDown -1 ;
    if (sessionCountDown != 0 ){
      document.getElementById('sess_time').textContent = sessionCountDown;
      window.setTimeout(sessionUpdateTime, (1000));
    } else  {
      // swap the countdown confirm dialog out for the expired notice
      dialog.hide();
      dialog = sessionAlertModal("Your session has expired.");
    }
}

function sessionAlert() {
    sessionCountDown = sessionCountDown -1 ;
    window.setTimeout(sessionUpdateTime, (1000));
    dialog = sessionConfirmModal(
      "Press OK to refresh session. Otherwise it will reset in <span id='sess_time'>120</span> seconds"
    );
}
window.setTimeout(sessionAlert, (1000*60*60*4)-(120*1000));
// for testing
// window.setTimeout(sessionAlert, (1000*30)-(0));
