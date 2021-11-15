var hasWikiImage = false;
var wikiDescription;
var subjectBrowse = {
  onLoad: function() {
    this.bindCrossRefsToggle();  
  },
  
  bindCrossRefsToggle: function() {
    $("#cr-refs-toggle").click(function() {
      if ( $(".toggled-cr-refs").first().is(":visible") ) {
          $(".toggled-cr-refs").hide();
          $("#cr-refs-toggle").html("more &raquo;");
      }
      else {
          $(".toggled-cr-refs").show();
          $("#cr-refs-toggle").html("&laquo; less");
      }
      return false;
    });
  },
};
var subjectDataBrowse = {
    onLoad: function() {
      var localname = $("#subj_loc_localname").val();
      // console.log("local name = " + localname);
      subjectDataBrowse.init();
     
      if (subjectDataBrowse.displayAnyExternalData) {
        if ( localname.length > 0 ) {
            this.getWikiImage(localname);
        }
        else {
            this.getDbpediaDescription("x", $("h2").text().replaceAll(">","").trim());
        }
      }
      else {
          $('#bio-desc').removeClass("d-none");
          $('#no-wiki-ref-info').removeClass("d-none");
      }
  },
    
  init: function() {
  	subjectDataBrowse.exclusionsJSON = subjectDataBrowse.getExclusions();
  	subjectDataBrowse.exclusionPropertiesHash = subjectDataBrowse.createExclusionHash();
  	//false if external data should not be displayed at all for this authority
  	subjectDataBrowse.displayAnyExternalData = subjectDataBrowse.displayAuthExternalData();
  },
  
  // Get Image country = P17; territory P131; location P276
  getWikiImage: function(localname) {
    var wikidataEndpoint = "https://query.wikidata.org/sparql";
    var sparqlQuery = "SELECT ?entity ?image ?label ?description "
                  + " WHERE { ?entity wdt:P244 '" + localname + "' . "
                  + " ?entity rdfs:label ?label . FILTER (langMatches( lang(?label), \"EN\" ) ) "
                  + " OPTIONAL {?entity wdt:P18 ?image . }"
                  + " OPTIONAL {?entity schema:description ?description . FILTER(lang(?description) = \"en\")}"
                  + " } LIMIT 1";
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
            if ( bindings['length'] > 0 ) {
              var binding = bindings[0];
              if ( subjectDataBrowse.displayProperty("image", binding) ) {
                imageUrl = bindings[0]["image"]["value"];
                if ( subjectDataBrowse.isSupportedImageType(imageUrl) ) {
                  hasWikiImage = true;
                  $("#subject-image").attr("src",imageUrl);
                  $("#img-container").show();
                }
              }
  		      if ( bindings[0]["description"] != undefined ) {
                var tempString = bindings[0]["description"]["value"]
  		        wikiDescription = tempString.charAt(0).toUpperCase() + tempString.slice(1) + ".";
  		      }
  		      if ( bindings[0]["label"] != undefined ) {
  		        label = bindings[0]["label"]["value"]
  			    // get the QID so we can use DBpedia to get a decent description
  			    var qid = bindings[0]['entity']['value'].split("/")[4];
                subjectDataBrowse.getDbpediaDescription(qid, label);
  		      }
            }
            else {
                subjectDataBrowse.getDbpediaDescription("x", $("h2").text().replaceAll(">","").trim());
            }
          }
      }
    });
  },
  
  // we can use the wikidata QID to get an entity description from DBpedia
  getDbpediaDescription: function(qid, label) {
      // console.log("QID: " + qid);
      // console.log("label: " + label);
      var dbpediaUrl = "https://dbpedia.org/sparql";
      var sparqlQuery = " SELECT distinct ?uri ?comment WHERE {"
                        + " { SELECT (?e1) AS ?uri ?comment WHERE { ?e1 dbp:d '" + qid + "'@en . ?e1 rdfs:comment ?comment . FILTER (langMatches(lang(?comment),\"en\")) }} UNION "
                        + " { SELECT (?e2) AS ?uri ?comment WHERE { ?e2 rdfs:label '" + label + "'@en . ?e2 rdfs:comment ?comment . FILTER (langMatches(lang(?comment),\"en\"))}}} "
      var fullQuery = dbpediaUrl + "?query=" +  escape(sparqlQuery) + "&format=json";
      $.ajax({
        url : fullQuery,
        headers : {
          Accept : 'application/sparql-results+json'
        },
        dataType: "jsonp",
        "jsonp": "callback",
        success : function (data) {
          if ( data && "results" in data && "bindings" in data["results"] ) {
            var bindings = data["results"]["bindings"];
  	        var comment = "";
            var dbpLink = "<span class='ld-acknowledge'>(From DBPedia.)</span>";
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
                if ( !subjectDataBrowse.isPropertyExcluded("description") ) {
  			      $('#dbp-comment').text(comment);
                  $('#dbp-comment').append(dbpLink);
                  $('#info-details').removeClass("d-none");
  			      $('#dbp-comment').show();
                  $('#has-wiki-ref-info').removeClass("d-none");
                }
                else {
                    $('#bio-desc').removeClass("d-none");
                    $('#no-wiki-ref-info').removeClass("d-none");
                }
  	  	      }
  	        }
            else if ( hasWikiImage ) {
                $('#info-details').removeClass("d-none");
                if ( !subjectDataBrowse.isPropertyExcluded("description") ) {
                    $('#dbp-comment').text(wikiDescription);
                    $('#dbp-comment').show();
                }
                $('#has-wiki-ref-info').removeClass("d-none");
            }
            else {
                $('#bio-desc').removeClass("d-none");
                $('#no-wiki-ref-info').removeClass("d-none");
            }
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
	var exclusionsJSON = subjectDataBrowse.exclusionsJSON;
	//no exclusions, or exclusion = false, or exclusion is true but there are properties
	return (exclusionsJSON == null || $.isEmptyObject(exclusionsJSON) ||
		("exclusion" in exclusionsJSON && (exclusionsJSON["exclusion"] == false) ) ||
		("exclusion" in exclusionsJSON && exclusionsJSON["exclusion"] == true && "properties" in exclusionsJSON && exclusionsJSON["properties"].length)) ;
			
  },
  isPropertyExcluded: function(propertyName) {
	// if this property exists in our hash, then that means it is one of the properties the yaml 
      // file indicates should not be displayed
	return ("exclusionPropertiesHash" in subjectDataBrowse && propertyName in subjectDataBrowse.exclusionPropertiesHash);
  },
  //relies on both presence of value and ability to display this data
  displayProperty: function(propertyName, binding) {
	if(subjectDataBrowse.isPropertyExcluded(propertyName)) {
		return false;
	}
	return (binding[propertyName] != undefined && binding[propertyName]["value"].length > 0);
  },
  createExclusionHash: function() {
	var exclusionHash = {};
	if("properties" in subjectDataBrowse.exclusionsJSON && subjectDataBrowse.exclusionsJSON["properties"].length) {
		$.each(subjectDataBrowse.exclusionsJSON.properties, function(i, v) {
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
    if ( $('body').prop('className').indexOf("browse-info") >= 0 ) {
        subjectBrowse.onLoad();  
    }
    if ( $("#subj_loc_localname").length ) {
        subjectDataBrowse.onLoad();
    }
});  
