function SubjectBrowse() {
  function onLoad() {
    bindCrossRefsToggle();
  };

  function bindCrossRefsToggle() {
    $('#cr-refs-toggle').click(function() {
      if ( $('.toggled-cr-refs').first().is(':visible') ) {
        $('.toggled-cr-refs').hide();
        $('#cr-refs-toggle').html('Show more &raquo;');
      }
      else {
        $('.toggled-cr-refs').show();
        $('#cr-refs-toggle').html('&laquo; Show less');
      }
      return false;
    });
  };

  return { onLoad };
};
function SubjectDataBrowse() {
  const ldExcluder = LDExcluder();
  const wikidataConnector = WikidataConnector();
  const dbpediaConnector = DbpediaConnector();

  async function renderLinkedData() {
    let dbpedia = {};
    let wikidata = {};
    try {
      if (ldExcluder.entityIsNotExcluded) {
        // Fetch and render image from wikidata and description from dbpedia
        const localname = $('#subj_loc_localname').val();
        if (localname.length) wikidata = await getWikidata(localname);

        // We only connect to dbpedia to get description, so don't bother if description should be excluded
        if (!ldExcluder.isPropertyExcluded('description')) {
          dbpedia = await getDbpediaDescription(wikidata);
        }
      }
    } catch(err) {
      console.log(err);
    } finally {
      // Either display linked data or default catalog metadata
      showDetails({ wikidata, dbpedia });
    }
  };

  // Get Image country = P17; territory P131; location P276
  async function getWikidata(localname) {
    const sparqlQuery = (
      `SELECT ?entity ?label ?description ${wikidataConnector.imageSparqlSelect} `
      + ' WHERE { '
        + ` ?entity wdt:P244 "${localname}" . `
        + ' ?entity rdfs:label ?label . FILTER (langMatches(lang(?label), "EN")) '
        + ' OPTIONAL {?entity schema:description ?description . FILTER (lang(?description) = "en")} '
        + wikidataConnector.imageSparqlWhere
      + ' } LIMIT 1'
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
        entity,
        image: imageUrl,
        imageLicense,
        imageLicenseShortName,
        imageLicenseUrl,
        imageArtist,
        imageName,
        imageTitle,
        label,
      } = bindings[0];

      if (canRender('description', description?.value)) {
        output.description = description.value.charAt(0).toUpperCase() + description.value.slice(1) + '.';
      }
      if (canRender('image', imageUrl?.value)) {
        const image = {
          url: imageUrl.value,
          license: imageLicense?.value,
          licenseShortName: imageLicenseShortName?.value,
          licenseUrl: imageLicenseUrl?.value,
          artist: imageArtist?.value,
          name: imageName?.value,
          title: imageTitle?.value
        };
        if (wikidataConnector.isSupportedImage(image)) output.image = image;
      };
      output.entity = entity?.value;
      output.label = label?.value;
    }
    return output;
  };

  function renderWikiImage(image) {
    if (image) {
      $('#bio-image').attr('src', image.url);
      $('#img-container').removeClass('d-none');;
      $('#wiki-image-acknowledge').html(`Image: ${wikidataConnector.imageAttributionHtml(image)}`);
    } else {
      $('#comment-container').removeClass();
      $('#comment-container').addClass('col-sm-12').addClass('col-md-12').addClass('col-lg-12');
    }
    // Show the acknowledgement box if any text is present
    toggleAcknowledgements();
  };

  function qidAndLabel(data) {
    return {
      label: data.label || $('h2').text().replaceAll('>','').trim(),
      qid: data.entity?.split('/')[4] || 'x'
    }
  };

  // we can use the wikidata QID to get an entity description from DBpedia
  async function getDbpediaDescription(data = {}) {
    const { qid, label } = qidAndLabel(data);
    const sparqlQuery = " SELECT distinct ?uri ?comment WHERE {"
                      + " { SELECT (?e1) AS ?uri ?comment WHERE { ?e1 dbp:d '" + qid + "'@en . ?e1 rdfs:comment ?comment . FILTER (langMatches(lang(?comment),\"en\")) }} UNION "
                      + " { SELECT (?e2) AS ?uri ?comment WHERE { ?e2 rdfs:label '" + label + "'@en . ?e2 rdfs:comment ?comment . FILTER (langMatches(lang(?comment),\"en\"))}}} "
    return await dbpediaConnector.getData(sparqlQuery);
  };

  function renderDescription({ wikidata = {}, dbpedia = {} }) {
    const wdDescription = wikidata.description;
    const { description: dbpDescription, uri: dbpLink } = dbpedia;

    if (dbpDescription) {
      const dbpLinkHtml = dbpLink ? `<a href="${dbpLink}">From DBPedia<i class="fa fa-external-link" aria-hidden="true"></i></a>` : 'From DBPedia';
      const dbpAcknowledgementHtml = `  <span class="ld-acknowledge">(${dbpLinkHtml}.)</span>`;
      $('#dbp-comment').text(dbpDescription);
      $('#dbp-comment').append(dbpAcknowledgementHtml);
      $('#dbp-comment').show();
    } else if (wdDescription) {
      $('#dbp-comment').text(wdDescription);
      $('#dbp-comment').show();
    }
    // Show the acknowledgement box if any text is present
    toggleAcknowledgements();
  };

  function showDetails({ dbpedia, wikidata }) {
    if (wikidata.image || dbpedia.description) {
      renderWikiImage(wikidata.image);
      renderDescription({ dbpedia, wikidata })
      displayLinkedData();
    } else {
      displayCatalogMetadata();
    }
  };
  
  function displayCatalogMetadata() {
    $('#bio-without-ld').removeClass('d-none');
  };

  function displayLinkedData() {
    $('#bio-with-ld').removeClass('d-none');
    $('#ref-info').addClass('mt-4');
  };

  // Relies on both presence of value and ability to display this data
  function canRender(propertyName, value) {
    return !!value && !ldExcluder.isPropertyExcluded(propertyName);
  };

  // Removes 'd-none' when either ack span has text.
  function toggleAcknowledgements() {
    const hasWikiText = $('#wiki-acknowledge').text().trim().length > 0;
    const hasImgText  = $('#wiki-image-acknowledge').text().trim().length > 0;
    const $box = $('#wiki-acknowledge, #wiki-image-acknowledge').closest('.ld-acknowledge');
    if (hasWikiText || hasImgText) {
      $box.removeClass('d-none');
    } else {
      $box.addClass('d-none');
    }
  }
  return { renderLinkedData };
};

Blacklight.onLoad(function() {
  if ( $('body').prop('className').indexOf('browse-info') >= 0 ) {
    SubjectBrowse().onLoad();
  }
  if ( $('#subj_loc_localname').length ) {
    SubjectDataBrowse().renderLinkedData();
  }
});  
