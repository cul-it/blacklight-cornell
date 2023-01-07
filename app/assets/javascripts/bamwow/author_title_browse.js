class authorTitleBrowse {
    
    constructor(heading, baseUrl) {
        this.heading = heading;
        this.baseUrl = baseUrl;
    }
   
    //Initialize

    init() {
        //this.bindEventListeners();
        this.queryHeading(this.reformatHeading(this.heading));
        
    }

    parseHeading(heading) {
        var parsedHeadings = [];
        var eThis = this;
        if(heading != "") {
            var headingJSON = JSON.parse(heading);
            if(headingJSON.length > 0) {
                parsedHeadings = $.map(headingJSON, function(h, i) {
                    return eThis.reformatHeading(h);
                });
            }
        }
        return parsedHeadings;
    }

  
    //Submit heading which includes a pipe value from the catalog, and remove the pipe value.  
    reformatHeading(pipeHeading) {
        var headingArray = pipeHeading.split("|");
        var trimmedArray = $.map(headingArray, function(v, i) {
            return v.trim();
        });
        return trimmedArray.join(" ");
    }   

    //Query LOC
    queryHeading(heading) {
        console.log("Query heading " + heading);
        this.handleQueryHeading(heading);
    }

    handleQueryHeading(queryHeading) {
        var eThis = this;
       //http or https?
        var lookupURL = "https://id.loc.gov/authorities/names/suggest/?q=" + queryHeading + "&rdftype=NameTitle&count=1";
        var promise = eThis.requestDataForHeading(lookupURL);
       
        //Assumption: promises are returned below in the order in which they were added
        promise.then(function() {
            var dArgs = arguments[0];   
            var headingData = eThis.handleHeadingData(dArgs);
            if(headingData != null) {
                var dataPromise = headingData;
                var dataPromiseHeading = queryHeading;
                //Now resolve these second set of ajax promises
                dataPromise.then(function() {
                    var dpArgs = arguments;
                    
                    var htmlForField = "";
                    var sourceLinks = "";
                    //We can have more results returned than actual information
                    var mappedDataArray = [];
                                
                    var mappedData = eThis.parseQueryResults(dpArgs[0]);
                    if(eThis.isMappedDataDisplayed(mappedData)) {
                        mappedDataArray.push({"mappedData": mappedData,
                            "heading": dataPromiseHeading});
                    } 
                        //see if mapped data has anything that will be displayed

                    //We can have different handling for multi-entity display versus single entity
                    if(mappedDataArray.length == 1) {
                        var md = mappedDataArray[0];
                        var generatedHTML = eThis.generateFieldHTML(md["mappedData"], md["heading"]);
                        htmlForField += generatedHTML;
                        if(generatedHTML != "") {
                            //Attach generated HTML
                            $("dl#item-details").append(generatedHTML);
                            //only show source links if there is something to display
                            sourceLinks = eThis.generateWikidataSourceLinks(md["mappedData"]);
                            $("#wiki-acknowledge").html(sourceLinks);
                        }
                    } 
       
                });
            }
        });
    }

    

    

    //Are there properties available to display the information in the data from the query results
    isMappedDataDisplayed(mappedData) {
        var propertyNames = this.getPropertyNames();
        //Are any of these property names present as keys
        var populated = false;
        $.each(propertyNames, function(i, v) {
            if(v in mappedData) {
                populated = true;
                return false;
            }
        });
        return populated;
    }


    requestDataForHeading(lookupURL) {
        return $.ajax({
            url : lookupURL,
            dataType : 'jsonp'
        });
    }

    handleHeadingData(data) {
        var wikidataPromise = null;
        var urisArray = this.parseLOCSuggestions(data);
        console.log("Handle heading data");
        console.log(urisArray);
        if (urisArray && urisArray.length) {
            var locURI = urisArray[0]; 
            wikidataPromise =  this.queryWikidata(locURI);
        }
        return wikidataPromise;
    }

    parseLOCSuggestions(suggestions) {
        var urisArray = [];
        if (suggestions && (suggestions.length > 3) && (suggestions[1] !== undefined)) {
            for (var s = 0; s < suggestions[1].length; s++) {
                var u = suggestions[3][s];
                urisArray.push(u);
            }
        }
        return urisArray;
    }

    getLocalName(uri) {
        return uri.split("/").pop();
    }
    //Query Wikidata to get related information given a particular LOC URI
    queryWikidata(uri) {
        var localName = this.getLocalName(uri);
        //console.log(localName);
        var wikidataEndpoint = "https://query.wikidata.org/sparql?";
        //Get the code and catalog, also check for other optional properties
        var sparqlQuery = this.generateSPARQLQuery(localName);
        return $.ajax({
            url : wikidataEndpoint,
            headers : {
              Accept : 'application/sparql-results+json'
            },
            data : {
              query : sparqlQuery
            }
        });
    }



    generateSPARQLQuery(localName) {
        var sparqlQuery = "SELECT ?entity ?codeval ?catalog ?catalogLabel ?music_created_for ?music_created_forLabel ?created_for_loc ?date ?location ?locationLabel ?opus ?dedicated ?dedicatedLabel ?commissionedBy ?commissionedByLabel ?tonality ?tonalityLabel ?librettist ?librettistLabel ?instrumentation ?instrumentationLabel " 
        + "WHERE {?entity wdt:P244 \"" + localName + "\" ." 
        + "OPTIONAL {?entity p:P528 ?code . ?code ps:P528 ?codeval . ?code pq:P972 ?catalog .}"
        + "OPTIONAL { ?entity wdt:P9899 ?music_created_for. ?music_created_for wdt:P244 ?created_for_loc. }"
        + "OPTIONAL { ?entity wdt:P1191 ?date .}"
        + "OPTIONAL {?entity wdt:P4647 ?location .}"
        + "OPTIONAL {?entity wdt:P10855 ?opus . }"
        + "OPTIONAL {?entity wdt:P825 ?dedicated . }"
        + "OPTIONAL {?entity wdt:P88 ?commissionedBy .}"
        + "OPTIONAL {?entity wdt:P826 ?tonality .}"
        + "OPTIONAL {?entity wdt:P87 ?librettist . }"
        + "OPTIONAL {?entity wdt:P870 ?instrumentation. }"
        + "  SERVICE wikibase:label { bd:serviceParam wikibase:language \"[AUTO_LANGUAGE],en\". }"
        + "}"; 
        return sparqlQuery;
    }

    getPropertyNames() {
        var propertyNames = ["date", "locationLabel", "opus", "dedicatedLabel", "commissionedBy", "commissionedByLabel", "tonalityLabel", "librettistLabel", "instrumentationLabel"];
        return propertyNames;
    }

    parseQueryResults(data) {
        var mappedData = {};
        var eThis = this;
        var propertyNames = this.getPropertyNames();

        if("results" in data && "bindings" in data["results"] && data["results"]["bindings"].length > 0) {
            var bindings = data["results"]["bindings"];
            var catalogCodes = {};
            $.each(bindings, function(i, binding) {
                if(! ("entity" in mappedData)) {
                    mappedData["entity"] = binding["entity"]["value"];
                }
                //catalog label and code value pairs, as nested objects, and multiple possible
                //Assume the pairing of catalog and code will always be unique, and there is only one code per catalog
                if("catalogLabel" in binding && "codeval" in binding) {
                   catalogCodes[binding["catalogLabel"]["value"]] = binding["codeval"]["value"]; 
                }
               
                //music created for label and accompanying LCCN

                if ( ("music_created_forLabel" in binding) && ("created_for_loc" in binding) && (! ("createdFor" in mappedData))) {
                    mappedData["createdFor"] = {"label": binding["music_created_forLabel"]["value"], "loc": binding["created_for_loc"]["value"]};
                }

                //We look for these values only one in the response, i.e. only the first row
                //There can be multiple instrumentation entities - so the assumption that we will have a one to one correspondence is incorrect
                //We should correct this

                //Add values for these properties to an array for the property
                $.each(propertyNames, function(i, v) {
                    if(v in binding) {
                        if(! (v in mappedData)) {
                            mappedData[v] = [];
                        }
                        mappedData[v].push(binding[v]["value"]);
                    }
                });

            });

            //Set catalog codes
            $.each(catalogCodes, function (c, cval) {
                if(! ("codes" in mappedData)) {
                    mappedData["codes"] = [];
                }
                
                mappedData["codes"].push({"catalogLabel": c, "code": cval});
            });

            //mappedData["codes"].push({"catalogLabel": binding["catalogLabel"]["value"], "code": binding["codeval"]["value"]});


            //Remove duplicates from values
            $.each(mappedData, function(key, value) {
                if($.isArray(value) && (key != "codes") && (value.length > 1)) {
                    //Remove duplicates from array
                    var deduped = [...new Set(value)];
                    mappedData[key] = deduped;
                }
            });
            
        }
        //console.log("after deduping");
        console.log(mappedData);
        return mappedData;
    }

    

    

    //Generate fields
    generateFieldHTML(mappedData, heading) {
        var eThis = this;
        //<dt class="blacklight-test col-sm-3">Name</dt>
        //<dd class="blacklight-test  col-sm-9">Info</dd>
        var fieldMapping = {"date": "First performance date", 
        "locationLabel": "First performance location", 
        "opus": "Opus", 
        "dedicatedLabel": "Dedicated to", 
        "commissionedByLabel": "Commissioned by",
        "tonalityLabel": "Tonality",
        "librettistLabel": "Librettist", 
        "instrumentationLabel": "Instrumentation"};
        //<dt class="col-sm-4 citizenship">Citizenship:</dt>
	    //<dd class="col-sm-8 citizenship"></dd>
        var html = "";
        if("codes" in mappedData && mappedData["codes"].length > 0) {
            var codes = mappedData["codes"];
            var codesArray = $.map(codes, function(code, i) {
                return "<dt>" + code["catalogLabel"] + " : " + code["code"] + " *</dt>";
            });
            html += "<dt class='col-sm-4'>Codes:</dt><dd class='col-sm-8'><dl class='dl-horizontal'>" + codesArray.join(" ") + "</dl></dd>";
        
        }
        if("createdFor" in mappedData) {
            var createdFor = mappedData["createdFor"];
            html += "<dt class='blacklight-wd-created col-sm-3'>Created for:</dt><dd class='col-sm-8' loc='" + createdFor["loc"] + "'>" + createdFor["label"] + " *</dd>";
        }

        $.each(fieldMapping, function(prop, label) {
            var label = fieldMapping[prop];
            if(prop in mappedData) {
                var value = mappedData[prop];
                if(prop == "date") {
                    value = eThis.formatDate(value);
                }
                //if value is array
                value = $.isArray(value) ? value.join(", "): value;
                html += "<dt class='col-sm-4'>" + label + ":</dt><dd class='col-sm-8'>" + value + " *</dd>";
            }
        });

        return html;
    }


   
    
    //is an array tpp
    formatDate(date) {
        var eThis = this;    
        var formattedDates = $.map(date, function(v, i) {
            return eThis.formatSingleDate(v);
        })
        return formattedDates;
    }

    formatSingleDate(date) {
        //Adding the UTC is important, otherwise it returns the date in the local time zone and the day can be off by one
        var formattedDate = new Date(date);
        var day = formattedDate.getUTCDate();
        var month = formattedDate.toLocaleDateString("default", {month: "short"});
        console.log("Month " + (parseInt(formattedDate.getUTCMonth()) + 1));
        return  (formattedDate.getUTCDate() + " " + month + ", " + formattedDate.getUTCFullYear());
    }
    generateWikidataSourceLinks(mappedData) {
        var link = "";
        if("entity" in mappedData) {
            var entity = mappedData["entity"];
            link += "  <span class='ld-acknowledge'>* <a href='" + entity + "'>From Wikidata<i class='fa fa-external-link' aria-hidden='true'></i></a></span>";
        }
        return link;
    }

    attachFieldHTML(fieldHTML) {
        $("#itemDetails").append(fieldHTML);
    }




}
Blacklight.onLoad(function () {
    //Only load this code on entity page 
    if ($('#author-title-heading').length) {
        var r = new authorTitleBrowse($("#author-title-heading").attr("heading"), $("#author-title-heading").attr("base-url"));
        r.init();
        
    }
});  