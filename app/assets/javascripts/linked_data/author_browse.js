// https://id.loc.gov/authorities/names/suggest/?q=Twain,+Mark,+1835-1910
// id.loc.gov/authorities/names/label/[label]
var authorBrowse = {
  onLoad: async function() {
    const localname = $('#auth_loc_localname').val();
    authorBrowse.init();
    
    if (authorBrowse.displayAnyExternalData) {
      try {
        const wdResults = await authorBrowse.getWikiData(localname);
        const parsedWikidata = authorBrowse.parseWikidataResults(wdResults);
        if (authorBrowse.hasWikiData(parsedWikidata)) {
          authorBrowse.renderWikidata(parsedWikidata);

          if (!authorBrowse.isPropertyExcluded('description')) {
            // If we have a wiki image or metadata, see if there's a dbpedia description
            const { wikiQid, wikiLabel } = authorBrowse.wikiQidAndLabel(parsedWikidata);
            const dbpediaResults = await authorBrowse.getDbpediaDescription(wikiQid, wikiLabel);
            authorBrowse.renderDbpediaDescription(dbpediaResults);
          }
        } else {
          authorBrowse.displayCatalogMetadata();
        }
      } catch(err) {
        console.log(err);
        authorBrowse.displayCatalogMetadata();
      }
    }
    else {
      authorBrowse.displayCatalogMetadata();
    }
    authorBrowse.bindEventHandlers();
  },
  
  init: function() {
    authorBrowse.exclusionsJSON = authorBrowse.getExclusions();
    authorBrowse.exclusionPropertiesHash = authorBrowse.createExclusionHash();
    //false if external data should not be displayed at all for this authority
    authorBrowse.displayAnyExternalData = authorBrowse.displayAuthExternalData();
    authorBrowse.wikidataConnector = WikidataConnector();
  },
  
  bindEventHandlers: function() {
      $('a[data-toggle="tab"]').click(function() {
          var clicked = this;
          $('li.nav-link').each(function() {
              $(this).removeClass('active');
          });
          $(clicked).parent('li').addClass('active'); 
      });
      
  },

  hasWikiData: function(data) {
    const wdProps = ['image', 'education', 'citizenship', 'pseudonyms'];
    return wdProps.some(k => k in data);
  },

  // Get image and metadata
  getWikiData: async function(localname) {
    const sparqlQuery = (
      `SELECT
        ?entity
        ?citizenship
        ?label
        ?description
        ${authorBrowse.wikidataConnector.imageSparqlSelect}
        (group_concat(DISTINCT ?educated_at; separator = ", ") as ?education)
        (group_concat(DISTINCT ?pseudos; separator = ", ") as ?pseudonyms)
      WHERE {
        ?entity wdt:P244 "${localname}".
        ?entity rdfs:label ?label. FILTER (langMatches( lang(?label), "EN" ) )
        OPTIONAL {
          ?entity wdt:P27 ?citizenshipRoot.
          ?citizenshipRoot rdfs:label ?citizenship. FILTER (langMatches( lang(?citizenship), "EN" ) )
        }
        OPTIONAL {
          ?entity wdt:P69 ?educationRoot.
          ?educationRoot rdfs:label ?educated_at. FILTER (langMatches( lang(?educated_at), "EN" ) )
        }
        OPTIONAL { ?entity wdt:P742 ?pseudos. }
        OPTIONAL { ?entity schema:description ?description. FILTER(lang(?description) = "en") }
        ${authorBrowse.wikidataConnector.imageSparqlWhere}
      } GROUP BY ?entity ?citizenship ?label ?description ${authorBrowse.wikidataConnector.imageSparqlSelect} LIMIT 1`
    );
    return authorBrowse.wikidataConnector.getData(sparqlQuery);
  },

  parseWikidataResults: function(data) {
    const output = {};
    const bindings = data?.results?.bindings;

    if (bindings && bindings.length) {
      // Parse everything and add to output
      // Then when rendering, check if it should be excluded
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
      if (authorBrowse.canRender('description', description?.value)) {
        output.description = description.value.charAt(0).toUpperCase() + description.value.slice(1) + '.';
      }
      if (authorBrowse.canRender('image', imageUrl?.value)) {
        const image = {
          url: imageUrl.value,
          license: imageLicense?.value,
          licenseShortName: imageLicenseShortName?.value,
          licenseUrl: imageLicenseUrl?.value,
          artist: imageArtist?.value,
          name: imageName?.value,
          title: imageTitle?.value
        };
        if (authorBrowse.wikidataConnector.isSupportedImage(image)) output.image = image;
      };
      if (authorBrowse.canRender('citizenship', citizenship?.value)) {
        output.citizenship = citizenship.value;
      }
      if (authorBrowse.canRender('education', education?.value)) {
        output.education = $.unique(education.value.split(', '));
      }

      // Remove any duplicate pseuds and primary name
      // Shouldn't really be dependent on dom, but wanted to retain previous render logic
      if (authorBrowse.canRender('pseudonyms', pseudonyms?.value) && $('.agent-notes').length === 0) {
        output.pseudonyms = $.unique(pseudonyms.value.split(', '));
        output.pseudonyms = output.pseudonyms.filter(pseud => pseud != label?.value);
      }

      if (entity?.value) output.entity = entity.value;
      if (label?.value) output.label = label.value;
    }

    return output;
  },

  wikiQidAndLabel: function(data) {
    return {
      wikiLabel: data.label,
      wikiQid: data.entity?.split("/")[4]
    }
  },

  renderWikidata: function(parsedWikidata) {
    const {
      citizenship, description, education, entity, image, pseudonyms
    } = parsedWikidata;

    if (description) {
      $('#dbp-comment').text(description);
      $('#dbp-comment').show();
    }
    if (image) {
      $("#agent-image").attr("src", image.url);
      $("#img-container").show();
      $("#wiki-image-acknowledge").html(`<br/>Image: ${authorBrowse.wikidataConnector.imageAttributionHtml(image)}`);
    } else {
      $("#comment-container").removeClass();
      $("#comment-container").addClass("col-sm-12").addClass("col-md-12").addClass("col-lg-12");
    }
    if (citizenship) {
      $("dd.citizenship").text(citizenship + "*");
      $(".citizenship").removeClass("citizenship");
    }
    if (education) {
      $("dd.education").text(education.join(", ") + "*");
      $(".education").removeClass("education");
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
          $("dl#itemDetails").append(the_html + "*");
        }
      }
    }

    $('#wiki-acknowledge').append(`* <a href="${entity}">From Wikidata<i class="fa fa-external-link" aria-hidden="true"></i></a>`);
    $('#info-details').removeClass('d-none');
    $('#has-wiki-ref-info').removeClass('d-none');
  },
    	
	// we can use the wikidata QID to get an entity description from DBpedia
	getDbpediaDescription: function(qid, label) {
	  var dbpediaUrl = "https://dbpedia.org/sparql";
    var sparqlQuery = " SELECT distinct ?uri ?comment WHERE {"
                        + " { SELECT (?e1) AS ?uri ?comment WHERE { ?e1 dbp:d '" + qid + "'@en . ?e1 rdfs:comment ?comment . "
                        + " ?e1 rdf:type dbo:Person . FILTER (langMatches(lang(?comment),\"en\")) } } UNION "
                        + " { SELECT (?e2) AS ?uri ?comment WHERE { ?e2 rdfs:label '" + label + "'@en . ?e2 rdfs:comment ?comment . "
                        + " ?e2 rdf:type dbo:Person . FILTER (langMatches(lang(?comment),\"en\"))} } UNION "
                        + " { SELECT (?e3) AS ?uri ?comment WHERE { ?e3 rdfs:label '" + label + "'@en . ?e3 rdfs:comment ?comment . "
                        + " ?e3 rdf:type yago:Person100007846 . FILTER (langMatches(lang(?comment),\"en\"))} }} ";
    var fullQuery = dbpediaUrl + "?query=" +  encodeURIComponent(sparqlQuery) + "&format=json";
    return $.ajax({
      url : fullQuery,
      headers : { Accept : 'application/sparql-results+json' },
      dataType: "jsonp",
      "jsonp": "callback",
    });
	},

  renderDbpediaDescription: function(data) {
    const bindings = data?.results?.bindings;
    if (bindings && bindings.length) {
      const { comment, uri } = bindings[0];
      if (authorBrowse.canRender('description', comment?.value)) {
        const dbpLink = uri?.value ? `<a href="${uri.value}">From DBPedia<i class="fa fa-external-link" aria-hidden="true"></i></a>` : 'From DBPedia';
        const dbpAcknowledgementHtml = `  <span class="ld-acknowledge">(${dbpLink}.)</span>`;
        $('#dbp-comment').text(comment.value);
        $('#dbp-comment').append(dbpAcknowledgementHtml);
      }
    }
  },
    
  // when there's no wikidata or an error occurs in one of the ajax calls
  displayCatalogMetadata: function() {
    $("#bio-desc").removeClass("d-none");
    $('#no-wiki-ref-info').removeClass("d-none");
  },
	
	//Method for reading exclusion information i.e whether Wikdiata/DbPedia info will be allowed for this heading
	getExclusions: function() {
		var exclusionsInput = $("#exclusions");
		if(exclusionsInput.length && exclusionsInput.val() != "") {
			var exclusionsJSON = JSON.parse(exclusionsInput.val());
			return exclusionsJSON;
		}
		return null;
	},
	//Is all external data not to be displayed for authority? If authority is present in the list and has no properties
	displayAuthExternalData: function() {
		var exclusionsJSON = authorBrowse.exclusionsJSON;
		//no exclusions, or exclusion = false, or exclusion is true but there are properties
		return (exclusionsJSON == null || $.isEmptyObject(exclusionsJSON) ||
			("exclusion" in exclusionsJSON && (exclusionsJSON["exclusion"] == false) ) ||
			("exclusion" in exclusionsJSON && exclusionsJSON["exclusion"] == true && "properties" in exclusionsJSON && exclusionsJSON["properties"].length)) ;
				
	},
	isPropertyExcluded: function(propertyName) {
		// if this property exists in our hash, then that means it is one of the properties the yaml 
        // file indicates should not be displayed
		return ("exclusionPropertiesHash" in authorBrowse && propertyName in authorBrowse.exclusionPropertiesHash);
	},
	//relies on both presence of value and ability to display this data
  canRender: function(propertyName, value) {
    return !!value && !authorBrowse.isPropertyExcluded(propertyName);
  },
	createExclusionHash: function() {
		var exclusionHash = {};
		if("properties" in authorBrowse.exclusionsJSON && authorBrowse.exclusionsJSON["properties"].length) {
			$.each(authorBrowse.exclusionsJSON.properties, function(i, v) {
				exclusionHash[v] = true;
			});
			
		}
		return exclusionHash;
	},
};

Blacklight.onLoad(function() {
  if ( $('body').prop('className').indexOf("browse-info") >= 0 && $("#auth_loc_localname").length ) {
    authorBrowse.onLoad();
  }
});