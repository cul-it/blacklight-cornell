var addDiscogsLegend = false;
function renderWikidataLegend(wikiURI) {
        var dt_margin_top = "50px";
        var dd_margin_top = "55px";

        if ( $('dt#discogs-legend').length ) {
          dt_margin_top = "10px";
          dd_margin_top = "15px";
        }
        var the_html = '<dt class="blacklight-donor_display col-sm-3" style="margin-top:' + dt_margin_top + ';">'
                    + '<div class="wikidata-bgc" style="width:40px;display:inline-block">&nbsp;</div></dt>'
                    + '<dd class="blacklight-donor_display col-sm-9" style="margin-top:' + dd_margin_top + ';">'
                    + '<a href="' + wikiURI + '" target="_blank">From the Wikidata entry <i class="fa fa-external-link"></i></a></dd>';

        $('dl.dl-horizontal').append(the_html);
    }
var processDiscogs = {
  onLoad: function() {
      
    var single_author = false;
    if ( $('dd.blacklight-format > i').attr("class").indexOf("fa-music") > 0 ) {
        var title_resp = $('#title_resp').val().replace(/.\s*$/, "");
        var title = $('#title').val();
        var subtitle = $('#subtitle').val();
        var pub_date = $('#pub_date').val();
        var publisher = $('#publisher').val();
        var publisher_nbr = $('#publisher_nbr').val();
        var other_tile = $('#other_tile').val();
        var author = $('#author').val();
        // if the author_json value contains partial or full date range, eliminate it
        if ( author[author.length -1] == "-" || author[author.length -6] == "-") {
            author = author.substring(0, author.lastIndexOf(","));
            single_author = true;
        }
        // or if we only have one author but no date range
        else if ( (author.match(/,/g) || []).length == 1 && author.endsWith(".") ) {
            author = author.replace(/.\s*$/, "");
            single_author = true;
        }
        else {
            author = author.replace(/\./g, "");
        }
        // The Naxos recordings never match Discogs, so don't do anything for those.
        if ( publisher.indexOf("Naxos") == -1 ) {
          var queryStr = this.buildSearchQueryString(title_resp, title, subtitle, pub_date, publisher, publisher_nbr, other_tile, author, single_author);
          // console.log("query string = " + queryStr);
          this.makeSearchAjaxCall(queryStr, title);
        }
    }
  },
  
  buildSearchQueryString: function(title_resp, title, subtitle, pub_date, publisher, publisher_nbr, other_tile, author, single_author) {
      var queryStr = "";
      
      // some catalog items won't have an author value but will have musicians listed in the title_resp field. 
      // In those cases add title_resp to the query string.
      if ( author.length > 0 ) {
        // if the author name is in the title, we only need the latter but only in the case of a single author
        // reverse last name, first name
        if ( single_author ) { 
          var first_last = author.substring(author.indexOf(",") + 2, author.length) + " " + author.substring(0, author.indexOf(","))
          if ( title.indexOf(first_last) == -1 && subtitle.indexOf(first_last) == -1) {
              queryStr = author + "+" + title;
          }
          else {
              queryStr = title;
          }
        }
        else if ( title.indexOf(author) == -1 ){
            queryStr = author + "+" + title;
        }
        else {
            queryStr = title;
        }
      }
      else {
          queryStr = title_resp + "+" + title;
      }
      if ( subtitle.length > 0 ) {
          queryStr += "+" + subtitle ;
      }
      
      if ( publisher_nbr.length > 0 ) {
          queryStr += "+" + publisher_nbr;
      }
      else {
          queryStr += "+" + publisher.replace(",","").replace(":","") + "+" + pub_date;
          // queryStr += " " + pub_date;
      }
      
      queryStr = queryStr.replace(/ /g,"+").replace(/\&/g,"and").replace("++","+");
      return queryStr;
  },

  makeSearchAjaxCall: function(queryStr, title) {
    var authorityUrl = "https://lookup.ld4l.org/authorities/search/discogs/release?";
    $.ajax({
      url : authorityUrl,
	  type: 'GET',
   	  dataType: 'json',
	  data: {
	    q: queryStr,
	  },
   	  complete: function(xhr, status) {
       	var results = $.parseJSON(xhr.responseText);
		if ( results.length > 0 ) {
			var discogs_id = results[0]["id"];
			var imageUrl = results[0]["context"]["Image URL"][0];
			var label = results[0]["label"];
			processDiscogs.makeShowAjaxCall(discogs_id, title, imageUrl);
        }
   	  }
    });
  },
  
  makeShowAjaxCall: function(discogs_id, title, imageUrl) {
    var authorityUrl = "https://lookup.ld4l.org/authorities/show/discogs/release/" + discogs_id;
    //var results = [];
    $.ajax({
      url : authorityUrl,
	  type: 'GET',
   	  dataType: 'json',
   	  complete: function(xhr, status) {
       	var results = $.parseJSON(xhr.responseText);
		if ( results != undefined ) {
    	    var discogs_title = results["title"];
    	    if ( discogs_title.toLowerCase().indexOf(title.toLowerCase()) >= 0 ) {
        	    $("#discogs-image").append("<img src='" + imageUrl + "' width='150px'/>");
                processDiscogs.discogsMetadataChecks(results);
            }
    	    // Sometimes there won't be an author/artist listed in the catalog, but we'll get one back from Discogs.
    	    // So store that in an input field and use it when we make the catalog call during the Wikidata portion.
    	    // This name will prevent erroneous results coming back from the catalog.
    	    var artistHtml = '<input id="discogs-artist" value="' + results["artists"][0]["name"] + '" type="hidden">';
    	    $('input#format').after(artistHtml);
    	    if ( results["master_id"] != undefined )
    	        processDiscogs.getWikidata(results["master_id"]);
            }
   	  }
    });
  },

  metadataCheck: function() {
      // Do we have metadata for this recording?
      // if there's a table of contents or list of contributors, we don't have to build the metadata
      if ( $('dt.blacklight-contents_display').length || $('dt.blacklight-author_addl_json').length) {
            return true;
      }
      return false;
  },
  
  discogsMetadataChecks: function(results) {
      // Do we have metadata for this recording?
      // if there's a table of contents or list of contributors, we don't have to build the metadata
      if ( !$('dt.blacklight-contents_display').length ) {
          if ( results['tracklist'].length )
                processDiscogs.renderContents(results['tracklist']);
      }
      if ( !$('dt.blacklight-author_addl_json').length ) {
          if ( results['extraartists'].length ) 
                processDiscogs.renderContributors(results['extraartists']);
      }
      
      if ( !$('dt.blacklight-pub_info_display').length ) {
          if ( results['year'] != undefined || results['labels'].length ) {
              var country = results["country"].length ? results["country"] : "";
              processDiscogs.renderPublished(results['year'], results['labels'], country);
          }
      }
      
      if ( !$('dt.blacklight-notes').length ) {
          if ( results['notes'].length ) {
              var companies = results["companies"].length ? results["companies"] : [];  
              processDiscogs.renderNotes(results['notes'], companies);
          }
      }
      
      if ( !$('dt.blacklight-subject_json').length ) {
          if ( results['styles'] != undefined || results['genres'].length ) 
                processDiscogs.renderGenres(results['styles'], results['genres']);
      }

      if ( addDiscogsLegend ) 
        processDiscogs.renderDiscogsLegend(results['uri']);      
  },

  renderPublished: function(year, labels, country) {
    var the_html = '<dt class="blacklight-pub_info_display col-sm-3"><span class="discogs-bgc" style="padding:0 2px;">Published:</span></dt>'
                    + '<dd class="blacklight-pub_info_display col-sm-9">';
    if ( country.length ) {
        the_html += country + " : ";
    }
    if ( labels.length ) {
        var prev_label = "";
      	$.each(labels, function(i, val) {
      	    if ( val["name"] != prev_label ) {
      		    the_html += val["name"] + ", ";
      		    prev_label = val["name"];
      		}
      	});
    }    
    if ( year != undefined ) {
        the_html += year + ".";
    }
    else {
        the_html = the_html.replace(/, ([^, ]*)$/,'.' + '$1');
    }
  	the_html += '</dd>';
  	
  	if ( $('dd.blacklight-language_display').length ) {
  	    $('dd.blacklight-language_display').after(the_html);
  	}
  	else {
  	    $('dd.blacklight-format').after(the_html);  	    
  	}
  	addDiscogsLegend = true;
  },

  renderContributors: function(artists) {
      var the_html = '<dt class="blacklight-author_addl_json col-sm-3"><span class="discogs-bgc" style="padding:0 2px;">Contributors:</span></dt>'
                    + '<dd class="blacklight-author_addl_json col-sm-9">';
      var contributors = []
      // build an array that eliminates duplicate names and combines roles
      artists.forEach(function(item) {
        var existing = contributors.filter(function(v, i) {
          return v.artist == item["name"];
        });
        if (existing.length) {
          var existingIndex = contributors.indexOf(existing[0]);
          contributors[existingIndex].role = contributors[existingIndex].role + ", " + item["role"];
        } else {
          contributors.push({artist: item["name"], role: item["role"]});
        }
      });

      // now iterate through the new array and build the html
      count = 0;
      $.each(contributors, function(i, val) {
          if ( count > 0 ) {
              the_html += '<br />' + val["artist"];
          }
          else {
              the_html += val["artist"];
          }
      	  if ( val["role"].length > 0 ) {
      	      the_html += ', ' + val["role"].replace("Composed By","composer").toLowerCase().replace("[","(").replace("]",")");
      	  }
      	  count += 1;
      });
  	  the_html += "</dd>";
  	  if ( $('dd.blacklight-contents_display').length ) {
	      $('dt.blacklight-contents_display').before(the_html);
	  } 
  	  else if ( $('dd.blacklight-description_display').length ) {
  	      $('dd.blacklight-description_display').after(the_html);
  	  } 
	  else if ( $('dd.blacklight-contents_display').length ){
          $('dt.blacklight-notes').before(the_html);
	  }
	  else {
	      $('dl.dl-horizontal').append(the_html);  
	  }
      addDiscogsLegend = true;
  },
  renderContents: function(tracks) {
    var the_html = '<dt class="blacklight-contents_display col-sm-3"><span class="discogs-bgc" style="padding:0 2px;">Table of contents:</span></dt>'
                    + '<dd class="blacklight-author_addl_json col-sm-9"><ul>';
  	$.each(tracks, function(i, val) {
  		the_html += '<li>' + val["title"] + ' (' + val["duration"] + ')' + "</li>";
  	});
  	the_html += '</ul></dd>';
	if ( $('dd.blacklight-description_display').length ) {
	    $('dd.blacklight-description_display').after(the_html);
	} 
	else if ( $('dd.blacklight-author_addl_json').length ) {
	    $('dd.blacklight-author_addl_json').after(the_html);
	} 
	else if ( $('dd.blacklight-notes').length ){
      $('dt.blacklight-notes').before(the_html);
	}
	else {
	    $('dl.dl-horizontal').append(the_html);  
	}
  	addDiscogsLegend = true;
  },

  renderNotes: function(notes, companies) {
      var companiesStr = "";

      if ( notes.toLowerCase().indexOf("recorded") == -1 ) {
          $.each(companies, function(i, val) {
              // Do we have a Recorded At company? and is that location not already mentioned in the notes?
              if ( val["entity_type_name"] == "Recorded At" ) {
          	    companiesStr = "<br/>Recorded at " + val["name"];
          	  }
          });          
      }

      var the_html = '<dt class="blacklight-notes col-sm-3"><span class="discogs-bgc" style="padding:0 2px;">Notes:</span></dt>';
      the_html += '<dd class="blacklight-notes col-sm-9">' + notes + companiesStr + "</dd>";
      $('dl.dl-horizontal').append(the_html); 
      addDiscogsLegend = true;
  },
  
  renderGenres: function(styles, genres) {
    var the_html = '<dt class="blacklight-subject_json col-sm-3"><span class="discogs-bgc" style="padding:0 2px;">Genres:</span></dt>'
                    + '<dd class="blacklight-subject_json col-sm-9">';
    if ( genres.length ) {
      	the_html += genres.join(", ") + ", ";
    }    
    if ( styles.length ) {
        the_html += styles.join(", ") + ", ";
    }
  	the_html = the_html.replace(/, ([^, ]*)$/,'.' + '$1') + '</dd>';
  	
	if ( $('dd.blacklight-description_display').length ) {
	    $('dt.blacklight-description_display').before(the_html);
	} 
	else if ( $('dd.blacklight-publisher_number_display').length ) {
	    $('dd.blacklight-publisher_number_display').after(the_html);
	} 
	else if ( $('dd.blacklight-pub_info_display').length ){
      $('dd.blacklight-pub_info_display').after(the_html);
	}
	else {
	    $('dd.blacklight-format').after(the_html);  
	}
  	addDiscogsLegend = true;
  },

  renderDiscogsLegend: function(uri) {
      var the_text = "From the Discogs database";
      var the_html = '<dt id="discogs-legend col-sm-3" class="blacklight-donor_display" style="margin-top:50px;">'
                  + '<div class="discogs-bgc" style="width:40px;display:inline-block">&nbsp;</div></dt>'
                  + '<dd class="blacklight-donor_display col-sm-9" style="margin-top:55px;">';
      if ( uri != undefined && uri.length ) {
          the_html += '<a href="' + uri + '" target="_blank">' + the_text + ' <i class="fa fa-external-link"></i></i></a></dd>';
      }
      else {
          the_html += the_text + '</dd>';
      }
      $('dl.dl-horizontal').append(the_html);
  },

  getWikidata: function(master_id) {
    var wikidataEndpoint = "https://query.wikidata.org/sparql?";
  	var sparqlQuery = "SELECT ?entity ?followsLabel ?followedByLabel " 
  	                   + "WHERE { "
  	                   + "?entity wdt:P1954 '" + master_id + "' . "
  	                   + "?entity wdt:P155 ?follows ."
  	                   + "?follows rdfs:label ?followsLabel ."
  	                   + "?entity wdt:P156 ?followedBy ."
  	                   + "?followedBy rdfs:label ?followedByLabel ."
  	                   + "}"
  	                   + "Limit 1";
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
		        if ( data["results"]["bindings"].length ) {
		            var bindings = data["results"]["bindings"];
                    var wikiURI = bindings[0]["entity"]["value"];
                    var follows = bindings[0]["followsLabel"]["value"];
                    var followedBy = bindings[0]["followedByLabel"]["value"];
                    if ( follows.length ) {
                        processDiscogs.renderNotesAddenda(follows, "Preceded by");
                    }
                    if ( followedBy.length ) {
                        processDiscogs.renderNotesAddenda(followedBy, "Followed by");
                    }
                    renderWikidataLegend(wikiURI);
                }
		    }
		}
    });
  },
  
  renderNotesAddenda: function(title, type) {
      var the_html = '<dt class="blacklight-notes col-sm-3" >Notes:</dt>';
      var title_html = '<dd class="blacklight-notes col-sm-9"><span class="wikidata-bgc" style="padding:0 2px;margin-top:20px">' + type 
                        + ':</span><span id="' + type.replace(" ","").toLowerCase() + '" style="padding-left:4px">' + title + '</span></dd>';

      if ( $('dt#discogs-legend').length ) {
          $('dt#discogs-legend').before(title_html);
      }
      else if ( $('dt.blacklight-notes').length ) {
          $('dl.dl-horizontal').append(title_html);
      }
      else {
          the_html += title_html;
          $('dl.dl-horizontal').append(the_html); 
      }
      // check the catalog to see if we have this work
      processDiscogs.checkTheCatalog(title, type.replace(" ","").toLowerCase());
  },
  
  checkTheCatalog: function(title, type) {
      var author = $("#author").val().length ? $("#author").val() : $("#discogs-artist").val();
      var solrUrl = "http://da-prod-solr8.library.cornell.edu/solr/ld4p2-blacklight/select?";
      var catalog_id = "";
      $.ajax({
          url : solrUrl,
  	      type: 'GET',
  	      data: {
  	          fl: "id",
  	          fq: "title_t:(" + title + ")",
  	          q: author,
  	          rows: 1,
  	          wt: "json"
  	      },
          dataType: 'jsonp',
          jsonp: 'json.wrf',
     	  complete: function(response) {
     	    if ( JSON.stringify(response["responseJSON"]["response"]["numFound"]) > 0 ) {
         	    catalog_id = response["responseJSON"]["response"]["docs"][0]["id"];
  		        if ( catalog_id != undefined ) {
  		            var the_link = '<a href="/catalog/' + catalog_id + '">' + title + '</a>';
      	            $('span#' + type).html(the_link);
      	        }
      	    } 
     	  }
      });
  }
  
};  
Blacklight.onLoad(function() {
    if ( $('body').hasClass("catalog-show") ) {
        processDiscogs.onLoad();  
    }
});  
