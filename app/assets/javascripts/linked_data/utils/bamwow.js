// Supports retrieving music metadata from Wikidata in Author-Title browse and works
// https://wiki.lyrasis.org/display/LD4P3/WP3%3A+Discovery#WP3:Discovery-BAMWOW!(BrowsingAcrossMusicWithObtainableWikidata)
function BamwowHelper() {
  const wikidataConnector = WikidataConnector();

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

  // Remove pipe value from heading attr in catalog
  function reformatHeading(heading) {
    return heading.split('|').map(v => v.trim()).join(' ');
  };

  async function getWikidata(localName) {
    const sparqlQuery = (
      'SELECT ?entity ?codeval ?catalog ?catalogLabel ?music_created_for ?music_created_forLabel ?created_for_loc '
        + ' ?date ?location ?locationLabel ?opus ?dedicated ?dedicatedLabel ?commissionedBy ?commissionedByLabel '
        + ' ?tonality ?tonalityLabel ?librettist ?librettistLabel ?instrumentation ?instrumentationLabel '
      + ' WHERE { '
        + ` ?entity wdt:P244 "${localName}". `
        + ' OPTIONAL { ?entity p:P528 ?code. ?code ps:P528 ?codeval. ?code pq:P972 ?catalog. } '
        + ' OPTIONAL { ?entity wdt:P9899 ?music_created_for. ?music_created_for wdt:P244 ?created_for_loc. } '
        + ' OPTIONAL { ?entity wdt:P1191 ?date. } '
        + ' OPTIONAL { ?entity wdt:P4647 ?location. } '
        + ' OPTIONAL { ?entity wdt:P10855 ?opus. } '
        + ' OPTIONAL { ?entity wdt:P825 ?dedicated . } '
        + ' OPTIONAL { ?entity wdt:P88 ?commissionedBy. } '
        + ' OPTIONAL { ?entity wdt:P826 ?tonality. } '
        + ' OPTIONAL { ?entity wdt:P87 ?librettist. } '
        + ' OPTIONAL { ?entity wdt:P870 ?instrumentation. } '
        + ' SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en". } '
      + ' }'
    );
    const results = await wikidataConnector.getData(sparqlQuery);
    return parseWikidata(results);
  };

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

  function formatDates(dates) {
    return dates.map(date => {
      // Adding the UTC is important, otherwise it returns the date in the local time zone and the day can be off by one
      const formattedDate = new Date(date);
      const month = formattedDate.toLocaleDateString('default', { month: 'short' });
      return `${formattedDate.getUTCDate()} ${month}, ${formattedDate.getUTCFullYear()}`;
    });
  };

  // Are there properties available to display the information in the data from the query results
  function canRender(data) {
    return propertyNames().some(prop => prop in data);
  };

  function propertyNames() {
    return Object.keys(fieldMapping);
  };

  return {
    canRender,
    fieldMapping,
    formatDates,
    getWikidata,
    reformatHeading
  }
}