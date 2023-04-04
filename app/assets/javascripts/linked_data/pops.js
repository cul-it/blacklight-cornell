// Represents author knowledge panel
class kPanel {
  constructor() {
    this.imageSize = 100;
    this.authType = 'author';
  } 

  init() {
    this.bindEventListeners();
  }

  bindEventListeners() {
    const eThis = this;
    $('*[data-poload]').click(function(event) {
      event.preventDefault();
      const e = $(this);
      const auth = e.attr('data-auth').replace('&', '%26');
      const fullRecordLink = e.data("poload");
      const catalogAuthURL = `/panel?type=${eThis.authType}&authq="${auth}"`;
      $.get(catalogAuthURL, function(d) {
        const displayHTML = $(d).find('div#kpanelContent').html();
        // Change trigger to focus for prod- click for debugging
        e.popover({ content: displayHTML, html: true, trigger: 'focus' }).popover('show');
        // Can drop additional info type parameter if author page defaults to that view
        $('#fullRecordLink').attr('href', fullRecordLink);
        // Now get additional data
        eThis.getAdditionalData(auth);
      });
    });

    // Popover div won't exist until user clicks and displays
    // Mousedown will close popover before allowing link to be clicked
    // This prevents the default behavior within the popover itself and allows link to be clicked
    // Based on https://stackoverflow.com/questions/20299246/bootstrap-popover-how-add-link-in-text-popover
    $('body').on('mousedown', '.popover', function(e) {
      e.preventDefault();
    });
  }

  // Get other data from LOC and Wikidata
  getAdditionalData(auth) {
    const locPath = 'names';
    const rdfType = 'PersonalName';
    const locQuery = this.processAuthName(auth);
    // Incorporate when so loc suggestion and auth check occur together
    // and then wikidata is queried only if info can be displayed
    this.queryLOCSuggestions(locPath, locQuery, rdfType);  
  }

  // Remove any extra periods or commas when looking up LOC
  processAuthName(auth) {
     return auth.replace(/[,.]\s*$/, "");
  }
  
  //Lookup suggestions in LOC for this name specifically
  queryLOCSuggestions(locPath, locQuery, rdfType) {   
    const lookupURL = `https://id.loc.gov/authorities/${locPath}/suggest?q=${locQuery}&rdftype=${rdfType}&count=1`;
    const eThis = this;
    
    // Using timeout to handle query that doesn't return in 3 seconds for jsonp request
    $.ajax({
      url: lookupURL,
      dataType: 'jsonp',
      timeout: 3000,
      crossDomain: true,
      success: function (data) {
        const urisArray = eThis.parseLOCSuggestions(data);
        if (urisArray && urisArray.length > 0) {
          const locURI = urisArray[0]; 
          eThis.queryWikidata(locURI);
        }
        else {
            // Probably shouldn't be here, but we are. So vcall the function that hides the
            // time indicator and displays the panel contents.
            eThis.renderWikidataInfo(data);
        }
      },
      error: function(xhr) {
        // If LOC error occurs, then no additional requests are made to retrieve information
        console.log(`Error occurred retrieving LOC suggestion for ${locQuery}`);
        console.log(`${xhr.status}:${xhr.statusText}:${xhr.responseText}`);
      }
    });
  }
  
  parseLOCSuggestions(suggestions) {
    const urisArray = [];
    if (suggestions && suggestions[1] !== undefined) {
      for (let s = 0; s < suggestions[1].length; s++) {
        urisArray.push(suggestions[3][s]);
      }
    }
    return urisArray;
  }
  
  // Given an LOC URI, query if equivalent wikidata entity exists and get image and/or description
  queryWikidata(locURI) {
    const wikidataEndpoint = 'https://query.wikidata.org/sparql';
    const localname = this.getLocalName(locURI);
    const sparqlQuery = this.getWikidataQuery(localname);
    const eThis = this;
    $.ajax({
      url: wikidataEndpoint,
      headers: { Accept: 'application/sparql-results+json' },
      data: { query: sparqlQuery },
      context: this,
      success: function (data) {
        const wikidataParsedData = eThis.parseWikidataSparqlResults(data);
        eThis.renderWikidataInfo(wikidataParsedData);
      },
      error: function(xhr) {
        // If Wikidata  error occurs, then no information will be displayed
        console.log(`Error occurred retrieving Wikidata info for ${locURI}`);
        console.log(`${xhr.status}:${xhr.statusText}:${xhr.responseText}`);
       }
    });
  }

  getWikidataQuery(localname) {
    return (
      `SELECT *
      WHERE {
        ?entity wdt:P244 "${localname}".
        OPTIONAL {
          ?entity wdt:P18 ?image .
          BIND(STRAFTER(wikibase:decodeUri(STR(?image)), "http://commons.wikimedia.org/wiki/Special:FilePath/") AS ?fileTitle)
          SERVICE wikibase:mwapi {
            bd:serviceParam wikibase:endpoint "commons.wikimedia.org";
            wikibase:api "Generator";
            wikibase:limit "once";
            mwapi:generator "allpages";
            mwapi:gapfrom ?fileTitle;
            mwapi:gapnamespace 6;
            mwapi:gaplimit 1;
            mwapi:prop "imageinfo";
            mwapi:iiprop "extmetadata".
            ?imageLicense wikibase:apiOutput "imageinfo/ii/extmetadata/License/@value".
            ?imageLicenseShortName wikibase:apiOutput "imageinfo/ii/extmetadata/LicenseShortName/@value".
            ?imageLicenseUrl wikibase:apiOutput "imageinfo/ii/extmetadata/LicenseUrl/@value".
            ?imageArtist wikibase:apiOutput "imageinfo/ii/extmetadata/Artist/@value".
            ?imageName wikibase:apiOutput "imageinfo/ii/extmetadata/ObjectName/@value".
            ?imageTitle wikibase:apiOutput mwapi:title.
          }
        }
        OPTIONAL {
          ?entity schema:description ?description . FILTER(lang(?description) = "en")
        }
      }`
    );
  }
   
  parseWikidataSparqlResults(data) {
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
  }

  renderWikidataInfo(wikidataParsedData) {
    const { image, description } = wikidataParsedData;
    if (this.isSupportedImage(image)) {
      const resizedImage = `${image.url}?width=${this.imageSize}`;
      const wmcUrl = `https://commons.wikimedia.org/wiki/${image.title}`;
      const titleHtml = `"<a href="${wmcUrl}">${image.name || image.title}</a>"`;
      const licenseName = image.licenseShortName || image.license;
      const licenseHtml = image.licenseUrl ?
        ` / <a href="${image.licenseUrl}">${licenseName}</a>` :
        ` / ${licenseName}`;
      const artistHtml = image.artist ? ` by ${image.artist}`: '';
      const attributionHtml = `${titleHtml}${artistHtml}${licenseHtml}`;
      const imageHtml = (
        `<figure class="kp-entity-image float-left">
          <img src="${resizedImage}" />
        </figure>`
      );
      $('#imageContent').html(imageHtml);
      $('#imageAttribution').html(`<span class="kp-source">Image: ${attributionHtml}</span>`)
    }
    if(description) $('#wikidataDescription').html(description);

    $('#time-indicator').hide();
    $('#popoverContent').removeClass('d-none');
  }

  // Get localname from LOC URI
  getLocalName(uri) {
      // Get string right after last slash if it's present
      // TODO: deal with hashes later
      return uri.split('/').pop();
    }
  
  isSupportedImage(image) {
    return !!image?.title && this.isSupportedImageType(image?.url) && this.isSupportedLicense(image?.license);
  }
    
  // Only display images with certain file types
  isSupportedImageType(imageUrl) {
    if (!imageUrl) return false;

    const fileExtension = imageUrl.substr( (imageUrl.lastIndexOf('.') +1) ).toLowerCase();
    return SUPPORTED_IMAGE_TYPES.includes(fileExtension);
  }

  // Don't display images licensed by cc2
  isSupportedLicense(imageLicense) {
    return ALLOWED_LICENSES.includes(imageLicense);
  }
}

Blacklight.onLoad(function() {
  // Only load this code when the popup is available
  // Currently, only one primary author for each item view page
  // This can be extended to include separate code if multiple knowledge panels are possible
  if ( $('*[data-auth]').length ) {
    var kPanelObj = new kPanel();
    kPanelObj.init();
  }
});
