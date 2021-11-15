// https://id.loc.gov/authorities/names/suggest/?q=Twain,+Mark,+1835-1910
// id.loc.gov/authorities/names/label/[label]
var hasWikiImage = false;
var showWikiAcknowledge = false;
var wikiDescription;
var authorBrowse = {
    onLoad: function() {
      var localname = $("#auth_loc_localname").val();
      authorBrowse.init();
     
      if ( authorBrowse.displayAnyExternalData ) {
      	authorBrowse.getWikiImage(localname);
      }
      else {
          $('#bio-desc').removeClass("d-none");
          $('#no-wiki-ref-info').removeClass("d-none");
      }
      authorBrowse.bindEventHandlers();
    },
    
    init: function() {
    	authorBrowse.exclusionsJSON = authorBrowse.getExclusions();
    	authorBrowse.exclusionPropertiesHash = authorBrowse.createExclusionHash();
    	//false if external data should not be displayed at all for this authority
    	authorBrowse.displayAnyExternalData = authorBrowse.displayAuthExternalData();
    },
    
    bindEventHandlers: function() {
        $('a[data-toggle="tab"]').click(function() {
            //console.log("clicked: " + $(this).attr("id"));
            var clicked = this;
            $('li.nav-link').each(function() {
                $(this).removeClass('active');
            });
            $(clicked).parent('li').addClass('active'); 
        });
        
    },

    // Get Image
    getWikiImage: function(localname) {
      // console.log("LOC local name = " + localname);
      var wikidataEndpoint = "https://query.wikidata.org/sparql";
      var sparqlQuery = "SELECT ?entity ?image ?citizenship ?label ?description (group_concat(DISTINCT ?educated_at; separator = \", \") as ?education) (group_concat(DISTINCT ?pseudos; separator = \", \") as ?pseudonyms) "
                  + " WHERE { ?entity wdt:P244 '" + localname + "' . ?entity rdfs:label ?label . FILTER (langMatches( lang(?label), \"EN\" ) ) "
                  + " OPTIONAL {?entity wdt:P18 ?image . ?entity wdt:P27 ?citizenshipRoot . ?citizenshipRoot rdfs:label ?citizenship . FILTER (langMatches( lang(?citizenship), \"EN\" ) ) }"
                  + " OPTIONAL {?entity wdt:P69 ?educationRoot . ?educationRoot rdfs:label ?educated_at . FILTER (langMatches( lang(?educated_at), \"EN\" ) ) }"
                  + " OPTIONAL {?entity wdt:P69 ?educationRoot . ?educationRoot rdfs:label ?educated_at . FILTER (langMatches( lang(?educated_at), \"EN\" ) ) }"
                  + " OPTIONAL {?entity wdt:P742 ?pseudos . }"
                  + " OPTIONAL {?entity schema:description ?description . FILTER(lang(?description) = \"en\")}"
                  + " } GROUP BY ?entity ?image ?citizenship ?label?description  LIMIT 1";
      $.ajax({
        url : wikidataEndpoint,
        headers : {
          Accept : 'application/sparql-results+json'
        },
        data : {
          query : sparqlQuery
        },
        success : function (data) {
            if ( data && "results" in data && "bindings" in data["results"] ) {
              var bindings = data["results"]["bindings"];
  		      var label = "";
              var wikiAcknowledge = "";
              if ( bindings['length'] > 0 ) {
                var binding = bindings[0];
    		    if ( authorBrowse.displayProperty("description", binding) ) {
                    var tempString = bindings[0]["description"]["value"]
      		        wikiDescription = tempString.charAt(0).toUpperCase() + tempString.slice(1) + ".";
    		    }
  			    if ( bindings[0]["label"] != undefined ) {
  			      label = bindings[0]["label"]["value"]
  				  // get the QID so we can use DBpedia to get a decent description
  				  var qid = bindings[0]['entity']['value'].split("/")[4];
  				  // console.log("QID: " + qid);
                  wikiAcknowledge = "  <span class='ld-acknowledge'>* <a href='" + bindings[0]['entity']['value'] + "' target='_blank'>From Wikidata <i class='fa fa-external-link'></i></a></span>"
  				  //Display if description allowed
                  authorBrowse.getDbpediaDescription(qid, label);
  			    }
                if (authorBrowse.displayProperty("image", binding)) {       
                  imageUrl = bindings[0]["image"]["value"];
                  if ( authorBrowse.isSupportedImageType(imageUrl) ) {
                    hasWikiImage = true;
                    $("#agent-image").attr("src",imageUrl);
                    $("#img-container").show();
                  }
                }
                if ( authorBrowse.displayProperty("citizenship", binding) ) {
                  citizenship = bindings[0]["citizenship"]["value"];
                  $("dd.citizenship").text(citizenship + "*");
                  $(".citizenship").removeClass("citizenship");
                  showWikiAcknowledge = true;
                }
                if ( authorBrowse.displayProperty("education", binding) ) {
                  education = bindings[0]["education"]["value"];
                  var tmpArray = $.unique(education.split(', '));
                  $("dd.education").text(tmpArray.join(", ") + "*");
                  $(".education").removeClass("education");
                  showWikiAcknowledge = true;
                }
                if ( authorBrowse.displayProperty("pseudonyms", binding) ) {
                  if ( $('.agent-notes').length == 0 ) {
                    the_html = '<dt class="col-sm-4">Notes:</dt><dd class="col-sm-8">For works of this author written under other names, search also under: <ul class="agent-notes">';
                    pseudonyms = bindings[0]["pseudonyms"]["value"];
                    var tmpArray = $.unique(pseudonyms.split(', '));
                    $.each(tmpArray, function(k,v) {
  				      if ( v != label ) {
                        the_html += '<li>' + v + '</li>';
  				      }
                    });
                    the_html += '</ul></dd>';
  				    if ( the_html.indexOf('<li>') > 0 ) {
                      $("dl#itemDetails").append(the_html + "*");
  			        }
                    showWikiAcknowledge = true;
                  }
                }
                if ( showWikiAcknowledge ) {
                  $("div#wiki-acknowledge").append(wikiAcknowledge);
                  if ( !hasWikiImage ) {
                      $("#comment-container").removeClass();
                      $("#comment-container").addClass("col-sm-12").addClass("col-md-12").addClass("col-lg-12");
                  }
                }
              }
              if ( !hasWikiImage && !showWikiAcknowledge ) {
                  $("#bio-desc").removeClass("d-none");
                  $('#no-wiki-ref-info').removeClass("d-none")
              }
            }
        }
      });
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
                        + " ?e3 rdf:type yago:Person100007846 . FILTER (langMatches(lang(?comment),\"en\"))} }} "
      var fullQuery = dbpediaUrl + "?query=" +  escape(sparqlQuery) + "&format=json";
      $.ajax({
        url : fullQuery,
        headers : {
          Accept : 'application/sparql-results+json'
        },
        dataType: "jsonp",
        "jsonp": "callback",
        success : function (data) {
		  var comment = "";
          if ( data && "results" in data && "bindings" in data["results"] ) {
            var bindings = data["results"]["bindings"];
            var dbpLink = "<span class='ls-acknowledge'>(From DBPedia.)</span>";
            if ( bindings['length'] > 0 ) {
  		  	  if ( bindings[0]["uri"] != undefined ) {
  		  	    uri = bindings[0]["uri"]["value"]
  				dbpLink = "  <span class='ld-acknowledge'>(<a href='" + uri + "' target='_blank'>From DBPedia <i class='fa fa-external-link'></i></a>.)</span>"
  		  	  }
		  	  if ( bindings[0]["comment"] != undefined ) {
		  	    comment = bindings[0]["comment"]["value"]
                  if ( !hasWikiImage ) {
                      $("#comment-container").removeClass();
                      $("#comment-container").addClass("col-sm-12").addClass("col-md-12").addClass("col-lg-12");
                  }
  				  if ( !authorBrowse.isPropertyExcluded("description") ) {
				    $('#dbp-comment').text(comment);
                    $('#dbp-comment').append(dbpLink);
                    $('#dbp-comment').show();
                  }
		  	  }
		    }
          }
          // clean up this logic
          if ( showWikiAcknowledge || comment.length > 0 ) {
              if ( comment.length > 0 ) {
                  $("#bio-desc").addClass("d-none");
                  $('#no-wiki-ref-info').addClass("d-none")                  
              }
              else if ( !subjectDataBrowse.isPropertyExcluded("description") ) {
                $('#dbp-comment').text(wikiDescription);
                $('#dbp-comment').show();
              }
              $('#info-details').removeClass("d-none");
              $('#has-wiki-ref-info').removeClass("d-none");
          }
        },
        error : function() {
            $("#bio-desc").removeClass("d-none");
            $('#no-wiki-ref-info').removeClass("d-none")                  
        }
      });	
	},
	
	//Method for reading exclusion information i.e whether Wikdiata/DbPedia info will be allowed for this heading
	getExclusions: function() {
		var exclusionsInput = $("#exclusions");
		if(exclusionsInput.length && exclusionsInput.val() != "") {
			// console.log(exclusionsInput.val());
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
	displayProperty: function(propertyName, binding) {
		if(authorBrowse.isPropertyExcluded(propertyName)) {
			return false;
		}
		return (binding[propertyName] != undefined && binding[propertyName]["value"].length > 0);
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
	//Check image type supported
	isSupportedImageType(image) {
		//Supported html display types = jpg, jpeg, gift, png, svg
		//Wikidata query may return other types.  Not displaying currently
		var fileExtension = image.substr( (image.lastIndexOf('.') +1) ).toLowerCase();
		return (fileExtension == "jpg" || fileExtension == "jpeg" || fileExtension == "gif" || fileExtension == "png" || fileExtension == "svg");
	}
    
};

Blacklight.onLoad(function() {
  if ( $('body').prop('className').indexOf("browse-info") >= 0 && $("#auth_loc_localname").length ) {
    authorBrowse.onLoad();
  }
});