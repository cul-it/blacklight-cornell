var buildAlternateSuggestions = {
  onLoad: function() {
    var q = $('input#q').val();
    if (q.length) {
      this.gatherSuggestions(q);
    }
  },

  // function checks each suggested search to display only those with > 0 catalog results
  checkSuggestions: function(suggestions) {
    // first, the suggestions will be checked all at once with a faceted catalog solr query
    var facetList = '&facet.query=' + suggestions.join('&facet.query=')
    var solrQuery = "http://da-prod-solr8.library.cornell.edu/solr/ld4p2-blacklight/select?indent=on&wt=json&rows=0&q=*.*&facet=true" + facetList
    $.ajax({ // would be nice to pull url from env var rather than directly include it in code
      url: solrQuery,
      type: 'GET',
      dataType: 'jsonp',
      jsonp: 'json.wrf', // avoid CORS and CORB errors
      complete: function(response) {
        // suggestions from query return that have nonzero catalog result counts "survive" the check
        var survivingSuggestions = Object.keys(response["responseJSON"]["facet_counts"]["facet_queries"]);
        // use array subtraction to get zero-count (non-surviving) suggestions
        var suggestionsToDoubleCheck = suggestions.filter(n => !survivingSuggestions.includes(n));
        // double-check these zero-count suggestions with nonfaceted search requests
        var ajaxRequests = buildAlternateSuggestions.ajaxRequestsForDoubleCheck(suggestionsToDoubleCheck);
        var whenRequests = $.when.apply($, ajaxRequests); // run each double-check request
        whenRequests.done(function( x ) {
          $.each(arguments, function(index, responseData){
            // when Ajax is done done, get JSON from responseData, an array of response info per request
            var solrDoublecheckResults = responseData[2].responseJSON
            // if there were more than zero catalog results, the suggestion has passed the double-check test
            if (solrDoublecheckResults.response.numFound > 0) {
              // add the passing search suggestion string into the list to be show to the user
              survivingSuggestions.push(solrDoublecheckResults.responseHeader.params.q)
            }
          });
          // display the suggestions that have nonzero catalog result counts
          buildAlternateSuggestions.displaySuggestions(survivingSuggestions);
        });
      }
    });
  },

  // function creates an (unexecuted) solr catalog Ajax request promise for each unique string in a list of suggested searches
  // these will be used by checkSuggestions() to double-check each suggestion that didn't pass the faceted catalog check
  ajaxRequestsForDoubleCheck: function(suggestions) {
    var requests = []; // function returns an array of other functions, each of which is an Ajax request
    var unique = [...new Set(suggestions)]; // compell suggestion strings to be unique
    $.each(unique, function(i, val) {
      var solrQuery = "http://da-prod-solr8.library.cornell.edu/solr/ld4p2-blacklight/select?wt=json&rows=0&facet=false&q=" + val
      requests.push( // add each Ajax request to the array
        $.ajax({
          url: solrQuery,
          type: 'GET',
          dataType: 'jsonp',
          jsonp: 'json.wrf' // avoid CORS and CORB errors
        })
      );
    });
    return requests;
  },

  // get strings, via Ajax requests, that may be useful as search suggestions
  gatherSuggestions: function(q) {
    var ajaxRequests = buildAlternateSuggestions.ajaxRequestsForSuggestedSearches(q); // get array of Ajax request promises
    var whenRequests = $.when.apply($, ajaxRequests); // run each request in the array
    whenRequests.done(function(ld4l, dbpedia, wikidata){ // when done running, process responses
      var responseData = ld4l[0].concat(dbpedia[0].results).concat(wikidata[0].search) // array of somewhat-normalized response data
      var filteredData = responseData.filter(function(item) { // filter out some search suggestions
        return buildAlternateSuggestions.retainLabel(q, item.label, (item.description ? item.description : ''))
      });
      var labelStrings = filteredData.map(x => x.label); // extract the search suggestion strings from the rest of the data
      buildAlternateSuggestions.checkSuggestions(labelStrings); // pass the labels to be checked as search suggestions
    })
  },

  // set up Ajax requests to three sources of search suggestion strings
  ajaxRequestsForSuggestedSearches: function(q) {
    var queryStringNoSpace = q.replace(/ /g, "+");
    var ajaxParametersList = [
      {
        url: 'https://lookup.ld4l.org/authorities/search/linked_data/locsubjects_ld4l_cache?&maxRecords=8&q=' + queryStringNoSpace, 
        type: 'GET',
        dataType: 'json'
      },
      {
        url: 'http://lookup.dbpedia.org/api/search/KeywordSearch?MaxHits=8&QueryString=' + queryStringNoSpace, 
        type: 'GET',
        dataType: 'json'
      },
      {
        url: 'https://www.wikidata.org/w/api.php?action=wbsearchentities&type=item&format=json&language=en&limit=8&search=' + queryStringNoSpace,
        type: 'GET',
        dataType: 'jsonp'
      }
    ];
    return ajaxParametersList.map(p => $.ajax(p)); // return an array of Ajax promises
  },
  
  retainLabel: function(q, label, desc) {
      if ( q.toLowerCase() == label.toLowerCase() ) {
          return false;
      }
      else if ( q.toLowerCase() == label.toLowerCase().replace("the ","") ) {
            return false;
      }
      if ( desc.indexOf("article") >= 0 ) {
          return false;
      }
      if ( label.indexOf("Wikipedia:") >= 0 ) {
          return false;
      }
      if ( label.indexOf("disambiguation") >= 0 ) {
          return false;
      }
      return true;
  },


  displaySuggestions: function(suggestions) {
      var opening_html = "<div class='expand-search'><div class='card'><div class='card-header'>Related searches"
                     + "</div><div class='card-body'><ul class='fa-ul'>";
      var closing_html = "</ul></div></div></div>";
      var list_html = "";
      if ( suggestions.length ) {
          suggestions = $.unique(suggestions.sort());
          // console.log("results = " + suggestions.toSource());
          $.each(suggestions, function(i, val) {
                list_html += "<li style='padding-left:16px;text-indent:-8px;'><i class='fa fa-search fa-inverse' aria-hidden='true' alt=''></i>"
                             + "<a href='/catalog?only_path=true&q=" + val.replace(/ /g, "+").replace(/--/g, "+")  
                             + "&search_field=all_fields&utf8=%E2%9C%93'>"
                             + val 
                             + "</a></li>";
          });
          $("#expanded-search").append(opening_html + list_html + closing_html);
      }
  }

};  
  
Blacklight.onLoad(function() {
  $('body.catalog-index').each(function() {
    buildAlternateSuggestions.onLoad();
  });
});