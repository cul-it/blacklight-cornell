var processWikidata = {
  onLoad: function() {
      var workId = $('#work_id').val();
      if ( workId.length ) {
          processWikidata.getWikiLocalName(workId);
      }
      $.extend
  },

  getWikiLocalName: function(workId) {
    var wikidataEndpoint = "https://query.wikidata.org/sparql?";
    var sparqlQuery = "SELECT ?entity WHERE {?entity wdt:P5331 \"" + workId + "\"}";
    $.ajax({
      url : wikidataEndpoint,
      headers : {
        Accept : 'application/sparql-results+json'
      },
      data : {
        query : sparqlQuery
      },
      success : function(data) {
        if ( data['results']['bindings'].length ) {
            var URI = data['results']['bindings'][0]['entity']['value'];
            processWikidata.getWikiDerivatives(URI);
            processWikidata.getWikiEditions(URI);
            processWikidata.getNarrativeLocations(URI);
            processWikidata.getWikiLocId(URI); 
        }
      }
    });
  },

  getWikiEditions: function(wikiURI) {
      console.log(wikiURI);
    //var wikidataURI = "http://www.wikidata.org/entity/" + localName;
  var wikidataEndpoint = "https://query.wikidata.org/sparql?";
  var sparqlQuery = "SELECT ?notable_work ?notable_workLabel ?pub_date " 
                     + "WHERE {?notable_work wdt:P629 <" + wikiURI + "> .  "
                     + "SERVICE wikibase:label { bd:serviceParam wikibase:language \"[AUTO_LANGUAGE],en\". }"
                     + " ?notable_work wdt:P577 ?pub_date .}";
    console.log(sparqlQuery);
  $.ajax({
    url : wikidataEndpoint,
    headers : {
      Accept : 'application/sparql-results+json'
    },
    data : {
      query : sparqlQuery
    },
    success : function(data) {
    
      //console.log("Editions of works ");
      //console.log(data);
      if (data && "results" in data
          && "bindings" in data["results"]) {
        var bindings = data["results"]["bindings"];
        var bLength = bindings.length;
        var b;
        if (bindings.length) {
          var notableWorksOpeningHtml = "<div id='wiki-editions' class='availability panel panel-default'>"
                                          + "<div class='panel-heading'><h3 class='panel-title'>Notable Editions (Wikidata)</h3></div>"
                                          + "<div class='panel-body'>";
          var notableWorksClosingHtml = "</div></div></div>";
          var notableHtmlArray = [];
          var notableWorkURI = "";
          var notableWorkLabel = "";
          var notableWorkPubDate = ""
          for(b = 0; b < bLength; b++) {
            var binding = bindings[b];
            if ("notable_work" in binding
                && "value" in binding["notable_work"] 
                && "notable_workLabel" in binding 
                && "value" in binding["notable_workLabel"]) {
              notableWorkURI = binding["notable_work"]["value"];
              notableWorkLabel = binding["notable_workLabel"]["value"];
                if ("pub_date" in binding && "value" in binding["pub_date"] ) {
                                notableWorkPubDate = " (" + binding["pub_date"]["value"].substring(0, 4) + ")";
                            }
                //console.log("uri and label for edition work " + notableWorkURI + ": " + notableWorkLabel + notableWorkPubDate);
                notableHtmlArray.push("<div class='other-form'><span class='other-form-title'>" + notableWorkLabel + notableWorkPubDate 
                                        + "<a class='data-src' data-toggle='tooltip' data-placement='top' data-original-title='See Wikidata' href='" 
                                        + notableWorkURI + "'><img src='/assets/wikidata.png'></a></span>");
            }
          }
          notableWorksHtml = notableWorksOpeningHtml + notableHtmlArray.join("</div>") + notableWorksClosingHtml;
          // console.log(notableWorksHtml);
          $("#availability-panel").after(notableWorksHtml);
        }
      }
    }
    
  }); 
  },
  
  getWikiDerivatives: function(wikiURI) {
    var wikidataEndpoint = "https://query.wikidata.org/sparql?";
    var sparqlQuery = "Select ?derivative ?title ?instanceTypeLabel (group_concat(distinct ?pub_date; separator=',') as ?date) "
                      + " WHERE {<" + wikiURI + "> wdt:P4969 ?derivative. ?derivative wdt:P1476 ?title.  "
                      + "OPTIONAL {?derivative wdt:P31 ?instanceType .} OPTIONAL { ?derivative wdt:P577 ?pub_date . } "
                      + "SERVICE wikibase:label { bd:serviceParam wikibase:language \"[AUTO_LANGUAGE],en\". }}"
                      + "GROUP BY ?derivative ?title ?instanceTypeLabel";
    $.ajax({
      url : wikidataEndpoint,
      headers : {
        Accept : 'application/sparql-results+json'
      },
      data : {
        query : sparqlQuery
      },
      success : function(data) {
    
        //console.log("Derivative works ");
        //console.log(data);
        if (data && "results" in data
            && "bindings" in data["results"]) {
          var bindings = data["results"]["bindings"];
          var bLength = bindings.length;
          var b;
          if (bindings.length) {
          var derivativesOpeningHtml = "<div id='derivatives' class='availability panel panel-default'>"
                                          + "<div class='panel-heading'><h3 class='panel-title'>Derivative Works (Wikidata)</h3></div>"
                                          + "<div class='panel-body'>";
          var derivativesClosingHtml = "</div></div></div>";
          var derivativesHtmlArray = [];
          var derivativesURI = "";
          var derivativesLabel = "";
          var derivativesPubDate = ""
          var instanceTypeLabel = ""
            for(b = 0; b < bLength; b++) {
              var binding = bindings[b];
              if ("derivative" in binding
                  && "value" in binding["derivative"] 
                  && "title" in binding 
                  && "value" in binding["title"]
                    ) {
                derivativesURI = binding["derivative"]["value"];
                derivativesLabel = binding["title"]["value"];
                if ("instanceTypeLabel" in binding
                        && "value" in binding["instanceTypeLabel"]) {
                  instanceTypeLabel = binding["instanceTypeLabel"]["value"];
                }
                if ("date" in binding && "value" in binding["date"] ) {
                                derivativesPubDate = binding["date"]["value"].substring(0, 4);
                            }
              //  console.log("uri and label for derivative work " + derivativesURI + ": " + derivativesLabel);
                derivativesHtmlArray.push("<div class='other-form'><span class='other-form-title'>" + derivativesLabel + " (" + derivativesPubDate + " " + instanceTypeLabel  
                                        + ")<a class='data-src' data-toggle='tooltip' data-placement='top' data-original-title='See Wikidata' href='" + derivativesURI + "'><img src='/assets/wikidata.png'></a></span>");
              }
            }
          derivativesHtml = derivativesOpeningHtml + derivativesHtmlArray.join("</div>") + derivativesClosingHtml;
          // console.log(derivativesHtml);
          $("#availability-panel").after(derivativesHtml);
          }
        }
      }
    }); 
  },
  
  // gets the Library of Congress name authority URI for a work or person,
  getWikiLocId: function(wikiURI) {
    var wikidataEndpoint = "https://query.wikidata.org/sparql?";
    var sparqlQuery = "SELECT ?locID WHERE {<" + wikiURI + "> wdt:P244 ?locID . }";
    $.ajax({
      url : wikidataEndpoint,
      headers : {
        Accept : 'application/sparql-results+json'
      },
      data : {
        query : sparqlQuery
      },
      success : function(data) {
        if ( data && "results" in data && "bindings" in data["results"] ) {
        var bindings = data["results"]["bindings"];
      if ( "locID" in bindings[0] ) {         
            locId = bindings[0]["locID"]["value"];
            processWikidata.getLocData(locId);
          }
        }
      } 
    });
  },

  getLocData: function(locID) {
      var authorityUrl = "https://lookup.ld4l.org/authorities/show/linked_data/loc/names/" + locID;
      $.ajax({
        url : authorityUrl,
        type: 'GET',
      dataType: 'json',
      complete: function(xhr, status) {
          var results = $.parseJSON(xhr.responseText);
        if ( !jQuery.isEmptyObject(results) ) {
        var label = results["label"][0].replace(". ",". | ");
        // var format = $('input#format').val();
        var href = '/browse?utf8=%E2%9C%93&authq=' + label.replace(" ","+") + '&start=0&browse_type=Subject'
        var browseHtml = '<div style="margin-top:-25px;"><h3><a href="' + href + '">Browse related items by subject</a></h3></div>';
            $('div.browse-call-number').append("<h4>- or -</h4>");
            $('div.browse-call-number').after(browseHtml);
          }
      }
      });
  },
    
  getWikiEntity: function(uri) {
    var localName = uri.split("/").pop();
    $.ajax({
      url : "https://www.wikidata.org/wiki/Special:EntityData/" + localName + ".json",
      dataType : "json",
      complete: function(xhr, status) {
        var response = xhr.responseJSON['entities'];
        console.log("Wikidata = " + response.toSource());
      } 
    });
  },
  
  //Get narrative locations
  //Unlike the other properties, this information is appended directly to the item details list
 getNarrativeLocations: function (wikidataURI) {
    var wikidataEndpoint = "https://query.wikidata.org/sparql?";
    var sparqlQuery = "SELECT ?narrativeLocation ?narrativeLocationLabel ?locURI ?fastURI ?geonamesURI ?wlon ?slat ?elon ?nlat ?clon ?clat WHERE {<"
      + wikidataURI
      + "> wdt:P840 ?narrativeLocation. " 
      + "OPTIONAL {?narrativeLocation wdt:P244 ?locURI . }"
      + "OPTIONAL {?narrativeLocation wdt:P2163 ?fastURI . }" 
      + "OPTIONAL {?narrativeLocation wdt:P1566 ?geonamesURI . }"
      + "OPTIONAL {?narrativeLocation wdt:P625 ?coords . BIND(geof:longitude(?coords) AS ?clon) BIND(geof:latitude(?coords) AS ?clat) }"
      + "OPTIONAL {?narrativeLocation wdt:P1335 ?w ; wdt:P1333 ?s; wdt:P1334 ?e; wdt:P1332 ?n . BIND( geof:longitude(?w) AS ?wlon) BIND(geof:latitude(?s) AS ?slat) BIND(geof:longitude(?e) AS ?elon) BIND(geof:latitude(?n) AS ?nlat)}"
      + "SERVICE wikibase:label { bd:serviceParam wikibase:language \"[AUTO_LANGUAGE],en\". } } ORDER BY ?narrativeLocationLabel";
    var fieldName = "Narrative Locations";
    var fieldValue = [];
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
            for (b = 0; b < bLength; b++) {
              var binding = bindings[b];
              if("narrativeLocation" in binding && "narrativeLocationLabel" in binding 
                  && "value" in binding["narrativeLocation"] && "value" in binding["narrativeLocationLabel"]) {
                var narrativeLocation = binding["narrativeLocation"]["value"];
                var narrativeLocationLabel = binding["narrativeLocationLabel"]["value"];
                if("fastURI" in binding && "value" in binding["fastURI"]) {
                  var fastURI = binding["fastURI"]["value"];
                  var geoInfo = processNarrativeLocation.generateCoordinateInfo(binding);
                  var geoInfoAttr = "";
                  if("bbox" in geoInfo) {
                    geoInfoAttr = " bbox='" + geoInfo["bbox"] + "' ";
                  }
                  if("Point" in geoInfo) {
                    geoInfoAttr += " lat='" + geoInfo["Point"]["lat"] + "' lon='" + geoInfo["Point"]["lon"] + "' ";
                  }
                  
                  narrativeLocationLabel = "<span  id='geo" + fastURI + "'>" + narrativeLocationLabel + "</span>" + 
                  "<a href='#' role='button' data-map='map' " + geoInfoAttr + " id='info' class='info-button hidden-xs' label='" + narrativeLocationLabel + "' fastURI='" + fastURI + "'><span class='badge badge-primary'>i</span></a>";
                }
                fieldValue.push(narrativeLocationLabel);
              }
            }
            $("#itemDetails").append(processWikidata.generateItemViewRow(fieldName, fieldValue.join("<br/>"), wikidataURI));
            processNarrativeLocation.init();
            renderWikidataLegend(wikidataURI);
          }
        }
   
      }
    });
  },
  
  generateItemViewRow: function(fieldName, fieldValue, wikidataURI) {
    var fieldNameId = fieldName.replace(/\s/g, '');
    return  "<dt class='blacklight-" + fieldNameId + "'><span  class='wikidata-bgc'>" + fieldName + ":</span></dt>"
    + "<dd class='blacklight-" + fieldNameId + "'>" + fieldValue + "</dd>";
    
  },
  
  retrieveFASTString: function(fastURI) {
    //An AJAX request that 
  }
  
};  
Blacklight.onLoad(function() {
  if ( $('body').prop('className').indexOf("catalog-show") >= 0 ) {
    processWikidata.onLoad();
  }
});  