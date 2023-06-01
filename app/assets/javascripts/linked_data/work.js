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
    // Get data from Author-Title browse endpoint
    const authorTitleBrowseData = await getAuthorTitleBrowseData(headings);

    // Attach popovers for each included work
    attachWorkPopovers(authorTitleBrowseData);
  };

  async function getAuthorTitleBrowseData(headings) {
    const authorTitleBrowseData = {};

    await Promise.all(headings.map(async h => {
      // Get json from author-title browse endpoint
      const results = await $.getJSON(
        `/browse/info?browse_type=Author-Title&authq=${encodeURIComponent(h.originalHeading)}`
      );
      const parsedData = parseAuthorTitleBrowseResults(results);

      // We want the parsed heading, i.e. without the pipe, because we need to
      // match against the included work title from the html
      if (parsedData) authorTitleBrowseData[parsedData.parsedHeading] = parsedData;
    }));

    return authorTitleBrowseData;
  };

  function parseAuthorTitleBrowseResults(results) {
    if (results?.length && results[0]['authority']) {
      const { heading, counts_json, rda_json } = results[0];

      const parsedData = {};
      parsedData.originalHeading = heading;
      parsedData.parsedHeading = bamwowHelper.reformatHeading(heading);
      if (counts_json) parsedData.counts = JSON.parse(counts_json);
      if (rda_json) parsedData.rda = JSON.parse(rda_json);

      // Example parsedData:
      // {
      //   "originalHeading": "Vivaldi, Antonio, 1678-1741. | Sonatas, violin, continuo. Selections",
      //   "parsedHeading": "Vivaldi, Antonio, 1678-1741. Sonatas, violin, continuo. Selections",
      //   "counts": {
      //       "worksAbout": 0,
      //       "works": 5
      //   }
      // }
      return parsedData;
    }
  };

  function attachWorkPopovers(authorTitleBrowseData) {
    const includedWorksHtml = $('dd.blacklight-included_work_display a');
    includedWorksHtml.each(function() {
      const linkText = $(this).text();
      // Get rid of ending punctuation
      const strippedLinkText = linkText.replace(/\.$/, '').trim();
      if (strippedLinkText in authorTitleBrowseData) {
        const dataForIncludedWork = authorTitleBrowseData[strippedLinkText];
        const { originalHeading, parsedHeading } = dataForIncludedWork;

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
        const content = generateAuthorTitlePopoverHtml(dataForIncludedWork);
        $(`a[heading='${parsedHeading}']`).click(function(e) {
          e.preventDefault();

          // TODO: Call to rails and render a knowledge panel view, instead of rendering all the html in js?
          $(this).popover({ content, html: true, trigger: 'focus' }).popover('show');
          // Get info from LOC + Wikidata
          renderPopoverContent(parsedHeading);
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

  function generateAuthorTitlePopoverHtml(data) {
    const { originalHeading, parsedHeading, counts, rda } = data;
    const headingBrowseLink = `/browse/info?browse_type=Author-Title&authq=${encodeURIComponent(originalHeading)}`;
    const workSearchLink = `/?q=${encodeURIComponent(`"${originalHeading}"`)}&search_field=`;
    let html = `<h2>${parsedHeading}</h2>`;

    // works & worksAbout catalog links
    html += (
      `<div class="author-works float-none">
        Works: <a href="${workSearchLink}authortitle_browse" id="worksForHeading">${counts.works}</a>
      </div>
      <div class="author-works float-none">
        Works about: <a href="${workSearchLink}subjectwork_browse" id="worksAboutHeading">${counts.worksAbout}</a>
      </div>`
    );

    // Start divs for Author-Title browse data
    html += '<div id="authorTitleDescription"><div class="dl dl-horizontal" id="authorTitleDescriptionContainer">';
    let rowCount = 1;
    $.each(rda, function(label, value) {
      if ($.isArray(value)) value = value.join(', ');
      fieldClass = rowCount % 2 ? 'field1-bg' : 'field2-bg';
      html += (
        `<div class="dt ${fieldClass}">${label}: </div>
        <div class="dd ${fieldClass}">${value}</div>`
      );
      rowCount += 1;
    });
    // End divs for Author-Title browse data
    html += '</div></div>';

    // Link to Author-Title browse page for work
    const fullLink = (
      `<div class="mt-2 w-100 text-right">
        <a id="fullRecordLink" href="${headingBrowseLink}">
          <span class="info-button d-sm-inline-block btn btn-sm btn-outline-secondary">View full info &raquo;</span>
        </a>
      </div>`
    );
    return (
      `<div id="popoverContent" class="kp-content">
        <div id="panelMainContent" class="mt-2 float-none clearfix">${html}</div>
        ${fullLink}
      </div>`
    );
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
