// Display enhanced music metadata from Wikidata (BAMWOW!) in Author-Title Browse
// https://wiki.lyrasis.org/display/LD4P3/WP3%3A+Discovery#WP3:Discovery-BAMWOW!(BrowsingAcrossMusicWithObtainableWikidata)
function AuthorTitleBrowse() {
  const locConnector = LOCConnector();
  const bamwowHelper = BamwowHelper();
  // TODO: Add ability to exclude excludeEntities.yml?

  async function renderLinkedData() {
    try {
      // Query Library of Congress for localName that can be used to fetch Wikidata results
      const headingAttr = $('#author-title-heading').data('heading');
      const locQuery = parseHeadingAttr(headingAttr);
      const localName = await locConnector.getLocalName(locQuery, 'NameTitle');

      if (localName) {
        // If LOC name found for heading, query Wikidata for additional data to display
        const wikidata = await bamwowHelper.getWikidata(localName);
        renderWikidata(wikidata);
      }
    } catch(err) {
      console.log(err);
    }
  };

  // Remove pipe value from heading attr in catalog
  function parseHeadingAttr(headingAttr) {
    return bamwowHelper.reformatHeading(headingAttr);
  };

  function renderWikidata(data) {
    if (bamwowHelper.canRender(data)) {
      const fieldHtml = generateFieldHtml(data);
      $('dl#item-details').append(fieldHtml);

      const sourceLinkHtml = generateWikidataSourceLinks(data);
      $('#wiki-acknowledge').html(sourceLinkHtml);

      // Show details
      $('#info-details').removeClass('d-none');
      $('#ref-info').addClass('mt-4');
    }
  }

  // Generate fields
  function generateFieldHtml(data) {
    let html = '';
    if (data.codes?.length) {
      const codesArr = data.codes.map(code => `<dt>${code.catalogLabel} : ${code.code} *</dt>`);
      html += (
        `<dt class="col-sm-4">Catalog numbers:</dt>
        <dd class="col-sm-8">
          <dl class="dl-horizontal">${codesArr.join(' ')}</dl>
        </dd>`
      );
    }
    if ('createdFor' in data) {
      const { loc: createdForLoc, label: createdForLabel } = data.createdFor;
      html += (
        `<dt class="blacklight-wd-created col-sm-4">Created for:</dt>
        <dd class="col-sm-8" loc="${createdForLoc}">${createdForLabel} *</dd>`
      );
    }

    // Don't display prop from Wikidata if we are already displaying from solr
    const rdaLabels = $('[data-rda-label]').map(function() { return $(this).data('rda-label') }).get();
    $.each(bamwowHelper.fieldMapping, function(prop, label) {
      if (prop in data && !rdaLabels.includes(label)) {
        let value = data[prop];
        if (prop === 'date') value = bamwowHelper.formatDates(value);
        if ($.isArray(value)) value = value.join(', ');
        html += `<dt class="col-sm-4">${label}:</dt><dd class="col-sm-8">${value} *</dd>`;
      }
    });

    return html;
  };

  function generateWikidataSourceLinks(data) {
    if (!('entity' in data)) return '';
    return (
      `  <span class="ld-acknowledge">
        * <a href="${data.entity}">From Wikidata<i class="fa fa-external-link" aria-hidden="true"></i></a>
      </span>`
    );
  }

  return { renderLinkedData };
}

Blacklight.onLoad(function() {
  // Only load this code on Author-Title Browse entity page
  if ($('#author-title-heading').length) {
    AuthorTitleBrowse().renderLinkedData();
  }
});
