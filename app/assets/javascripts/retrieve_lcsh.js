class retrieveLCSH {
	constructor(uri) {
		this.uri = uri;
	}
	
	init() {
		this.loadLCResource();	
	}
	
	//Do a request to get the LC JSON for this URI
	loadLCResource() {
		var eThis  = this;
		var uri = this.uri;
		var url = uri.replace("http://","https://") + ".json";
    	//context:this may have made callback unavailable?
    	var lcshCall = $.ajax({
			"url": url,
			"type": "GET",
			"success" : function(data) {
				var dataHash = eThis.processLCSHJSON(data);
				eThis.getInfoAboutResource(dataHash, uri);
		 	}, 
		 	 "error": function(xhr, status, error) {
		      	//If LOC error occurs, then no additional requests are made to retrieve information
		      	console.log("Error occurred retrieving LOC info for " + uri);
      			console.log(xhr.status + ":" + xhr.statusText);
      		}	
		 });
	}
	
	//LC Call returns array of objects.  Generate a hash using the id 
	//to enable easier retrieval of information we want
	processLCSHJSON(jsonArray) {
	    var len = jsonArray.length;
	    var l;
	    var jsonObj;
	    var jsonHash = {};
	    for(l = 0; l < len; l++) {
	      jsonObj = jsonArray[l];
	      var id = jsonObj["@id"];
	      jsonHash[id] = jsonObj;
	    }
	    return jsonHash;
	}
	
	getInfoAboutResource(dataHash, uri) {
		var entity = dataHash[uri];
		var classificationProp = "http://www.loc.gov/mads/rdf/v1#classification";
		var rdfCodeProp = "http://www.loc.gov/mads/rdf/v1#code";
		var classificationValues = [];
		if(classificationProp in entity && entity[classificationProp].length > 0) {
			var classifications = entity[classificationProp];
			$.each(classifications, function(i, val) {
				//Two possibilities for classification values: array of objects with @value = classification string
				//OR array of objects, with @id pointing to another JSON object that has an rdf code property
				//which points to an array of objects where @value = classification string
				if("@value" in val) {
					classificationValues.push(val["@value"]);
				}
				if("@id" in val) { 
					var id = val["@id"];
					//This points to another JSON object
					if(id in dataHash) {
						var node = dataHash[id];
						if(rdfCodeProp in node && node[rdfCodeProp]. length > 0) {
							$.each(node[rdfCodeProp], function(j, v) {
								if("@value" in v) {
									classificationValues.push(v["@value"]);
								}
							});
						}
					}
				}
			});
		}
		if(classificationValues.length > 0) {
			this.displayClassificationValues(classificationValues);
		}
	}
	
	displayClassificationValues(classificationValues) {
		//Generate HTML links based on classification values
		var eThis = this;
		var linksArray = $.map(classificationValues, function(val, i) {
			//Check if there's a "-" which will specify a range
			if(val.indexOf("-") > -1) {
				var classificationRange = val.split("-");
				if(classificationRange.length == 2) {
					return eThis.generateCallNumberBrowseLink(classificationRange[0]) + " - " + eThis.generateCallNumberBrowseLink(classificationRange[1]);
				}
			} else {
				return eThis.generateCallNumberBrowseLink(val);
			}
		});
		if(linksArray.length > 0) {
			var displayHTML = "<div>Browse related items by call number:</div><div class='ml-4'>" + linksArray.join(", ") + "</div>";
			$("#callnumberbrowselink").html(displayHTML);
		}
	}
	
	//This may be a partial or full string
	generateCallNumberBrowseLink(classificationString) {
		var url = "/browse?authq=" + classificationString + "&start=0&browse_type=Call-Number";
		var html = "<a href='" + url + "'>" + classificationString + "</a>";
		return html;
	}
}

Blacklight.onLoad(function() {
	// Check for particular element and attribute with uri in order to retrieve classification information
    // Needs to be a value in the field.
	if ( $('#callnumberbrowselink').length && $('#callnumberbrowselink').attr("localname").length > 0 ) {
		var localname = $('#callnumberbrowselink').attr("localname");
		//Putting this logic back in
		var lcshURI = ( localname.substring(0, 2) == "sh" ) ? "http://id.loc.gov/authorities/subjects/" + localname : "http://id.loc.gov/authorities/names/" + localname;
		var rLCSH = new retrieveLCSH(lcshURI);
		rLCSH.init();		
	} 
}); 