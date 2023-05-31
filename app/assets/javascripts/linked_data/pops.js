// Represents author knowledge panel
function KPanel() {
  const wikidataConnector = WikidataConnector();
  const locConnector = LOCConnector();

  function init() {
    bindEventListeners();
  };

  function bindEventListeners() {
    $('*[data-poload]').click(function(event) {
      event.preventDefault();
      const e = $(this);
      const authority = e.data('auth');
      const fullRecordLink = e.data('poload');
      const catalogAuthURL = `/panel?type=author&authq="${encodeURIComponent(authority)}"`;
      $.get(catalogAuthURL, function(d) {
        const displayHTML = $(d).find('div#kpanelContent').html();
        // Change trigger to focus for prod- click for debugging
        e.popover({ content: displayHTML, html: true, trigger: 'focus' }).popover('show');
        // Can drop additional info type parameter if author page defaults to that view
        $('#fullRecordLink').attr('href', fullRecordLink);
        // Now get additional data
        renderKPanelContent(authority);
      });
    });

    // Popover div won't exist until user clicks and displays
    // Mousedown will close popover before allowing link to be clicked
    // This prevents the default behavior within the popover itself and allows link to be clicked
    // Based on https://stackoverflow.com/questions/20299246/bootstrap-popover-how-add-link-in-text-popover
    $('body').on('mousedown', '.popover', function(e) {
      e.preventDefault();
    });
  };

  // Get other data from LOC and Wikidata
  async function renderKPanelContent(authority) {
    const locQuery = processAuthorityName(authority);

    // Incorporate when so loc suggestion and auth check occur together
    // and then wikidata is queried only if info can be displayed
    try {
      const localName = await locConnector.getLocalName(locQuery, 'PersonalName');;
      if (localName) {
        try {
          const wikidata = await getWikidata(localName);
          renderWikidata(wikidata);
        } catch(err) {
          console.log(`Error occurred retrieving Wikidata info for ${localName}`);
          console.log(err);
        }
      }
    } catch(err) {
      // If LOC error occurs, then no additional requests are made to retrieve information
      console.log(`Error occurred retrieving LOC suggestion for ${locQuery}`);
      console.log(err);
    } finally {
      showPopoverContent();
    }
  };

  // Remove any extra periods or commas when looking up LOC
  function processAuthorityName(authority) {
    return authority?.replace(/[,.]\s*$/, '');
  };
  
  // Given an LOC URI, query if equivalent wikidata entity exists and get image and/or description
  async function getWikidata(localName) {
    const sparqlQuery = (
      'SELECT *'
      + 'WHERE {'
        + `?entity wdt:P244 "${localName}".`
        + wikidataConnector.imageSparqlWhere
        + 'OPTIONAL { ?entity schema:description ?description. FILTER(lang(?description) = "en") }'
      + '}'
    );
    const results = await wikidataConnector.getData(sparqlQuery);
    return parseWikidata(results);
  };
   
  function parseWikidata(data) {
    const output = {};
    const bindings = data?.results?.bindings;
    if (bindings && bindings.length) {
      const {
        description,
        image,
        imageLicense,
        imageLicenseShortName,
        imageLicenseUrl,
        imageArtist,
        imageName,
        imageTitle
      } = bindings[0];
      output.description = description?.value;
      output.image = {
        url: image?.value,
        license: imageLicense?.value,
        licenseShortName: imageLicenseShortName?.value,
        licenseUrl: imageLicenseUrl?.value,
        artist: imageArtist?.value,
        name: imageName?.value,
        title: imageTitle?.value
      };
    }
    return output;
  };

  function renderWikidata(parsedWikidata) {
    const { image, description } = parsedWikidata;
    if (wikidataConnector.isSupportedImage(image)) {
      const resizedImage = `${image.url}?width=100`;
      const attributionHtml = wikidataConnector.imageAttributionHtml(image);
      const imageHtml = (
        `<figure class="kp-entity-image float-left">
          <img src="${resizedImage}" />
        </figure>`
      );
      $('#imageContent').html(imageHtml);
      $('#imageAttribution').html(`<span class="kp-source">Image: ${attributionHtml}</span>`)
    }
    if(description) $('#wikidataDescription').html(description);
  };

  function showPopoverContent() {
    $('#time-indicator').hide();
    $('#popoverContent').removeClass('d-none');
  };

  return { init }
}

Blacklight.onLoad(function() {
  // Only load this code when the popup is available
  // Currently, only one primary author for each item view page
  // This can be extended to include separate code if multiple knowledge panels are possible
  if ( $('*[data-auth]').length ) {
    KPanel().init();
  }
});
