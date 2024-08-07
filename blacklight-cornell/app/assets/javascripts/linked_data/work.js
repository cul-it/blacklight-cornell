// Display enhanced music metadata from Wikidata (BAMWOW!) in work display
// https://wiki.lyrasis.org/display/LD4P3/WP3%3A+Discovery#WP3:Discovery-BAMWOW!(BrowsingAcrossMusicWithObtainableWikidata)
function Work() {
  const locConnector = LOCConnector();
  const bamwowHelper = BamwowHelper();
  // TODO: Add ability to exclude excludeEntities.yml?

  // Fetch and display music data from wikidata if only one author title facet
  async function renderLinkedData() {
    try {
      // Data from html attributes
      const headingAttr = $('#work').data('heading');
      const headings = parseHeadingAttr(headingAttr);

      if (Object.keys(headings).length === 1) {
        // If only one authortitle heading, display data on work
        await displayDataOnWork(Object.values(headings)[0]['parsedHeading']);

        // Highlight data from wikidata in item details on click
        $('#wikidata_highlight').on('click', addWdHighlightHandler);
      }
    } catch(err) {
      console.log(err);
    }
  };

  function addWdHighlightHandler() {
    if ($('#wikidata_highlight').text().indexOf('Highlight') > -1) {
      $('.wd-highlight').each(function() {
        $(this).addClass('wikidata-bgc');
      });
      $('#wikidata_highlight').text('Remove the Wikidata highlighting.')
    }
    else {
      $('.wd-highlight').each(function() {
        $(this).removeClass('wikidata-bgc');
      });
      $('#wikidata_highlight').text('Highlight the Wikidata data.')
    }
    return false;
  }

  function parseHeadingAttr(headings) {
    if (!headings) return {};

    const headingsData = {}
    headings.forEach(originalHeading => {
      // Remove pipe value from heading attr in catalog
      const parsedHeading = bamwowHelper.reformatHeading(originalHeading);
      // Format headings for faster lookup by parsedHeading
      headingsData[parsedHeading] = { originalHeading, parsedHeading };
    });
    return headingsData;
  };

  async function displayDataOnWork(heading) {
    const localName = await locConnector.getLocalName(heading, 'NameTitle');
    if (localName) {
      // If LOC name found for heading, query Wikidata for additional data to display
      const wikidata = await bamwowHelper.getWikidata(localName);
      renderWikidata(wikidata);
    }
  };

  function renderWikidata(data) {
    if (bamwowHelper.canRender(data)) {
      const fieldHtml = generateFieldHTML(data);
      $('#itemDetails').append(fieldHtml);

      const sourceLinkHtml = generateWikidataSourceLinks(data);
      $('#wikidata_source').append(sourceLinkHtml);
    }
  }

  // Generate fields
  function generateFieldHTML(data) {
    let html = "";
    if (data.codes?.length) {
      const codesArr = data.codes.map(code => `${code.catalogLabel} : ${code.code}`);
      html += (
        `<dt class="blacklight-wd-codes col-sm-3"><div class="wd-highlight">Catalog numbers:</div></dt>
        <dd class="blacklight-wd-codes wd-highlight col-sm-9">${codesArr.join('<br>')}</dd>`
      );
    }
    if ('createdFor' in data) {
      const { loc: createdForLoc, label: createdForLabel } = data.createdFor;
      html += (
        `<dt class="blacklight-wd-created col-sm-3"><div class="wd-highlight">Created for:</div></dt>
        <dd class="blacklight-wd-created wd-highlight col-sm-9" loc="${createdForLoc}">${createdForLabel}</dd>`
      );
    }

    $.each(bamwowHelper.fieldMapping, function(prop, label) {
      if (prop in data) {
        let value = data[prop];
        if (prop === 'date') value = bamwowHelper.formatDates(value);
        if ($.isArray(value)) value = value.join(', ');
        const className = `blacklight-wd-${label.replace(/\s+/g, '')}`;
        html += (
          `<dt class="${className} col-sm-3"><div class="wd-highlight">${label}:</div></dt>
          <dd class="${className} wd-highlight col-sm-9">${value}</dd>`
        );
      }
    });

    return html;
  };

  function generateWikidataSourceLinks(data) {
    if (!('entity' in data)) return '';

    return (
      `<div>
        <span>
          Some of this information comes from
          <a href="${data.entity}">Wikidata <i class="fa fa-external-link" aria-hidden="true"></i></a>
          <br/>
          <a id="wikidata_highlight" href="#">Highlight the Wikidata data.</a>
        </span>
      </div>`
    );
  };

  return { renderLinkedData };
}

Blacklight.onLoad(function () {
  // Only load this code on entity page
  if ($('#work').length) {
    Work().renderLinkedData();
  }
});
