// DISCOVERYACCESS-2515 - add label for date range slider input
$(document).ready(function() {
	$( '.slider-horizontal input' ).attr( 'id', 'slider' );
	$( '.slider-horizontal input' ).before( '<label class="sr-only" for="slider">Select date range</label>' );
}); 