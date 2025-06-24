// https://id.loc.gov/authorities/names/suggest/?q=Twain,+Mark,+1835-1910
// id.loc.gov/authorities/names/label/[label]
function AuthorBrowse() {
  const ldExcluder = LDExcluder();
  const wikidataConnector = WikidataConnector();
  const dbpediaConnector = DbpediaConnector();

  async function renderLinkedData() {
    let wikidata = {};
    let dbpedia = {};
    try {
      if (ldExcluder.entityIsNotExcluded) {
        const localname = $('#auth_loc_localname').val();
        wikidata = await getWikidata(localname);
        if (hasWikiData(wikidata)) {
          // We only connect to dbpedia to get description, so don't bother if description should be excluded
          if (!ldExcluder.isPropertyExcluded('description')) {
            dbpedia = await getDbpediaDescription(wikidata);
          }
        }
      }
    } catch(err) {
      console.log(err);
    } finally {
      // Either display linked data or default catalog metadata
      showDetails({ wikidata, dbpedia });
    }

    bindEventHandlers();
  };

  // TODO: what is this doing? there doesn't seem to be a 'a[data-toggle="tab"]' in the dom??
  function bindEventHandlers() {
    $('a[data-toggle="tab"]').click(function() {
      const clicked = this;
      $('li.nav-link').each(function() {
        $(this).removeClass('active');
      });
      $(clicked).parent('li').addClass('active');
    });
  };

  function hasWikiData(data) {
    const wdProps = ['image', 'education', 'citizenship', 'pseudonyms'];
    return wdProps.some(k => k in data);
  };

  // Get image and metadata
  async function getWikidata(localname) {
    const sparqlQuery = (
      'SELECT '
        + ' ?entity ?citizenship ?label ?description '
        + wikidataConnector.imageSparqlSelect
        + ' (group_concat(DISTINCT ?educated_at; separator = ", ") as ?education) '
        + ' (group_concat(DISTINCT ?pseudos; separator = ", ") as ?pseudonyms) '
      + ' WHERE { '
        + ` ?entity wdt:P244 "${localname}"; `
                + ' rdfs:label ?label. FILTER (langMatches( lang(?label), "EN" ) ) '
        + ' OPTIONAL { ?entity wdt:P27/rdfs:label ?citizenship. FILTER (langMatches( lang(?citizenship), "EN" ) ) } '
        + ' OPTIONAL { ?entity wdt:P69/rdfs:label ?educated_at. FILTER (langMatches( lang(?educated_at), "EN" ) ) } '
        + ' OPTIONAL { ?entity wdt:P742 ?pseudos. } '
        + ' OPTIONAL { ?entity schema:description ?description. FILTER(lang(?description) = "en") } '
        + wikidataConnector.imageSparqlWhere
      + ` } GROUP BY ?entity ?citizenship ?label ?description ${wikidataConnector.imageSparqlSelect} LIMIT 1`
    );
    const results = await wikidataConnector.getData(sparqlQuery);
    return parseWikidata(results);
  };

  function parseWikidata(data) {
    const output = {};
    const bindings = data?.results?.bindings;

    if (bindings && bindings.length) {
      const {
        citizenship,
        description,
        education,
        entity,
        image: imageUrl,
        imageLicense,
        imageLicenseShortName,
        imageLicenseUrl,
        imageArtist,
        imageName,
        imageTitle,
        label,
        pseudonyms,
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
      if (canRender('citizenship', citizenship?.value)) {
        output.citizenship = citizenship.value;
      }
      if (canRender('education', education?.value)) {
        output.education = $.unique(education.value.split(', '));
      }

      // Remove any duplicate pseuds and primary name
      // Shouldn't really be dependent on dom, but wanted to retain previous render logic
      if (canRender('pseudonyms', pseudonyms?.value) && $('.agent-notes').length === 0) {
        output.pseudonyms = $.unique(pseudonyms.value.split(', '));
        output.pseudonyms = output.pseudonyms.filter(pseud => pseud != label?.value);
      }

      output.entity = entity?.value;
      output.label = label?.value;
    }

    return output;
  };

  function qidAndLabel(data) {
    return {
      label: data.label,
      qid: data.entity?.split('/')[4]
    }
  };

  function renderWikidata(parsedWikidata) {
    const { citizenship, education, entity, image, pseudonyms } = parsedWikidata;

    if (image) {
      $('#bio-image').attr('src', image.url);
      $('#img-container').removeClass('d-none');;
      $('#wiki-image-acknowledge').html(`Image: ${wikidataConnector.imageAttributionHtml(image)}`);
    } else {
      $('#comment-container').removeClass();
      $('#comment-container').addClass('col-sm-12').addClass('col-md-12').addClass('col-lg-12');
    }
    if (citizenship) {
      $('dd.citizenship').text(citizenship + '*');
      $('.citizenship').removeClass('citizenship');
    }
    if (education) {
      $('dd.education').text(education.join(', ') + '*');
      $('.education').removeClass('education');
    }

    // TODO: I don't think this ever renders? - dl#itemDetails is only in _show_default, not in author browse
    if (pseudonyms) {
      if ( $('.agent-notes').length === 0 ) {
        let the_html = '<dt class="col-sm-4">Notes:</dt><dd class="col-sm-8">For works of this author written under other names, search also under: <ul class="agent-notes">';
        $.each(pseudonyms, function(k,v) {
          the_html += '<li>' + v + '</li>';
        });
        the_html += '</ul></dd>';
        if ( the_html.indexOf('<li>') > 0 ) {
          $('dl#itemDetails').append(the_html + '*');
        }
      }
    }

    $('#wiki-acknowledge').append(`* <a href="${entity}">From Wikidata<i class="fa fa-external-link" aria-hidden="true"></i></a>`);
  };

	// we can use the wikidata QID to get an entity description from DBpedia
	async function getDbpediaDescription(wikidata) {
    const { qid, label } = qidAndLabel(wikidata);
    const sparqlQuery = " SELECT distinct ?uri ?comment WHERE {"
                        + " { SELECT (?e1) AS ?uri ?comment WHERE { ?e1 dbp:d '" + qid + "'@en . ?e1 rdfs:comment ?comment . "
                        + " ?e1 rdf:type dbo:Person . FILTER (langMatches(lang(?comment),\"en\")) } } UNION "
                        + " { SELECT (?e2) AS ?uri ?comment WHERE { ?e2 rdfs:label '" + label + "'@en . ?e2 rdfs:comment ?comment . "
                        + " ?e2 rdf:type dbo:Person . FILTER (langMatches(lang(?comment),\"en\"))} } UNION "
                        + " { SELECT (?e3) AS ?uri ?comment WHERE { ?e3 rdfs:label '" + label + "'@en . ?e3 rdfs:comment ?comment . "
                        + " ?e3 rdf:type yago:Person100007846 . FILTER (langMatches(lang(?comment),\"en\"))} }} ";
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
  };

  function showDetails({ dbpedia, wikidata }) {
    if (hasWikiData(wikidata)) {
      renderWikidata(wikidata);
      renderDescription({ wikidata, dbpedia });
      displayLinkedData();
    } else {
      displayCatalogMetadata();
    }
  };

  // when there's no wikidata or an error occurs in one of the ajax calls
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

  return { renderLinkedData };
};

Blacklight.onLoad(function() {
  if ( $('body').prop('className').indexOf('browse-info') >= 0 && $('#auth_loc_localname').length ) {
    AuthorBrowse().renderLinkedData();
  }
});