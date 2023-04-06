const subjectBrowse = {
  onLoad: function() {
    this.bindCrossRefsToggle();  
  },
  
  // TODO: This is broken because the views are rendering multiple #cr-refs-toggles and letting the js determine which one to display
  // https://culibrary.atlassian.net/browse/DISCOVERYACCESS-8035
  bindCrossRefsToggle: function() {
    $('#cr-refs-toggle').click(function() {
      if ( $('.toggled-cr-refs').first().is(':visible') ) {
        $('.toggled-cr-refs').hide();
        $('#cr-refs-toggle').html('more &raquo;');
      }
      else {
        $('.toggled-cr-refs').show();
        $('#cr-refs-toggle').html('&laquo; less');
      }
      return false;
    });
  },
};
const subjectDataBrowse = {
  onLoad: async function() {
    const localname = $('#subj_loc_localname').val();
    this.init();
    
    let dbpedia = {};
    let wikidata = {};
    if (this.displayAnyExternalData) {
      if (localname.length) {
        // Fetch and render image from wikidata and description from dbpedia
        const wdResults = await this.getWikidata(localname);
        wikidata = this.parseWikidata(wdResults);
        this.renderWikiImage(wikidata.image);

        // We only connect to dbpedia to get description, so don't bother if description should be excluded
        if (!this.isPropertyExcluded('description')) {
          const dbpediaResults = await this.getDbpediaDescription(wikidata);
          dbpedia = this.parseDbpediaResults(dbpediaResults);
          this.renderDescription({ wikidata, dbpedia });
        }
      }
      else {
        // Fetch description from dbpedia only
        if (!this.isPropertyExcluded('description')) {
          const dbpediaResults = await this.getDbpediaDescription();
          dbpedia = this.parseDbpediaResults(dbpediaResults);
          this.renderDescription({ dbpedia });
        }
      }
    }

    // Either display linked data or default catalog metadata
    this.showDetails({ wikidata, dbpedia });
  },
    
  init: function() {
  	this.exclusionsJSON = this.getExclusions();
  	this.exclusionPropertiesHash = this.createExclusionHash();
  	//false if external data should not be displayed at all for this authority
  	this.displayAnyExternalData = this.displayAuthExternalData();
    this.wikidataConnector = WikidataConnector();
  },
  
  // Get Image country = P17; territory P131; location P276
  getWikidata: async function(localname) {
    const sparqlQuery = (
      `SELECT ?entity ?label ?description ${this.wikidataConnector.imageSparqlSelect}
      WHERE {
        ?entity wdt:P244 "${localname}" .
        ?entity rdfs:label ?label . FILTER (langMatches( lang(?label), "EN" ) )
        OPTIONAL {?entity schema:description ?description . FILTER(lang(?description) = "en")}
        ${this.wikidataConnector.imageSparqlWhere}
      } LIMIT 1`
    );
    return this.wikidataConnector.getData(sparqlQuery);
  },
  parseWikidata: function(data) {
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

      if (this.canRender('description', description?.value)) {
        output.description = description.value.charAt(0).toUpperCase() + description.value.slice(1) + '.';
      }
      if (this.canRender('image', imageUrl?.value)) {
        const image = {
          url: imageUrl.value,
          license: imageLicense?.value,
          licenseShortName: imageLicenseShortName?.value,
          licenseUrl: imageLicenseUrl?.value,
          artist: imageArtist?.value,
          name: imageName?.value,
          title: imageTitle?.value
        };
        if (this.wikidataConnector.isSupportedImage(image)) output.image = image;
      };
      output.entity = entity?.value;
      output.label = label?.value;
    }
    return output;
  },
  renderWikiImage: function(image) {
    if (image) {
      $('#subject-image').attr('src', image.url);
      $('#img-container').show();
      $('#wiki-image-acknowledge').html(`<br/>Image: ${this.wikidataConnector.imageAttributionHtml(image)}`);
    } else {
      $('#comment-container').removeClass();
      $('#comment-container').addClass('col-sm-12').addClass('col-md-12').addClass('col-lg-12');
    }
  },
  qidAndLabel: function(data) {
    return {
      wikiLabel: data.label || $('h2').text().replaceAll('>','').trim(),
      wikiQid: data.entity?.split('/')[4] || 'x'
    }
  },
  
  // we can use the wikidata QID to get an entity description from DBpedia
  getDbpediaDescription: async function(data = {}) {
    const { qid, label } = this.qidAndLabel(data);
    const dbpediaUrl = 'https://dbpedia.org/sparql';
    const sparqlQuery = " SELECT distinct ?uri ?comment WHERE {"
                      + " { SELECT (?e1) AS ?uri ?comment WHERE { ?e1 dbp:d '" + qid + "'@en . ?e1 rdfs:comment ?comment . FILTER (langMatches(lang(?comment),\"en\")) }} UNION "
                      + " { SELECT (?e2) AS ?uri ?comment WHERE { ?e2 rdfs:label '" + label + "'@en . ?e2 rdfs:comment ?comment . FILTER (langMatches(lang(?comment),\"en\"))}}} "
    const fullQuery = `${dbpediaUrl}?query=${encodeURIComponent(sparqlQuery)}&format=json`;
    return $.ajax({
      url: fullQuery,
      headers: { Accept: 'application/sparql-results+json' },
      dataType: 'jsonp',
      'jsonp': 'callback',
    });
  },
  parseDbpediaResults: function(data) {
    const dbpOutput = {};
    const bindings = data?.results?.bindings;
    if (bindings && bindings.length) {
      const { comment, uri } = bindings[0];
      if (this.canRender('description', comment?.value)) {
        dbpOutput.description = comment.value;
        dbpOutput.uri = uri?.value;
      }
    }
    return dbpOutput;
  },
  renderDescription: function({ wikidata = {}, dbpedia = {} }) {
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
  },
  showDetails: function({ dbpedia, wikidata }) {
    if (wikidata.image || dbpedia.description) {
      this.displayLinkedData();
    } else {
      this.displayCatalogMetadata();
    }
  },
  displayCatalogMetadata: function() {
    $('#bio-desc').removeClass('d-none');
    $('#no-wiki-ref-info').removeClass('d-none');
  },
  displayLinkedData: function() {
    $('#info-details').removeClass('d-none');
    $('#has-wiki-ref-info').removeClass('d-none');
  },
  
  //Method for reading exclusion information i.e whether Wikdiata/DbPedia info will be allowed for this heading
  getExclusions: function() {
    const exclusionsInput = $('#exclusions');
    if (exclusionsInput.length && exclusionsInput.val() != '') {
      return JSON.parse(exclusionsInput.val());
    }
    return null;
  },
 
  //Is all external data not to be displayed for authority? If authority is present in the list and has no properties
  displayAuthExternalData: function() {
    const exclusionsJSON = this.exclusionsJSON;
    //no exclusions, or exclusion = false, or exclusion is true but there are properties
    return (exclusionsJSON == null || $.isEmptyObject(exclusionsJSON) ||
      ('exclusion' in exclusionsJSON && (exclusionsJSON['exclusion'] == false) ) ||
      ('exclusion' in exclusionsJSON && exclusionsJSON['exclusion'] == true && 'properties' in exclusionsJSON && exclusionsJSON['properties'].length));
  },
  isPropertyExcluded: function(propertyName) {
    // if this property exists in our hash, then that means it is one of the properties the yaml 
        // file indicates should not be displayed
    return ('exclusionPropertiesHash' in this && propertyName in this.exclusionPropertiesHash);
  },
  //relies on both presence of value and ability to display this data
  canRender: function(propertyName, value) {
    return !!value && !this.isPropertyExcluded(propertyName);
  },
  createExclusionHash: function() {
    const exclusionHash = {};
    if('properties' in this.exclusionsJSON && this.exclusionsJSON['properties'].length) {
      $.each(this.exclusionsJSON.properties, function(i, v) {
        exclusionHash[v] = true;
      });
	  }
    return exclusionHash;
  },
};

Blacklight.onLoad(function() {
  if ( $('body').prop('className').indexOf('browse-info') >= 0 ) {
    subjectBrowse.onLoad();
  }
  if ( $('#subj_loc_localname').length ) {
    subjectDataBrowse.onLoad();
  }
});  
