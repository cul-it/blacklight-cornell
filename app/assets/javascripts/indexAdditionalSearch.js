//Integrate digital collections faceted and/or keyword search in index view

$(document).ready(function () {
  var searchDiv = $("#digital-collections-search");
  if(searchDiv.length) {
    var facetName = searchDiv.attr("facet-name");
    var facetValue = searchDiv.attr("facet-value");
    var baseUrl = searchDiv.attr("base-url");
    searchDigitalCollectionFacet(facetName, facetValue, baseUrl);
  }
});

function searchDigitalCollectionFacet(facetName, facetValue, baseUrl) {
  //Facet value is a json array so need to get first value out
  var facetValues = JSON.parse(facetValue);
  var dcFacetName = (facetName === "fast_topic_facet") ?  "subject_tesim": facetName;
  var thumbnailImageProp = "media_URL_size_0_tesim";
  if(facetValues.length) {
    var dcFacetValue = facetValues[0];
    var lookupURL = baseUrl + "proxy/facet?facet_field=" + dcFacetName + "&facet_value=" + dcFacetValue;
    $.ajax({
      url : lookupURL,
      dataType : 'json',
      success : function (data) {
        // Digital collection results, append
        var results = [];
        var resultsHtml = "";
        if ("response" in data && "docs" in data.response) {
          results = data["response"]["docs"];
          var len = results.length;
          var l;
          for (l = 0; l < len; l++) {
            var result = results[l];
            var id = result["id"];
            var title = result["title_tesim"][0];
            var digitalURL = "http://digital.library.cornell.edu/catalog/" + id;
            var imageContent = "";
            if(thumbnailImageProp in result && result[thumbnailImageProp].length) {
              var imageURL = result[thumbnailImageProp][0];
              imageContent = "<a  target='_blank' title='" + title + "' href='" + digitalURL + "'><img style='max-width:90%;'  src='" + imageURL + "'></a>";
            }
            resultsHtml += "<li>";
            if(imageContent != "") {
              resultsHtml += "<div style='float:none;clear:both;'><div style='float:left;margin-bottom:5px;width:15%'>" + imageContent + "</div>";
            }
            resultsHtml += generateLink(digitalURL, title);
            if(imageContent != "") {
              resultsHtml += "</div>";
            }
            resultsHtml += "</li>";
            
          }
          $("#dig-search-anchor").attr("href","http://digital.library.cornell.edu/?f[" + dcFacetName + "][]=" + dcFacetValue);
          $("#digital-results").append(resultsHtml);
          
        }
      }
    });
    
  }
  
}

function generateLink(URI, label) {
  return label  + " <a class='data-src' target='_blank' title='" + label + "' href='" + URI + "'><img src='/assets/dc.png' /></a>";
}



