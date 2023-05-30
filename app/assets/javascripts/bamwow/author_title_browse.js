function AuthorTitleBrowse() {
  const wikidataConnector = WikidataConnector();
  // TODO: Add ability to exclude excludeEntities.yml?

  // Order in mapping determines display order
  const fieldMapping = {
    'date': 'First performance date',
    'locationLabel': 'First performance location',
    'opus': 'Opus',
    'dedicatedLabel': 'Dedicated to',
    'commissionedByLabel': 'Commissioned by',
    'tonalityLabel': 'Tonality',
    'librettistLabel': 'Librettist',
    'instrumentationLabel': 'Instrumentation',
  };

  async function renderLinkedData() {
    try {
      const headingAttr = $('#author-title-heading').attr('heading');
      const heading = parseHeadingAttr(headingAttr);
      const localName = await getLocLocalName(heading);
      if (localName) {
        const wikidata = await getWikidata(localName);
        renderWikidata(wikidata);
      }
    } catch(err) {
      console.log(err);
    }
  };

  // Remove pipe value from heading attr in catalog
  function parseHeadingAttr(headingAttr) {
    const headings = headingAttr.split('|').map(heading => heading.trim());
    return headings.join(' ');
  };

  function renderWikidata(wikidata) {
    if (canRender(wikidata)) {
      const fieldHtml = generateFieldHTML(wikidata);
      $('dl#item-details').append(fieldHtml);

      const sourceLinkHtml = generateWikidataSourceLinks(wikidata);
      $('#wiki-acknowledge').html(sourceLinkHtml);
    }
  }

  async function getWikidata(localName) {
    const sparqlQuery = (
      "SELECT ?entity ?codeval ?catalog ?catalogLabel ?music_created_for ?music_created_forLabel ?created_for_loc ?date ?location ?locationLabel ?opus ?dedicated ?dedicatedLabel ?commissionedBy ?commissionedByLabel ?tonality ?tonalityLabel ?librettist ?librettistLabel ?instrumentation ?instrumentationLabel "
        + "WHERE {?entity wdt:P244 \"" + localName + "\" ." 
        + "OPTIONAL { ?entity p:P528 ?code. ?code ps:P528 ?codeval. ?code pq:P972 ?catalog.}"
        + "OPTIONAL { ?entity wdt:P9899 ?music_created_for. ?music_created_for wdt:P244 ?created_for_loc. }"
        + "OPTIONAL { ?entity wdt:P1191 ?date. }"
        + "OPTIONAL { ?entity wdt:P4647 ?location. }"
        + "OPTIONAL { ?entity wdt:P10855 ?opus. }"
        + "OPTIONAL { ?entity wdt:P825 ?dedicated. }"
        + "OPTIONAL { ?entity wdt:P88 ?commissionedBy. }"
        + "OPTIONAL { ?entity wdt:P826 ?tonality. }"
        + "OPTIONAL { ?entity wdt:P87 ?librettist. }"
        + "OPTIONAL { ?entity wdt:P870 ?instrumentation. }"
        + "  SERVICE wikibase:label { bd:serviceParam wikibase:language \"[AUTO_LANGUAGE],en\". }"
        + "}"
    );
    const results = await wikidataConnector.getData(sparqlQuery);
    return parseWikidata(results);
  };

  // Are there properties available to display the information in the data from the query results
  function canRender(data) {
    return propertyNames().some(prop => prop in data)
  };

  // TODO: Move to utils/loc_connector.js
  async function getLocLocalName(heading) {
    const results = await $.ajax({
      url: `https://id.loc.gov/authorities/names/suggest/?q=${encodeURIComponent(heading)}&rdftype=NameTitle&count=1`,
      dataType: 'jsonp'
    });
    return parseLocResults(results);
  };

  // Example LOC results:
  // [
  //   "Vivaldi, Antonio, 1678-1741. Sonatas, op. 5. No. 1",
  //   ["Vivaldi, Antonio, 1678-1741. Sonatas, op. 5. No. 1"],
  //   ["1 result"],
  //   ["http://id.loc.gov/authorities/names/no2003085675"]
  // ]
  function parseLocResults(suggestions) {
    if (suggestions && suggestions.length > 3 && suggestions[1] !== undefined) {
      const locURI = suggestions[3][0];
      // Get string right after last slash if it's present
      return locURI?.split('/')?.pop();
    }
  }

  function parseWikidata(data) {
    const output = {};
    const bindings = data?.results?.bindings;

    if (bindings && bindings.length) {
      const catalogCodes = {};
      $.each(bindings, function(_i, binding) {
        const {
          entity,
          catalogLabel,
          codeval,
          music_created_forLabel,
          created_for_loc
        } = binding;
        output.entity ||= entity?.value;

        // catalog label and code value pairs, as nested objects, and multiple possible
        // Assume the pairing of catalog and code will always be unique, and there is only one code per catalog
        if (catalogLabel && codeval) catalogCodes[catalogLabel.value] = codeval.value;;
        
        // music created for label and accompanying LCCN
        if (music_created_forLabel && created_for_loc) {
          output.createdFor ||= { 'label': music_created_forLabel.value, 'loc': created_for_loc.value };
        }

        $.each(propertyNames(), function(i, prop) {
          if (prop in binding) {
            output[prop] ||= [];
            output[prop].push(binding[prop]['value']);
          }
        });
      });

      // Remove duplicates
      $.each(output, function(key, value) {
        if ($.isArray(value) && (value.length > 1)) {
          output[key] = [...new Set(value)];
        }
      });

      // Set unique catalog codes
      $.each(catalogCodes, function (c, cval) {
        output.codes ||= [];
        output.codes.push({ 'catalogLabel': c, 'code': cval });
      });
    }

    return output;
  };

  function propertyNames() {
    return Object.keys(fieldMapping);
  };

  // Generate fields
  function generateFieldHTML(data) {
    let html = '';
    if (data.codes?.length) {
      const codesArr = data.codes.map(code => `<dt>${code['catalogLabel']} : ${code['code']} *</dt>`);
      html += `<dt class="col-sm-4">Codes:</dt><dd class="col-sm-8"><dl class="dl-horizontal">${codesArr.join(' ')}</dl></dd>`;
    }
    if ('createdFor' in data) {
      const { loc: createdForLoc, label: createdForLabel } = data.createdFor;
      html += `<dt class="blacklight-wd-created col-sm-3">Created for:</dt><dd class="col-sm-8" loc="${createdForLoc}">${createdForLabel} *</dd>`;
    }

    $.each(fieldMapping, function(prop, label) {
      if (prop in data) {
        let value = data[prop];
        if (prop === 'date') value = formatDates(value);
        if ($.isArray(value)) value = value.join(', ');
        html += `<dt class="col-sm-4">${label}:</dt><dd class="col-sm-8">${value} *</dd>`;
      }
    });

    return html;
  };

  function formatDates(dates) {
    return dates.map(date => formatSingleDate(date));
  };

  function formatSingleDate(date) {
    // Adding the UTC is important, otherwise it returns the date in the local time zone and the day can be off by one
    const formattedDate = new Date(date);
    const month = formattedDate.toLocaleDateString('default', {month: 'short'});
    return `${formattedDate.getUTCDate()} ${month}, ${formattedDate.getUTCFullYear()}`;
  }

  function generateWikidataSourceLinks(data) {
    if ('entity' in data) {
      return `  <span class="ld-acknowledge">* <a href="${data.entity}">From Wikidata<i class="fa fa-external-link" aria-hidden="true"></i></a></span>`;
    } else {
      return '';
    }
  }

  return { renderLinkedData };
}

Blacklight.onLoad(function() {
  // Only load this code on Author-Title Browse entity page
  // TODO: Do we want to run a music sparql query for EVERY author-title browse record? Or just those with a certain format (e.g. Musical Score/Recordings?
  if ($('#author-title-heading').length) {
    AuthorTitleBrowse().renderLinkedData();
  }
});
