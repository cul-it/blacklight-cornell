$(function () {
  $('[data-toggle="tooltip"]').tooltip()
})

// Add tooltip to select box when not signed in
$(".show-select-box").attr({
	"data-toggle": "tooltip",
	"data-placement": "bottom",
	"title": "Sign in first to email items or save them to Book Bag"
});