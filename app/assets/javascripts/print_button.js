$(document).ready(function() {
 $('ul#item-tools').append('<li class="print"><a href="#print" class="btn btn-default btn-sm"><i class="fa fa-print"></i> Print</a></li>');
 $('ul#item-tools li.print a').click(function() {
  window.print();
  return false;
 });
}); 
