// Represents author knowledge panel
function KPanel() {
  const imageSize = 100
  const authType = 'author';
  const wikidataConnector = WikidataConnector();

  function init() {
    bindEventListeners();
  };

  function bindEventListeners() {
    $('*[data-poload]').click(function(event) {
      event.preventDefault();
      const e = $(this);
      const auth = e.attr('data-auth');
      const fullRecordLink = e.data('poload');
      const catalogAuthURL = `/panel?type=${authType}&authq="${encodeURIComponent(auth)}"`;
      $.get(catalogAuthURL, function(d) {
        const displayHTML = $(d).find('div#kpanelContent').html();
        // Change trigger to focus for prod- click for debugging
        e.popover({ content: displayHTML, html: true, trigger: 'focus' }).popover('show');
        // Can drop additional info type parameter if author page defaults to that view
        $('#fullRecordLink').attr('href', fullRecordLink);
        // Now get additional data
        getAdditionalData(auth);
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
  async function getAdditionalData(auth) {
    const locPath = 'names';
    const rdfType = 'PersonalName';
    const locQuery = processAuthName(auth);
    // Incorporate when so loc suggestion and auth check occur together
    // and then wikidata is queried only if info can be displayed
    try {
      const locResults = await queryLOCSuggestions(locPath, locQuery, rdfType);
      const locURI = parseLOCResults(locResults);
      if (locURI) {
        try {
          const wdResults = await queryWikidata(locURI);
          const parsedWikidata = parseWikidataResults(wdResults);
          renderWikidata(parsedWikidata);
        } catch(err) {
          console.log(`Error occurred retrieving Wikidata info for ${locURI}`);
          console.log(err);
        }
      }
    } catch(err) {
      // If LOC error occurs, then no additional requests are made to retrieve information
      console.log(`Error occurred retrieving LOC suggestion for ${locQuery}`);
      console.log(err);
    } finally {
      renderPopover();
    }
  };

  // Remove any extra periods or commas when looking up LOC
  function processAuthName(auth) {
    return auth.replace(/[,.]\s*$/, '');
  };
  
  // Lookup suggestions in LOC for this name specifically
  async function queryLOCSuggestions(locPath, locQuery, rdfType) {
    const lookupURL = `https://id.loc.gov/authorities/${locPath}/suggest?q=${encodeURIComponent(locQuery)}&rdftype=${rdfType}&count=1`;    
    // Using timeout to handle query that doesn't return in 3 seconds for jsonp request
    return $.ajax({
      url: lookupURL,
      dataType: 'jsonp',
      timeout: 3000,
      crossDomain: true
    });
  };
  
  function parseLOCResults(suggestions) {
    if (suggestions && suggestions[1] !== undefined) {
      return suggestions[3][0];
    }
  };
  
  // Given an LOC URI, query if equivalent wikidata entity exists and get image and/or description
  async function queryWikidata(locURI) {
    const localname = getLocalName(locURI);
    const sparqlQuery = (
      `SELECT *
      WHERE {
        ?entity wdt:P244 "${localname}".
        ${wikidataConnector.imageSparqlWhere}
        OPTIONAL {
          ?entity schema:description ?description . FILTER(lang(?description) = "en")
        }
      }`
    );
    return wikidataConnector.getData(sparqlQuery);
  };
   
  function parseWikidataResults(data) {
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
      const resizedImage = `${image.url}?width=${imageSize}`;
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

  function renderPopover() {
    $('#time-indicator').hide();
    $('#popoverContent').removeClass('d-none');
  };

  // Get localname from LOC URI
  function getLocalName(uri) {
    // Get string right after last slash if it's present
    // TODO: deal with hashes later
    return uri.split('/').pop();
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
