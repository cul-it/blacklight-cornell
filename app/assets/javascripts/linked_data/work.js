// Display enhanced music metadata from Wikidata (BAMWOW!) in work display
// https://wiki.lyrasis.org/display/LD4P3/WP3%3A+Discovery#WP3:Discovery-BAMWOW!(BrowsingAcrossMusicWithObtainableWikidata)
function Work() {
  const locConnector = LOCConnector();
  const bamwowHelper = BamwowHelper();
  // TODO: Add ability to exclude excludeEntities.yml?

  // Data from html attributes
  const headingAttr = $('#work').attr('heading');
  const includedWorksAttr = $('#work').attr('included');

  // Only fetch and display music data from wikidata in 2 scenarios:
  // 1. Only one author title facet: display wikidata directly on work
  // 2. Multiple included works: display wikidata in popover for each included work
  function renderLinkedData() {
    try {
      // There may be multiple author title facets possible
      const headings = parseHeadingAttr(headingAttr);
      const includedWorks = parseIncludedWorksAttr(includedWorksAttr);
      // If more than one query heading, check included works if they exist
      if (headings.length === 1) {
        // This only requires the parsed heading
        displayDataOnWork(headings[0]['parsedHeading']);
      }
      else if (headings.length > 1 && includedWorks.length) {
        displayDataInPopovers(headings);
      }
    } catch(err) {
      console.log(err);
    }
  };

  function parseHeadingAttr(attr) {
    if (!attr) return [];

    const headings = JSON.parse(attr);
    return headings.map(originalHeading => {
      // Remove pipe value from heading attr in catalog
      const parsedHeading = bamwowHelper.reformatHeading(originalHeading);
      return { originalHeading, parsedHeading };
    });
  };

  // Just return first part of work attr (before first pipe value, if any)
  function parseIncludedWorksAttr(attr) {
    if (!attr) return [];

    const works = JSON.parse(attr);
    return works.map(work => work.split('|').map(v => v.trim())[0]);
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

  // Display metadata from Author-Title browse and Wikidata as a popover for each included work
  async function displayDataInPopovers(headings) {
    // Format headings for faster lookup by parsedHeading
    const headingsData = {}
    headings.forEach(h => headingsData[h.parsedHeading] = h);

    // For each included work in list, add popover
    const includedWorksHtml = $('dd.blacklight-included_work_display a');
    includedWorksHtml.each(function() {
      const linkText = $(this).text();
      // Get rid of ending punctuation
      const strippedLinkText = linkText.replace(/\.$/, '').trim();
      if (strippedLinkText in headingsData) {
        const dataForIncludedWork = headingsData[strippedLinkText];
        const { originalHeading, parsedHeading } = dataForIncludedWork;

        // (Possible) TODO: Render button at page load in view instead of when data fetches are done, like Author Info?
        //    Add matomo tracking on button click?
        //    Direct link to author-title browse page if mobile? (currently button doesn't show at all on mobile)
        // Render buttons for each included work
        const buttonHtml = (
          `<a
            originalHeading="${originalHeading}"
            heading="${parsedHeading}"
            href="#"
            role="button"
            tabindex="0"
            data-trigger="focus"
            class="info-button d-none d-sm-inline-block btn btn-sm btn-outline-secondary"
          >
            Work info »
          </a>`
        );
        $(this).after(buttonHtml);

        // Clicking included work button triggers popover
        $(`a[heading='${parsedHeading}']`).click(function(e) {
          e.preventDefault();
          const eThis = $(this);

          // Render kpanel view with data from solr browse index
          const catalogAuthURL = `/panel?type=authortitle&authq="${encodeURIComponent(originalHeading)}"`;
          $.get(catalogAuthURL, function(d) {
            const content = $(d).find('div#kpanelContent').html();
            // TODO: Investigate more accessible options for popover focus navigation
            // Change trigger to focus for prod- click for debugging
            eThis.popover({ content, html: true, trigger: 'focus' }).popover('show');
            // Get info from LOC + Wikidata
            renderPopoverContent(parsedHeading);
          });
        });
      }
    });
  };

  // Generate popup knowledge panel using plain Bootstrap
  async function renderPopoverContent(heading) {
    const localName = await locConnector.getLocalName(heading, 'NameTitle');
    if (localName) {
      // If LOC name found for heading, query Wikidata for additional data to display
      const wikidata = await bamwowHelper.getWikidata(localName);
      renderWikidataSubset(wikidata);
    }
  };
    
  function renderWikidataSubset(data) {
    const fieldMappingSubset = {
      opus: bamwowHelper.fieldMapping.opus,
      tonalityLabel: bamwowHelper.fieldMapping.tonalityLabel,
      instrumentationLabel: bamwowHelper.fieldMapping.instrumentationLabel,
    };
    let html = '';

    if (data.codes?.length > 0) {
      const codesArr = data.codes.map(code => `${code.catalogLabel} : ${code.code}`);
      html += (
        `<div class="dt field1-bg">Codes</div>
        <div class="dd field1-bg">${codesArr.join('<br>')}</div>`
      );
    }

    let rowCount = 0;
    $.each(fieldMappingSubset, function(prop, label) {
      if (prop in data) {
        let value = data[prop];
        if ($.isArray(value)) value = value.join(', ');
        const fieldClass = rowCount % 2 ? 'field1-bg' : 'field2-bg';
        html += (
          `<div class="dt ${fieldClass}">${label}: </div>
          <div class="dd ${fieldClass}">${value}</div>`
        );
        rowCount += 1;
      }
    });

    $('#authorTitleDescriptionContainer').append(html);
  };

  // Generate fields
  function generateFieldHTML(data) {
    let html = "";
    if (data.codes?.length) {
      const codesArr = data.codes.map(code => `${code.catalogLabel} : ${code.code} *`);
      html += (
        `<dt class="blacklight-wd-codes col-sm-3">Codes:</dt>
        <dd class="blacklight-wd-codes col-sm-9">${codesArr.join('<br>')}</dd>`
      );
    }
    if ('createdFor' in data) {
      const { loc: createdForLoc, label: createdForLabel } = data.createdFor;
      html += (
        `<dt class="blacklight-wd-created col-sm-3">Created for:</dt>
        <dd class="blacklight-wd-created col-sm-9" loc="${createdForLoc}">${createdForLabel} *</dd>`
      );
    }

    $.each(bamwowHelper.fieldMapping, function(prop, label) {
      if (prop in data) {
        let value = data[prop];
        if (prop === 'date') value = bamwowHelper.formatDates(value);
        if ($.isArray(value)) value = value.join(', ');
        const className = `blacklight-wd-${label.replace(/\s+/g, '')}`;
        html += (
          `<dt class="${className} col-sm-3">${label}:</dt>
          <dd class="${className} col-sm-9">${value} *</dd>`
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
          * Some information for this item comes from
          <a href="${data.entity}">Wikidata <i class="fa fa-external-link" aria-hidden="true"></i></a>
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
