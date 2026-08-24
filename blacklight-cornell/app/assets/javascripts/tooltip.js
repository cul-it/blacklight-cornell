// Add tooltip to select box when not signed in
document.querySelectorAll(".show-select-box").forEach((el) => {
  el.setAttribute("data-bs-toggle", "tooltip");
  el.setAttribute("data-bs-placement", "bottom");
  el.setAttribute("data-bs-title", "Sign in first to email items or save them to Book Bag");
});

document.querySelectorAll('[data-bs-toggle="tooltip"]').forEach((el) => new bootstrap.Tooltip(el));
