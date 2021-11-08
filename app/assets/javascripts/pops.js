//Represents individual knowledge panel
class kPanel {
  //Initialize with string heading
  //Can be extended to include URI
  constructor() {
  	this.imageSize = 100;
   
  } 
   
  //initialize function
  init() {
  	this.bindEventListeners();
  }
  
  bindEventListeners() {
    var eThis = this;
  	$('*[data-poload]').click(function(event) {
  		event.preventDefault();
  		var e=$(this);
  		//e.off('click');
		var auth = e.attr("data-auth");
		var fullRecordLink = e.data("poload");	  
		//only for authors
		var authType = "author";
		var catalogAuthURL = "/panel?type=" + authType + "&authq=\"" + auth + "\"";   
		
	    $.get(catalogAuthURL,function(d) {
	    	var displayHTML= $(d).find("div#kpanelContent").html();
	    	//Change trigger to focus for prod- click for debugging
	       e.popover({content: displayHTML, html:true, trigger:'focus'}).popover('show');
	       //Can drop additional info type parameter if author page defaults to that view
           $("#fullRecordLink").attr("href",fullRecordLink);
           //Now get additional data
           eThis.getAdditionalData(auth);
	    });
	});
	//Popover div won't exist until user clicks and displays
	//Mousedown will close popover before allowing link to be clicked
	//This prevents the default behavior within the popover itself and allows link to be clicked
	//Based on https://stackoverflow.com/questions/20299246/bootstrap-popover-how-add-link-in-text-popover
	$('body').on('mousedown', '.popover', function(e) {
    	e.preventDefault();
  	});
  	
  }
  
  //Get other data from LOC and Wikidata
  getAdditionalData(auth) {
    var locPath = "names";
    var rdfType = "PersonalName";  
	var locQuery = this.processAuthName(auth);
	//Incorporate when so loc suggestion and auth check occur together
	//and then wikidata is queried only if info can be displayed
	this.queryLOCSuggestions(locPath, locQuery, rdfType);	
  }
  
  //Remove any extra periods or commas when looking up LOC
  processAuthName(auth) {
  	 var returnAuth = auth.replace(/,\s*$/, "");
     // Also periods
     returnAuth = returnAuth.replace(/\.\s*$/, "");
     return returnAuth;
  }
  
  //Lookup suggestions in LOC for this name specifically
  queryLOCSuggestions(locPath, locQuery, rdfType) {   
    var lookupURL = "http://id.loc.gov/authorities/" + locPath
    + "/suggest?q=" + locQuery + "&rdftype=" + rdfType
    + "&count=1";
    var eThis = this;
    
    //Using timeout to handle query that doesn't return in 3 seconds for jsonp request
    $.ajax({
      url : lookupURL,
      dataType : 'jsonp',
      timeout: 3000,
      crossDomain: true,
      success : function (data) {
        var urisArray = eThis.parseLOCSuggestions(data);
        if (urisArray && urisArray.length > 0) {
          var locURI = urisArray[0]; 
          eThis.queryWikidata(locURI);
        }
      },
      error: function(xhr, status, error) {
      	//If LOC error occurs, then no additional requests are made to retrieve information
      	console.log("Error occurred retrieving LOC suggestion for " + locQuery);
      	console.log(xhr.status + ":" + xhr.statusText + ":" + xhr.responseText);
      }
    });
  }
  
  parseLOCSuggestions(suggestions) {
    var urisArray = [];
    if (suggestions && suggestions[1] !== undefined) {
      for (var s = 0; s < suggestions[1].length; s++) {
        // var l = suggestions[1][s];
        var u = suggestions[3][s];
        urisArray.push(u);
      }
    }
    return urisArray;
  }
  
  //given an LOC URI, query if equivalent wikidata entity exists and get image and/or description
	queryWikidata(locURI) {
		var wikidataEndpoint = "https://query.wikidata.org/sparql?";
		var localname = this.getLocalName(locURI);
		var sparqlQuery = this.getWikidataQuery(locURI, localname);
		var eThis = this;
		 $.ajax({
		    url : wikidataEndpoint,
		    headers : {
		      Accept : 'application/sparql-results+json'
		    },
		    data : {
		      query : sparqlQuery
		    },
		    context:this,
		    success : function (data) {
		      var wikidataParsedData = eThis.parseWikidataSparqlResults(data);
		      eThis.processWikidataInfo(wikidataParsedData);
		    },
		    error: function(xhr, status, error) {
		     	//If Wikidata  error occurs, then no information will be displayed
		     	console.log("Error occurred retrieving Wikidata info for " + locURI);
		     	console.log(xhr.status + ":" + xhr.statusText + ":" + xhr.responseText);
		 	}		
		  });	 	
	}
	
	getWikidataQuery(locURI, localname) {
		//if(this.isPropertyForURIAllowed(locURI, "image")) {
			return "SELECT ?entity ?image ?description WHERE " + 
	  			"{?entity wdt:P244 \"" + localname + "\". " +
	  			"OPTIONAL {?entity wdt:P18 ?image . }" + 
	  			"OPTIONAL {?entity schema:description ?description . FILTER(lang(?description) = \"en\")}}";
		//}
		/*
		return "SELECT ?entity ?description WHERE " + 
	  		"{?entity wdt:P244 \"" + localname + "\". " +
	  		"OPTIONAL {?entity schema:description ?description . FILTER(lang(?description) = \"en\")}}";; */S
	}
   
	parseWikidataSparqlResults(data) {
	   var output = {};
	   if (data && "results" in data && "bindings" in data["results"]) {
	     var bindings = data["results"]["bindings"];
	     if (bindings.length) {
	       var binding = bindings[0];
	       if ("entity" in binding && "value" in binding["entity"]) {
	         output.uriValue = binding["entity"]["value"];
	       }
	       if ("image" in binding && "value" in binding["image"]
	       && binding["image"]["value"]) {
	         output.image = binding["image"]["value"];
	       }
	       if ("description" in binding && "value" in binding["description"]
	       && binding["description"]["value"]) {
	         output.description = binding["description"]["value"];
	       }
	     }
	   }
	   return output;
	 }
	 
	 processWikidataInfo(wikidataParsedData) {
         if("image" in wikidataParsedData) {
         	//Check if file type ends with jpg or gif or png
         	var image = wikidataParsedData["image"];
            var uri = wikidataParsedData["uriValue"];
         	if(this.isSupportedImageType(image)) {
         		//Requesting smaller size image
         		image += "?width=" + this.imageSize;
	         	//Check filename to ensure that w are
	         	var html = "<figure class='kp-entity-image float-left'><img src='" + image + "'><br>"
                html += "<span class='kp-source'>Image: <a href='" + uri + "' target='_blank'>Wikidata</a></span></figure>";
	            $("#imageContent").html(html);
            }         	
         }
         
         if("description" in wikidataParsedData) {
         	//Check if file type ends with jpg or gif or png
         	var description = wikidataParsedData["description"];
            $("#wikidataDescription").html(description);
         }

         $('#time-indicator').hide();         
         $('#popoverContent').removeClass("d-none");
	 }
	   
     // function to get localname from LOC URI
	getLocalName(uri) {
	    // Get string right after last slash if it's present
	    // TODO: deal with hashes later
	    return uri.split("/").pop();
  	}
  	
	//Check image type supported
	isSupportedImageType(image) {
		//Supported html display types = jpg, jpeg, gift, png, svg
		//Wikidata query may return other types.  Not displaying currently
		var fileExtension = image.substr( (image.lastIndexOf('.') +1) ).toLowerCase();
		return (fileExtension == "jpg" || fileExtension == "jpeg" || fileExtension == "gif" || fileExtension == "png" || fileExtension == "svg");
	}
}

Blacklight.onLoad(function() {
	//Only load this code when the popup is available
	//Currently, only one primary author for each item view page
	//This can be extended to include separate code if multiple knowledge panels are possible
	if ( $('*[data-auth]').length ) {
		var headingElement =  $('*[data-auth]');
	  	var kPanelObj = new kPanel();
	  	kPanelObj.init();
	} 
}); 


