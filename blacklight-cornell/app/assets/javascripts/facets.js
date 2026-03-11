// DACCESS-191 - Fetch and display all values for lc_callnum_facet asynchronously to improve initial page load
Blacklight.onLoad(function() {
  // Re-initialize blacklight-hierarchy behavior to display +/- icons correctly in modal
  function rerenderHierarchicalFacets() {
    if (document.querySelector("#blacklight-modal .facet-hierarchy")) {
      Blacklight.do_hierarchical_facet_expand_contract_behavior();
    }
  }
  $('body').on('loaded.blacklight.blacklight-modal', rerenderHierarchicalFacets);

  if (document.getElementById('facets') && document.getElementById('facet-lc_callnum_facet')) {
    const moreLink = document.querySelector('#facet-lc_callnum_facet .more_facets a');

    // If there are more call number facet values to load, fetch them asynchronously
    if (moreLink) {
      // Replace more link with loading indicator
      const moreLinkParent = moreLink.parentNode;

      // Create loading indicator
      const loadingIndicator = document.createElement('div');
      loadingIndicator.classList.add('spinner-border');
      loadingIndicator.setAttribute('role', 'status');

      // Create screen reader text
      const srIndicatorText = document.createElement('span');
      srIndicatorText.innerText = 'Loading more...';
      srIndicatorText.classList.add('sr-only');
      loadingIndicator.appendChild(srIndicatorText);

      moreLinkParent.classList.add('text-center');
      moreLinkParent.replaceChild(loadingIndicator, moreLink);

      // Get current URL params
      const searchParams = new URLSearchParams(window.location.search);
      // callnum values will be rendered server-side if searchParams includes lc_callnum_facet
      if (!searchParams.has('f[lc_callnum_facet][]')) {
        // Build the facet URL
        const url = 'catalog/facet_values/lc_callnum_facet?' + searchParams.toString();
        // Fetch the facet HTML and update the facet div
        $.ajax({
            url: url,
            error: function(xhr, status, error) {
              console.error('Error fetching Call Number facet:', error);
              // Restore more link on error
              moreLinkParent.replaceChild(moreLink, loadingIndicator);
              moreLinkParent.classList.remove('text-center');
            }
          });
      }
    }
  }
});