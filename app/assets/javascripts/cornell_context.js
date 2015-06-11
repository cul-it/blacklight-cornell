(function($) {
  Blacklight.cornell_do_search_context_behavior = function() {
      $('a[data-counter]').click(function(event) {
      //  not a catalog reference
      if  (($(this).attr('href').indexOf('catalog') < 0 ) 
       &&   ($(this).attr('href').indexOf('bookmark') < 0 )) {
        return true;
      }
      var f = document.createElement('form'); f.style.display = 'none'; 
      this.parentNode.appendChild(f); 
      f.method = 'POST'; 
      f.action = $(this).attr('href') +"/track";
      if(event.metaKey || event.ctrlKey){f.target = '_blank';};
      var d = document.createElement('input'); d.setAttribute('type', 'hidden'); 
      d.setAttribute('name', 'counter'); d.setAttribute('value', $(this).data('counter')); f.appendChild(d);
      var id = document.createElement('input'); id.setAttribute('type', 'hidden');
      id.setAttribute('name', 'search_id'); id.setAttribute('value', $(this).data('search_id')); f.appendChild(id);
      var m = document.createElement('input'); m.setAttribute('type', 'hidden'); 
      m.setAttribute('name', '_method'); m.setAttribute('value', 'post'); f.appendChild(m);
      var m = document.createElement('input'); m.setAttribute('type', 'hidden'); 
      m.setAttribute('name', $('meta[name="csrf-param"]').attr('content')); m.setAttribute('value', $('meta[name="csrf-token"]').attr('content')); f.appendChild(m);
      f.submit();
      return false;
      });

    };  
Blacklight.onLoad(function() {
  Blacklight.cornell_do_search_context_behavior();  
});
})(jQuery);

