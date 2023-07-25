// Display enhanced music metadata from Wikidata (BAMWOW!) in work display
// https://wiki.lyrasis.org/display/LD4P3/WP3%3A+Discovery#WP3:Discovery-BAMWOW!(BrowsingAcrossMusicWithObtainableWikidata)
function Work() {
  const locConnector = LOCConnector();
  const bamwowHelper = BamwowHelper();
  // TODO: Add ability to exclude excludeEntities.yml?

  // Only fetch and display music data from wikidata in 2 scenarios:
  // 1. Only one author title facet: display wikidata directly on work
  // 2. Multiple author title facets and at least 1 included work: display wikidata in popover for each included work
  async function renderLinkedData() {
    try {
      // Data from html attributes
      const headingAttr = $('#work').data('heading');
      const includedWorksAttr = $('#work').data('included');
      const headings = parseHeadingAttr(headingAttr);
      const includedWorks = parseIncludedWorksAttr(includedWorksAttr);

      if (Object.keys(headings).length === 1) {
        // This only requires the parsed heading
        await displayDataOnWork(Object.values(headings)[0]['parsedHeading']);

        // Highlight data from wikidata on click
        $('#wikidata_highlight').on('click', function() {
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
        });
      }
      else if (Object.keys(headings).length && Object.keys(includedWorks).length) {
        // If more than one query heading, check included works if they exist
        // Popovers display if parsed included work matches an authortitle facet
        displayDataInPopovers(headings, includedWorks);
      }
    } catch(err) {
      console.log(err);
    }
  };

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

  // Attr Example #1:
  //   ["Vivaldi, Antonio, 1678-1741. Sonatas, op. 5. No. 1.|Sonatas, op. 5. No. 1.|Vivaldi, Antonio, 1678-1741.",
  //    "Vivaldi, Antonio, 1678-1741. Sonatas, op. 5. No. 2.|Sonatas, op. 5. No. 2.|Vivaldi, Antonio, 1678-1741."]
  // Attr Example #2:
  //   ["Container of (work): McAuley, Paul J. Winning peace.|Winning peace.|McAuley, Paul J.",
  //    "Container of (work): Leckie, Ann. Night's slow poison.|Night's slow poison.|Leckie, Ann."]
  // Returns list: [{ linkTextDisplay: 'Author Work' }]
  function parseIncludedWorksAttr(works) {
    const parsedWorks = {};
    if (works) {
      works.forEach(work => {
        const components = work.split('|').map(c => c.trim());
        if (components.length === 3) {
          // Parse includedWorks to match heading
          parsedWorks[components[0]] = `${components[2]} ${components[1].replace(/\.$/, '')}`;
        }
      });
    }

    return parsedWorks;
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
  async function displayDataInPopovers(headings, includedWorks) {
    // For each included work in list, add popover
    const includedWorksHtml = $('dd.blacklight-included_work_display a');
    includedWorksHtml.each(function() {
      const linkText = $(this).text().trim();
      if (includedWorks[linkText] in headings) {
        // Match heading formed from included_work_display to heading from authortitle_facet
        const dataForIncludedWork = headings[includedWorks[linkText]];
        if (dataForIncludedWork) {
          const { originalHeading, parsedHeading } = dataForIncludedWork;

          // Clicking included work button triggers popover
          const buttonEl = renderPopoverButton($(this));
          buttonEl.click(async function(e) {
            e.preventDefault();

            // Render kpanel view with data from solr browse index
            const catalogAuthURL = `/panel?type=authortitle&authq="${encodeURIComponent(originalHeading)}"`;
            const kpanelTemplate = await $.get(catalogAuthURL);
            const content = $(kpanelTemplate).find('#kpanelContent').html();
            // TODO: Investigate more accessible options for popover focus navigation
            // Change trigger to focus for prod- click for debugging
            $(this).popover({ content, html: true, trigger: 'focus' }).popover('show');
            // Get info from LOC + Wikidata
            renderPopoverContent(parsedHeading);
          });
        }
      }
    });
  };

  // Render popover button for included work
  function renderPopoverButton(includedWork) {
    // (Possible) TODO: Add matomo tracking on button click?
    //    Direct link to author-title browse page if mobile? (currently button doesn't show at all on mobile)
    const buttonHtml = (
      `<a
        href="#"
        role="button"
        tabindex="0"
        data-trigger="focus"
        class="info-button d-none d-sm-inline-block btn btn-sm btn-outline-secondary"
      >
        Work info »
      </a>`
    );
    // TODO: Styling when link text wraps with button? (e.g. /catalog/9769908)
    // $(this).css({ 'display': 'inline-block', 'max-width': '80%' });
    return $(buttonHtml).insertAfter(includedWork);
  };

  // Generate popup knowledge panel using plain Bootstrap
  async function renderPopoverContent(heading) {
    try {
      const localName = await locConnector.getLocalName(heading, 'NameTitle');
      if (localName) {
        // If LOC name found for heading, query Wikidata for additional data to display
        const wikidata = await bamwowHelper.getWikidata(localName);
        renderWikidataSubset(wikidata);
      }
    } catch (err) {
      console.log(err)
    } finally {
      hideSpinner();
    }
  };
    
  function renderWikidataSubset(data) {
    const fieldMappingSubset = {
      opus: bamwowHelper.fieldMapping.opus,
      tonalityLabel: bamwowHelper.fieldMapping.tonalityLabel,
      instrumentationLabel: bamwowHelper.fieldMapping.instrumentationLabel,
    };
    let html = '';

    // Some data may already be displaying from solr
    // Reset alternating line styling based on existing # of rows
    const rdaLabels = $('.rda-label').map(function(){ return $(this).text() }).get();
    let rowCount = $('#authorTitleDescriptionContainer .dt').length - 1;
    if (data.codes?.length > 0) {
      const codesArr = data.codes.map(code => `${code.catalogLabel} : ${code.code}`);
      html += (
        `<div class="dt field1-bg">Catalog numbers:</div>
        <div class="dd field1-bg">${codesArr.join('<br>')}</div>`
      );
      rowCount++;
    }

    $.each(fieldMappingSubset, function(prop, label) {
      // Don't display prop from Wikidata if we are already displaying from solr
      if (prop in data && !rdaLabels.includes(label)) {
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

  function hideSpinner() {
    $('#time-indicator').hide();
  };

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
