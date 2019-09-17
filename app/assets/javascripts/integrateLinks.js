//Knowledge Panel JS code

$(document).ready(function () {
    $("body").tooltip({
        selector: '[data-toggle="tooltip"]'
    });
    
    $(this).on('click','*[data-auth]',
      function (event) {
        var e = $(this);
        //e.off('click');
        event.preventDefault();
        // var baseUrl = e.attr("base-url")
        var baseUrl = $("#itemDetails").attr("base-url");
        var auth = e.attr("data-auth");
        var headingType = e.attr("heading-type");
        auth = auth.replace(/,\s*$/, "");
        // Also periods
        auth = auth.replace(/\.\s*$/, "");
        var authType = e.attr("data-auth-type");
        var catalogAuthURL = e.attr("datasearch-poload");
        // Set up container
        var contentHtml = "<div id='popoverContent' class='kp-content'>" + 
        "<div id='authContent' style='float:none'><div style='float:left;clear:both' id='imageContent'></div></div>" + 
        "<div id='wikidataContent'></div><div id='digitalCollectionsContent'></div></div>";
        //,trigger : 'focus'
        e.popover({
          content : contentHtml,
          html : true,
          trigger: 'click'
        }).popover('show');
        // Get authority content
        $.get(catalogAuthURL, function (d) {
          $("#authContent").append(d);
        });
       queryLOC(auth, authType, headingType);
        // Add query to lookup digital collections
        searchDigitalCollections(baseUrl, getDigitalCollectionsQuery(auth, authType));
      });
  
  function queryLOC(auth, authType, headingType) {
    locPath = "names";
    rdfType = "PersonalName";
    // Even though LCSH has person names, querying /subjects for
    // names won't get you main resource
    // TODO: look into
    // id.loc.gov/authorities/names/label/[label]
    // for subject, LOC query will replace > with --
    // Digital collections will just use space for now
    var locQuery = auth;   
    if(authType == "subject") {
      if(headingType == "Geographic Name") {
        rdfType = "Geographic";
      }
      else if (headingType != "Personal Name") {
        locPath = "subjects";
        rdfType = "(Topic OR rdftype:ComplexSubject)";
      } 
      locQuery = locQuery.replace(/\s>\s/g, "--");
    }
    queryLOCSuggestions(locPath, locQuery, rdfType);
  }
  
  function getDigitalCollectionsQuery(auth, authType) {
    var digitalQuery = auth;
    if(authType == "subject") {    
        digitalQuery = digitalQuery.replace(/>/g, " ");
    }
    return digitalQuery;

  }
  
  function queryLOCSuggestions(locPath, locQuery, rdfType) {   
    var lookupURL = "http://id.loc.gov/authorities/" + locPath
    + "/suggest/?q=" + locQuery + "&rdftype=" + rdfType
    + "&count=1";
    $.ajax({
      url : lookupURL,
      dataType : 'jsonp',
      success : function (data) {
        urisArray = parseLOCSuggestions(data);
        if (urisArray && urisArray.length) {
          var locURI = urisArray[0]; 
          console.log("LOC URI from suggestions is " + locURI);
          queryWikidata(locURI);
        }
      }
    });
  }
  
  //Get entity using the label directly
  //If this approach, then could also potentially parse returned JSON for related Wikidata URI
  function retrieveLOCEntityByLabel() {
    
  }

  // Function to lookup digital collections
  function searchDigitalCollections(baseUrl, authString) {
    var lookupURL = baseUrl + "proxy/search?q=" + authString;
    $.ajax({
      url : lookupURL,
      dataType : 'json',
      success : function (data) {
        // Digital collection results, append
        var results = [];
        if ("response" in data && "docs" in data.response) {
          results = data["response"]["docs"];
          // iterate through array
          var resultsHtml = "<div><ul class=\"explist-digitalresults\">";
          var authorsHtml = "<div><ul class=\"explist-digitalcontributers\">";
          var maxLen = 10;
          var numberResults = results.length;
          var len = results.length;
          if (len > maxLen)
            len = maxLen;
          var l;
          for (l = 0; l < len; l++) {
            var result = results[l];
            var id = result["id"];
            var title = result["title_tesim"];
            var digitalURL = "http://digital.library.cornell.edu/catalog/"
              + id;
            resultsHtml += "<li>" + generateExternalLinks(digitalURL, title, "Digital Library Collections", "") + "</li>";
            var creator = [], creator_facet = [];
            if ("creator_tesim" in result)
              creator = result["creator_tesim"];
            if ("creator_facet_tesim" in result)
              creator_facet = result["creator_facet_tesim"];
            if (creator.length) {
              var c = creator.length;
              var i;
              for (i = 0; i < creator.length; i++) {
                authorsHtml += "<li> <a href='" + baseUrl
                + "catalog?q=" + creator[i]
                + "&search_field=all_fields'>" + creator[i]
                + "</a></li>";
              }
            }
          }

          resultsHtml += "</ul><button id=\"expnext-digitalresults\">&#x25BD; more</button><button id=\"expless-digitalresults\">&#x25B3; less</button></div>";
          var displayHtml = "";
          //Only display this section if there are any digital collection results
          if(numberResults > 0) {
            var digColSearchURL = "https://digital.library.cornell.edu/?q=" + authString + "&search_field=all_fields";
            displayHtml += "<div><h4>Digital Collections Results " + 
            "<a class='data-src' href='" + digColSearchURL + "' target='_blank'><img src='/assets/dc.png' /></a></h4>"          
            + resultsHtml
            + "<h4>Related Digital Collections Contributors</h4>"
            + authorsHtml
            + "</ul><button id=\"expnext-digitalcontributers\">&#x25BD; more</button><button id=\"expless-digitalcontributers\">&#x25B3; less</button></div>";
          }  

          $("#digitalCollectionsContent").append(displayHtml);
          listExpander('digitalresults');
          listExpander('digitalcontributers');
        }

      }
    });
  }

  // function to process results from LOC lookup

  function parseLOCSuggestions(suggestions) {
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

  // Query wikidata
  //TODO: make label optional
  function queryWikidata(LOCURI) {
    // Given loc uri, can you get matching wikidata entities
    var wikidataEndpoint = "https://query.wikidata.org/sparql?";
    var localname = getLocalName(LOCURI);
    var sparqlQuery = "SELECT ?entity ?entityLabel WHERE {?entity wdt:P244 \""
      + localname
      + "\" SERVICE wikibase:label { bd:serviceParam wikibase:language \"[AUTO_LANGUAGE],en\". }}";
    $.ajax({
      url : wikidataEndpoint,
      headers : {
        Accept : 'application/sparql-results+json'
      },
      data : {
        query : sparqlQuery
      },
      success : function (data) {
        // Data -> results -> bindings [0] ->
        // entity -> value
        var wikidataParsedData = parseWikidataSparqlResults(data);
        var wikidataURI = wikidataParsedData['uriValue'];
        var authorLabel = wikidataParsedData['authorLabel'];
        // Do a popover here with the wikidata uri and the loc uri
        // if no wikidata uri then will just show null
        // Currently hide label 
        // For now, we are linking to items with authority files so we should have the label
        // Second, the label seems to be undefined in some cases
       
        // Get notable results
        if (wikidataURI != null) {
          var contentHtml = "<section class=\"kp-flexrow\"><div><h3>Wikidata Info " + 
          "<a href='" + wikidataURI + "' target='_blank' class='data-src'><img src='/assets/wikidata.png' /></a>" + 
          "</h3></section>";
          $("#wikidataContent").append(contentHtml);
          getImage(wikidataURI);
          getNotableWorks(wikidataURI);
          getPeopleInfluencedBy(wikidataURI);
          getPeopleWhoInfluenced(wikidataURI);
        }

      }

    });

  }

  // function to parse sparql query results from wikidata, getting URI
  // and author name
  function parseWikidataSparqlResults(data) {
    output = {}
    if (data && "results" in data && "bindings" in data["results"]) {
      var bindings = data["results"]["bindings"];
      if (bindings.length) {
        var binding = bindings[0];
        if ("entity" in binding && "value" in binding["entity"]) {
          output.uriValue = binding["entity"]["value"];
        }
        if ("entityLabel" in binding
            && "value" in binding["entityLabel"]) {
          output.authorLabel = binding["entityLabel"]["value"];
        }
      }
    }
    return output;
  }

  // function to get localname from LOC URI
  function getLocalName(uri) {
    // Get string right after last slash if it's present
    // TODO: deal with hashes later
    return uri.split("/").pop();
  }

  // Wikidata notable works
  function getNotableWorks(wikidataURI) {
    var wikidataEndpoint = "https://query.wikidata.org/sparql?";
    var sparqlQuery = "SELECT ?notable_work ?title WHERE {<"
      + wikidataURI
      + "> wdt:P800 ?notable_work. ?notable_work wdt:P1476 ?title. ?notable_work wikibase:sitelinks ?linkcount . } ORDER BY DESC(?linkcount)";

    $.ajax({
      url : wikidataEndpoint,
      headers : {
        Accept : 'application/sparql-results+json'
      },
      data : {
        query : sparqlQuery
      },
      success : function (data) {
        if (data && "results" in data
            && "bindings" in data["results"]) {
          var bindings = data["results"]["bindings"];
          var bLength = bindings.length;
          var b;
          if (bindings.length) {
            var notableWorksHtml = "<div><h4>Notable Works</h4><ul class=\"explist-notable\"><li>";
            var notableHtmlArray = [];
            for (b = 0; b < bLength; b++) {
              var binding = bindings[b];
              if ("notable_work" in binding
                  && "value" in binding["notable_work"]
              && "title" in binding
              && "value" in binding["title"]) {
                var notableWorkURI = binding["notable_work"]["value"];
                var notableWorkLabel = binding["title"]["value"];
                console.log("uri and label for notable work "
                    + notableWorkURI + ":" + notableWorkLabel);
                notableHtmlArray.push(generateExternalLinks(notableWorkURI, notableWorkLabel, "Wikidata", ""));
              }
            }
            notableWorksHtml += notableHtmlArray.join("</li><li>")
            + "</li></ul><button id=\"expnext-notable\">&#x25BD; more</button><button id=\"expless-notable\">&#x25B3; less</button></div>";
            $("#wikidataContent").append(notableWorksHtml);
          }
        }
        listExpander('notable');
      }

    });
  }

  // Wikidata people who influenced the current author
  function getPeopleInfluencedBy(wikidataURI) {
    var wikidataEndpoint = "https://query.wikidata.org/sparql?";
    // var sparqlQuery = "SELECT ?influenceFor ?influenceForLabel WHERE
    // {?influenceFor wdt:P737 <" + wikidataURI + "> . SERVICE
    // wikibase:label { bd:serviceParam wikibase:language
    // \"[AUTO_LANGUAGE],en\". } } ORDER BY ASC(?influenceForLabel)";
    var sparqlQuery = "SELECT ?influenceFor ?locUri ?surname ?givenName ?surnameLabel ?givenNameLabel ( CONCAT(?surnameLabel, \", \" ,?givenNameLabel ) AS ?influenceForLabel ) WHERE { ?influenceFor wdt:P737 <"
      + wikidataURI
      + "> . ?influenceFor wdt:P734 ?surname . ?influenceFor wdt:P735 ?givenName . ?influenceFor wdt:P244 ?locUri . SERVICE wikibase:label { bd:serviceParam wikibase:language \"[AUTO_LANGUAGE],en\". }} ORDER BY ASC(?surnameLabel)"

      $.ajax({
        url : wikidataEndpoint,
        headers : {
          Accept : 'application/sparql-results+json'
        },
        data : {
          query : sparqlQuery
        },
        success : function (data) {
          if (data && "results" in data
              && "bindings" in data["results"]) {
            var bindings = data["results"]["bindings"];
            var bLength = bindings.length;
            var b;
            if (bindings.length) {
              var notableWorksHtml = "<div><h4>Was influence for</h4><ul class=\"explist-influencedby\"><li>";
              var notableHtmlArray = [];
              for (b = 0; b < bLength; b++) {
                var binding = bindings[b];
                if ("influenceFor" in binding
                    && "value" in binding["influenceFor"]
                && "influenceForLabel" in binding
                && "value" in binding["influenceForLabel"]) {
                  var iURI = binding["influenceFor"]["value"];
                  var iLabel = binding["influenceForLabel"]["value"];
                  var iLocUri = binding["locUri"]["value"] != undefined ? binding["locUri"]["value"] : "";
                  notableHtmlArray.push(generateExternalLinks(iURI, iLabel, "Wikidata", iLocUri));
                }
              }
              notableWorksHtml += notableHtmlArray.join("</li><li>")
              + "</li></ul><button id=\"expnext-influencedby\">&#x25BD; more</button><button id=\"expless-influencedby\">&#x25B3; less</button></div>";
              $("#wikidataContent").append(notableWorksHtml);
            }
          }
          listExpander('influencedby');
        }

      });
  }

  // Wikidata author influenced these people
  function getPeopleWhoInfluenced(wikidataURI) {
    var wikidataEndpoint = "https://query.wikidata.org/sparql?";
    // var sparqlQuery = "SELECT ?influencedBy ?influencedByLabel WHERE
    // {<" + wikidataURI + "> wdt:P737 ?influencedBy . SERVICE
    // wikibase:label { bd:serviceParam wikibase:language
    // \"[AUTO_LANGUAGE],en\". } } ORDER BY ASC(?influencedByLabel)";
    var sparqlQuery = "SELECT ?influencedBy ?locUri ?surname ?givenName ?surnameLabel ?givenNameLabel ( CONCAT(?surnameLabel, \", \" ,?givenNameLabel ) AS ?influencedByLabel ) WHERE { <"
      + wikidataURI
      + "> wdt:P737 ?influencedBy . ?influencedBy wdt:P734 ?surname . ?influencedBy wdt:P735 ?givenName . ?influencedBy wdt:P244 ?locUri . SERVICE wikibase:label { bd:serviceParam wikibase:language \"[AUTO_LANGUAGE],en\". }} ORDER BY ASC(?surnameLabel)"

      $.ajax({
        url : wikidataEndpoint,
        headers : {
          Accept : 'application/sparql-results+json'
        },
        data : {
          query : sparqlQuery
        },
        success : function (data) {
          if (data && "results" in data
              && "bindings" in data["results"]) {
            var bindings = data["results"]["bindings"];
            var bLength = bindings.length;
            var b;
            if (bindings.length) {
              var notableWorksHtml = "<div><h4>Was influenced by</h4><ul class=\"explist-whoinfluenced\"><li>";
              var notableHtmlArray = [];
              for (b = 0; b < bLength; b++) {
                var binding = bindings[b];
                if ("influencedBy" in binding
                    && "value" in binding["influencedBy"]
                && "influencedByLabel" in binding
                && "value" in binding["influencedByLabel"]) {
                  var iURI = binding["influencedBy"]["value"];
                  var iLabel = binding["influencedByLabel"]["value"];
                  var iLocUri = binding["locUri"]["value"] != undefined ? binding["locUri"]["value"] : "";
                  notableHtmlArray.push(generateExternalLinks(iURI, iLabel, "Wikidata", iLocUri));
                }
              }
              notableWorksHtml += notableHtmlArray.join("</li><li>")
              + "</li></ul><button id=\"expnext-whoinfluenced\">&#x25BD; more</button><button id=\"expless-whoinfluenced\">&#x25B3; less</button></div>";
              $("#wikidataContent").append(notableWorksHtml);
              //$('[data-toggle="tooltip"]').tooltip();
            }
          }
          listExpander('whoinfluenced');
        }

      });
  }

  // Get Image
  function getImage(wikidataURI) {
    var wikidataEndpoint = "https://query.wikidata.org/sparql?";
    var sparqlQuery = "SELECT ?image WHERE {<" + wikidataURI
    + "> wdt:P18 ?image . }";

    $.ajax({
      url : wikidataEndpoint,
      headers : {
        Accept : 'application/sparql-results+json'
      },
      data : {
        query : sparqlQuery
      },
      success : function (data) {
        if (data && "results" in data
            && "bindings" in data["results"]) {
          var bindings = data["results"]["bindings"];
          var bLength = bindings.length;
          var b;
          if (bindings.length) {
            var notableWorksHtml = "<img src=' ";
            var binding = bindings[0];
            if ("image" in binding && "value" in binding["image"] 
               && binding["image"]["value"]) {
              var image = binding["image"]["value"];
              var html = "<figure class='kp-entity-image'><img src='" + image + "'></figure>" + 
              "<span class='kp-source'>Image: Wikidata</span>";
              $("#imageContent").append(html);

            }
          }

        }
      }

    });
  }
  
  //Create both search link and outbound to entity link
  function generateExternalLinks(URI, label, sourceLabel, locUri) {
    var baseUrl = $("#itemDetails").attr("base-url");
    var keywordSearch = baseUrl + "catalog?q=" + label + "&search_field=all_fields";
    var title = "See " + sourceLabel;
    var image = "wikidata";
    var locHtml = "";
    if ( locUri.length > 0 ) {
        locHtml += "<a target='_blank' class='data-src' data-toggle='tooltip' data-placement='top' data-original-title='See Library of Congress' href='http://id.loc.gov/authorities/names/"
                    + locUri + ".html'><img src='/assets/loc.png' /></a>"
    }
    if ( sourceLabel.indexOf("Digital") > -1 ) {
        image = "dc";
    }
    return "<a data-toggle='tooltip' data-placement='top' data-original-title='Search Library Catalog' href='" 
            + keywordSearch + "'>" + label + "</a> " + "<a target='_blank' class='data-src' data-toggle='tooltip' data-placement='top' data-original-title='" 
            + title + "' href='" + URI + "'><img src='/assets/" + image +".png' /></a>" + locHtml
  }

});

//Workings of "show more" links on knowledge panel lists
function listExpander(domString) {
  var list = $(".explist-" + domString + " li");
  var numToShow = 10;
  var moreButton = $("#expnext-" + domString);
  var lessButton = $("#expless-" + domString);
  var numInList = list.length;
  list.hide();
  if (numInList > numToShow) {
    moreButton.show();
  }
  list.slice(0, numToShow).show();

  moreButton.click(function () {
    var showing = list.filter(':visible').length;
    list.slice(showing - 1, showing + numToShow).fadeIn();
    var nowShowing = list.filter(':visible').length;
    if (nowShowing >= numInList) {
      moreButton.hide();
    }
    lessButton.show();
  });
  lessButton.click(function () {
    var showing = list.filter(':visible').length;
    list.slice(numToShow, showing+1).fadeOut('fast');
    lessButton.hide();
    moreButton.show();
  });
};

//Close popover when clicking outside
//TODO: Native popover functionality should allow for closing when clicking on the X and when clicking outside
//How has this been overridden and how can we maintain it?
$(document).mouseup(function (e) {
  var container = $(".popover");
  if (!container.is(e.target) && container.has(e.target).length === 0) {
    container.popover("hide");
  }
});