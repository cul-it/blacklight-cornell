class work {
    
    constructor(heading, includedWorks, baseUrl, authorTitleUrl) {
        this.heading = heading;
        this.baseUrl = baseUrl;
        this.includedWorks = includedWorks;
        this.authorTitleUrl = authorTitleUrl;
    }
   
    //Initialize

    init() {
        //this.bindEventListeners();
        this.queryHeading(this.heading, this.includedWorks);
        
    }

    parseHeading(heading) {
        var parsedHeadings = [];
        var eThis = this;
        if(heading != "") {
            var headingJSON = JSON.parse(heading);
            if(headingJSON.length > 0) {
                parsedHeadings = $.map(headingJSON, function(h, i) {
                    return {"originalHeading": h, "parsedHeading": eThis.reformatHeading(h)};
                });
            }
        }
        return parsedHeadings;
    }

    parseIncludedWork(work) {
        var parsedWorks = [];
        var eThis = this;
        if(work != "") {
            var workJSON = JSON.parse(work);
            if(workJSON.length > 0) {
                parsedWorks = $.map(workJSON, function(h, i) {
                    return eThis.reformatIncludedWork(h);
                });
            }
        }
        return parsedWorks;
    }
    //Submit heading which includes a pipe value from the catalog, and remove the pipe value.  
    reformatHeading(pipeHeading) {
        var headingArray = pipeHeading.split("|");
        var trimmedArray = $.map(headingArray, function(v, i) {
            return v.trim();
        });
        return trimmedArray.join(" ");
    }   

    reformatIncludedWork(work) {
        var reformattedWork = work;
        if(work.indexOf("|") > -1) {
            reformattedWork = work.substring(0, work.indexOf("|")).trim();
        }
        return reformattedWork;
    }   

    //Query LOC

    //We are going to focus on situations where there is only one author title facet OR where there are multiple included works. In the former, this is just one call and the fields get added directly
    //In the latter, we focus on included works and add that info
    queryHeading(heading, works) {
        //There may be multiple author title facets possible
        var queryHeadings = this.parseHeading(heading);
        var includedWorks = this.parseIncludedWork(works);
        //If more than one query heading, check included works if they exist
        if(queryHeadings.length == 1) {
            //This only requires the parsed heading
            this.handleQueryHeading(queryHeadings[0]["parsedHeading"]);
        }
        else if(queryHeadings.length > 1 && includedWorks.length > 0) {
            this.handleQueryWorks(queryHeadings);
        }

    }

    handleQueryHeading(parsedQueryHeading) {
        var eThis = this;
       
        var lookupURL = "http://id.loc.gov/authorities/names/suggest/?q=" + parsedQueryHeading + "&rdftype=NameTitle&count=1";
        var promise = eThis.requestDataForHeading(lookupURL);
       
        //Assumption: promises are returned below in the order in which they were added
        promise.then(function() {
            var dArgs = arguments[0];   
            var headingData = eThis.handleHeadingData(dArgs);
            if(headingData != null) {
                var dataPromise = headingData;
                var dataPromiseHeading = parsedQueryHeading;
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
                            //only show source links if there is something to display
                            sourceLinks += eThis.generateWikidataSourceLinks(md["mappedData"]);
                        }
                    } else {
                        //We should have at MOST one
                    }   
                    //eThis.attachPopover(htmlForPopover);
                    eThis.attachFieldHTML(htmlForField);
                    $("#wikidata_source").append(sourceLinks);              
                });
            }
        });
    }

    //attach popovers for each included work, using a request to the author title browse index
    handleQueryWorks(queryHeadings) {
        var eThis = this;
        var browsePromises = [];
        $.each(queryHeadings, function(i, h) {
            var lookupHeading = h["originalHeading"];
            var lookupURL = eThis.authorTitleUrl + "\"" + lookupHeading + "\"";
            browsePromises.push($.ajax({url : lookupURL}));
        });
        $.when.apply($, browsePromises).then(function() {
            //Array to store author title browse info where returned
            var authorTitleBrowseInfo = {};
            //Have consistent structure regardless of number of promises
            var dArgs = arguments;
            if(browsePromises.length == 1) {
                dArgs = [arguments];
            }
            $.each(dArgs, function(i, data) {   
                if(data != null && data.length && data[0] != null && data[0].length && data[0][0] != null) {
                    var headingInfo = data[0][0];
                    console.log(headingInfo);
                    var isAuthority = ("authority" in headingInfo && headingInfo["authority"] == true)? true: false;
                    var heading = headingInfo["heading"];
                    //console.log(isAuthority);
                    if(isAuthority) {
                        var parsedInfo = eThis.parseAuthorTitleBrowseInfo(headingInfo);
                        //We want the parsed heading, i.e. without the pipe, because we need to match against the included work title from the html
                        authorTitleBrowseInfo[parsedInfo["parsedHeading"]] = eThis.parseAuthorTitleBrowseInfo(headingInfo);
                    }
                }
            });
            eThis.kickoffWorkPopovers(authorTitleBrowseInfo);
        });
       
    }

    parseAuthorTitleBrowseInfo(headingInfo) {
        var info = {};
        var heading = headingInfo["heading"];
        info["originalHeading"] = headingInfo["heading"];
        info["parsedHeading"] = this.reformatHeading(heading);
        if("counts_json" in headingInfo) {
            var counts_str = headingInfo["counts_json"];
            var counts = JSON.parse(counts_str);
            info["counts"]= counts;
        }
        if("rda_json" in headingInfo) {
            var rda_str = headingInfo["rda_json"];
            info["rda"] = JSON.parse(rda_str);
        }
        return info;
    }

    //Array of heading information
    kickoffWorkPopovers(mappedDataHash) {
        console.log(mappedDataHash);
        var aTags = $("dd.blacklight-included_work_display a");
        var eThis = this;
        aTags.each(function (i) {
            var linkText = $(this).text();
            //get rid of ending punctuation
            var strippedLinkText = linkText.replace(/\.$/, "").trim();
            if(strippedLinkText in mappedDataHash) {
                var info = mappedDataHash[strippedLinkText];
                var originalHeading = info["originalHeading"];
                var parsedHeading = info["parsedHeading"];
                var newText = '<a originalHeading=\"' + originalHeading + '\" heading=\"' + parsedHeading + '\" href="#" role="button" tabindex="0" data-trigger="focus" class="info-button d-none d-sm-inline-block btn btn-sm btn-outline-secondary">Work info »</a>';
                $(this).after(newText);
                //var generatedHTML = eThis.generateWorkPopoverHTML(info["mappedData"], info["heading"]);
                var generatedHTML = eThis.generateAuthorTitlePopoverHTML(info);

                $("a[heading='" + parsedHeading + "']").click(function(e) {
                    e.preventDefault();
                    $(this).popover({content: generatedHTML, html:true, trigger:'focus'}).popover('show');
                    //Kick off ajax request to get info from LOC + Wikidata
                    eThis.getExternalPopoverData(parsedHeading); 
                });
            } 
           });
    }

    getExternalPopoverData(lookupHeading) {
        var eThis = this;
        var lookupURL = "http://id.loc.gov/authorities/names/suggest/?q=" + lookupHeading + "&rdftype=NameTitle&count=1";
        var lookupPromise = this.requestDataForHeading(lookupURL);
        //Assumption: promises are returned below in the order in which they were added
        $.when(lookupPromise).then(function() {
            //Have consistent structure regardless of number of promises
            var dArgs = [arguments];
            //console.log("Lookup LOC info");
            //console.log(dArgs);
            $.each(dArgs, function(i, data) {              
                var dataPromise = eThis.handleHeadingData(data[0]);
                if(dataPromise != null) {
                    //console.log("created data promise");
                    $.when(dataPromise).then(function() {
                        var dpArgs =  [arguments];
                        //We can have more results returned than actual information
                        var mappedDataArray = [];
                        $.each(dpArgs, function(i, dpv) {
                            var dpvData = dpv[0];     
                            //console.log(dpvData);               
                            var mappedData = eThis.parseQueryResults(dpvData);
                            if(eThis.isMappedDataDisplayed(mappedData)) {
                                mappedDataArray.push({"mappedData": mappedData,
                                    "heading": lookupHeading});
                            } 
                            //see if mapped data has anything that will be displayed
                        });
                        //We can have different handling for multi-entity display versus single entity
                        //console.log(mappedDataArray);
                        if(mappedDataArray.length && mappedDataArray[0]) {
                            eThis.addDisplayWorkPopovers(mappedDataArray[0]);
                        }
                    });
                }
            });
           
           
        });
    }
    
    addDisplayWorkPopovers(mappedDataObj) {
        var mappedData = mappedDataObj["mappedData"];
        var eThis = this;
        var evenClassName = "field2-bg";
        var oddClassName = "field1-bg";
        var fieldClassName = oddClassName;
        var rowCount = 1;
        var fieldMapping = {"opus": "Opus", 
        "tonalityLabel": "Tonality",
        "instrumentationLabel": "Instrumentation"};
        var html = "";
        
        //html += "<div id='authorTitleDescription'>" + 
		//    "<div class='dl dl-horizontal'>";

        if("codes" in mappedData && mappedData["codes"].length > 0) {
            var codes = mappedData["codes"];
            var codesArray = $.map(codes, function(code, i) {
                return code["catalogLabel"] + " : " + code["code"];
            });
            
            html += "<div class='dt " + fieldClassName + "'>Codes</div><div class='dd " + fieldClassName + "'>" + codesArray.join("<br>") + "</div>";
            rowCount += 1;
        }
        
        $.each(fieldMapping, function(prop, label) {
            var label = fieldMapping[prop];
            if(prop in mappedData) {
                fieldClassName = (rowCount % 2 == 0)? evenClassName: oddClassName;
                var value = mappedData[prop];
                /*
                if(prop == "date") {
                    value = eThis.formatDate(value);
                }*/
                //if value is array
                value = $.isArray(value) ? value.join(", "): value;
                html += "<div class='dt " + fieldClassName + "'>" + label + ": </div><div class='dd " + fieldClassName + "'>" + value + "</div>";
                rowCount += 1;
            }
        });
        
        $("#authorTitleDescriptionContainer").append(html);

    }
    generateAuthorTitlePopoverHTML(info) {
        var eThis = this;
        var evenClassName = "field2-bg";
        var oddClassName = "field1-bg";
        var fieldClassName = oddClassName;
        var rowCount = 1;
        var parsedHeading = info["parsedHeading"];
        var originalHeading = info["originalHeading"];
        var headingBrowseLink = this.baseUrl + "browse/info?browse_type=Author-Title&authq=" + originalHeading;
        var workSearchLink = this.baseUrl + "?q=" + originalHeading + "&search_field=";
        var html = "<h2>" + parsedHeading + "</h2>";
        html += "<div class='author-works float-none'>" + 
		    "Works: <a href='" + workSearchLink + "authortitle_browse' id='worksForHeading'>" + info["counts"]["works"] + "</a>" + 
	        "</div>" + 
	        "<div class='author-works float-none'>" + 
		    "Works about: <a href='" + workSearchLink + "subjectwork_browse' id='worksAboutHeading'>" + info["counts"]["worksAbout"] + "</a>" + 
	        "</div>";
        
            html += "<div id='authorTitleDescription'>" + 
		    "<div class='dl dl-horizontal' id='authorTitleDescriptionContainer'>";
        if("rda" in info) {
            $.each(info["rda"], function(label, value) {
                fieldClassName = (rowCount % 2 == 0)? evenClassName: oddClassName;
                
                //if value is array
                value = $.isArray(value) ? value.join(", "): value;
                html += "<div class='dt " + fieldClassName + "'>" + label + ": </div><div class='dd " + fieldClassName + "'>" + value + "</div>";
                rowCount += 1;
            });
        }
        html += "</div></div>";
       var fullLink = "<div class='mt-2 w-100 text-right'><a id='fullRecordLink' href='" + headingBrowseLink + "'>" + 
        "<span class='info-button d-sm-inline-block btn btn-sm btn-outline-secondary'>View full info &raquo;</span></a>" + 
        "</div>";
        return "<div id='popoverContent' class='kp-content'>" + 
            "<div id='panelMainContent' class='mt-2 float-none clearfix'>" + html + "</div>" + 
            fullLink + "</div>";  
    }

    //
    handleQueryWorksPlace(includedWorks, queryHeadings) {
        
        var eThis = this;
        var promises = [];
        $.each(queryHeadings, function(i, h) {
            var lookupHeading = h["parsedHeading"];
            var lookupURL = "http://id.loc.gov/authorities/names/suggest/?q=" + lookupHeading + "&rdftype=NameTitle&count=1";
            promises.push(eThis.requestDataForHeading(lookupURL));
        });
       
        //Assumption: promises are returned below in the order in which they were added
        $.when.apply($, promises).then(function() {
            //Have consistent structure regardless of number of promises
            var dArgs = arguments;
            if(promises.length == 1) {
                dArgs = [arguments];
            }
            var dataPromises = [];
            var dataPromiseHeadings = [];
            var counter = 0;
            $.each(dArgs, function(i, data) {              
                var headingData = eThis.handleHeadingData(data[0]);
                if(headingData != null) {
                    dataPromises.push(headingData);
                    dataPromiseHeadings.push(queryHeadings[counter]);
                }
                counter+=1;
            });
           
            //Now resolve these second set of ajax promises
            $.when.apply($, dataPromises).then(function() {
                var dpArgs = arguments;
                if(dataPromises.length == 1) {
                    dpArgs = [arguments];
                }
                var htmlForField = "";
                var sourceLinks = "";
                counter = 0;
                //We can have more results returned than actual information
                var mappedDataArray = [];
                $.each(dpArgs, function(i, dpv) {
                    var dpvData = dpv[0];     
                    ////console.log(dpvData);               
                    var mappedData = eThis.parseQueryResults(dpvData);
                    if(eThis.isMappedDataDisplayed(mappedData)) {
                        mappedDataArray.push({"mappedData": mappedData,
                            "heading": dataPromiseHeadings[counter]});
                    } 
                    counter+=1;
                    //see if mapped data has anything that will be displayed
                })
                //We can have different handling for multi-entity display versus single entity
                eThis.displayWorkPopovers(mappedDataArray);
            });
        });
    }

    displayWorkPopovers(mappedDataArray) {
        var eThis = this;
        if(mappedDataArray.length > 0) {
            //Hash
            var mappedDataHash = {};
            $.each(mappedDataArray, function(i,v) {
                var strippedHeading = v["heading"]["parsedHeading"].replace(/\.$/, "").trim();
                mappedDataHash[strippedHeading] ={"heading":v["heading"], "mappedData": v["mappedData"]};
            });
            //Query the included work
           var aTags = $("dd.blacklight-included_work_display a");
           aTags.each(function (i) {
            var linkText = $(this).text();
            //get rid of ending punctuation
            var strippedLinkText = linkText.replace(/\.$/, "").trim();
            if(strippedLinkText in mappedDataHash) {
                var info = mappedDataHash[strippedLinkText];
                var originalHeading = info["heading"]["originalHeading"];
                var parsedHeading = info["heading"]["parsedHeading"];
                var newText = '<a originalHeading=\"' + originalHeading + '\" heading=\"' + parsedHeading + '\" href="#" role="button" tabindex="0" data-trigger="focus" class="info-button d-none d-sm-inline-block btn btn-sm btn-outline-secondary">Work info »</a>';
                $(this).after(newText);
                var generatedHTML = eThis.generateWorkPopoverHTML(info["mappedData"], info["heading"]);
                $("a[heading='" + parsedHeading + "']").click(function(e) {
                    e.preventDefault();
                    $(this).popover({content: generatedHTML, html:true, trigger:'focus'}).popover('show');
                    //We may need a different way to do this
                    //Query the browse index to get works and works about to display in the popover
                });
            } 
           });
        }
    }

    generateWorkPopoverHTML(mappedData, heading) {
        var eThis = this;
        var evenClassName = "field2-bg";
        var oddClassName = "field1-bg";
        var fieldClassName = oddClassName;
        var rowCount = 1;
        var parsedHeading = heading["parsedHeading"];
        var originalHeading = heading["originalHeading"];
        var headingBrowseLink = this.baseUrl + "browse/info?browse_type=Author-Title&authq=" + originalHeading;
        
        //We're not representing all the info in the popover
        var fieldMapping = {"opus": "Opus", 
        "tonalityLabel": "Tonality",
        "instrumentationLabel": "Instrumentation"};
        var html = "<h2>" + parsedHeading + "</h2>";
        html += "<div class='author-works float-none'>" + 
		    "Works: <a href='#' id='worksForHeading'></a>" + 
	        "</div>" + 
	        "<div class='author-works float-none'>" + 
		    "Works about: <a href='#' id='worksAboutHeading></a>" + 
	        "</div>";
        if("entity" in mappedData) {
            var entity = mappedData["entity"];
            //html+= "<div>Wikidata: <a href='" + entity + "'>" + entity + "</a></div>";
        }
        html += "<div id='authorTitleDescription'>" + 
		    "<div class='dl dl-horizontal'>";

        if("codes" in mappedData && mappedData["codes"].length > 0) {
            var codes = mappedData["codes"];
            var codesArray = $.map(codes, function(code, i) {
                return code["catalogLabel"] + " : " + code["code"];
            });
            
            html += "<div class='dt " + fieldClassName + "'>Codes</div><div class='dd " + fieldClassName + "'>" + codesArray.join("<br>") + "</div>";
            rowCount += 1;
        }
       
        $.each(fieldMapping, function(prop, label) {
            var label = fieldMapping[prop];
            if(prop in mappedData) {
                fieldClassName = (rowCount % 2 == 0)? evenClassName: oddClassName;
                var value = mappedData[prop];
                //if value is array
                value = $.isArray(value) ? value.join(", "): value;
                html += "<div class='dt " + fieldClassName + "'>" + label + ": </div><div class='dd " + fieldClassName + "'>" + value + "</div>";
                rowCount += 1;
            }
        });
        html += "</div></div>";
       var fullLink = "<div class='mt-2 w-100 text-right'><a id='fullRecordLink' href='" + headingBrowseLink + "'>" + 
        "<span class='info-button d-sm-inline-block btn btn-sm btn-outline-secondary'>View full info &raquo;</span></a>" + 
        "</div>";
        return "<div id='popoverContent' class='kp-content'>" + 
            "<div id='panelMainContent' class='mt-2 float-none clearfix'>" + html + "</div>" + 
            fullLink + "</div>";
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
    //Generate popup knowledge panel using plain Bootstrap

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
        console.log(sparqlQuery);
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

        var html = "";
        if("codes" in mappedData && mappedData["codes"].length > 0) {
            var codes = mappedData["codes"];
            var codesArray = $.map(codes, function(code, i) {
                //return "<li>" + code["catalogLabel"] + " : " + code["code"] + " *</li>";
                return code["catalogLabel"] + " : " + code["code"] + " *";

            });
            //html += "<dt class='blacklight-wd-codes col-sm-3'>Codes:</dt><dd class='blacklight-wd-codes col-sm-9'><ul>" + codesArray.join("<br>") + "</ul></dd>";
            html += "<dt class='blacklight-wd-codes col-sm-3'>Codes:</dt><dd class='blacklight-wd-codes col-sm-9'>" + codesArray.join("<br>") + "</dd>";

        }
        if("createdFor" in mappedData) {
            var createdFor = mappedData["createdFor"];
            html += "<dt class='blacklight-wd-created col-sm-3'>Created for:</dt><dd class='blacklight-wd-created col-sm-9' loc='" + createdFor["loc"] + "'>" + createdFor["label"] + " *</dd>";
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
                var className = "blacklight-wd-" + label.replace(/\s+/g, '');
                html += "<dt class='" + className + " col-sm-3'>" + label + ":</dt><dd class='" + className + " col-sm-9'>" + value + " *</dd>";
            }
        });

       //html += "<dd class='col-sm-12 float-sm--right'>" + link + "</dd>";
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
            link+= "<div><span>* Some information for this item comes from <a href='" + entity + "'> Wikidata " + link + "<i class='fa fa-external-link' aria-hidden='true'></i></a></span></div>";
        }
        return link;
       
    }

    attachFieldHTML(fieldHTML) {
        $("#itemDetails").append(fieldHTML);
    }




}
Blacklight.onLoad(function () {
    //Only load this code on entity page 
    if ($('#work').length) {
        var r = new work($("#work").attr("heading"), $("#work").attr("included"), $("#work").attr("base-url"), $("#work").attr("authortitle-url"));
        r.init();
        
    }
});  