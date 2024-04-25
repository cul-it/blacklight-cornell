
function sectionrecord(shortname, longname, url, subsectionexists){

this.shortname = shortname
this.longname = longname
this.url = url
this.subsectionexists = subsectionexists

}


function findsectionproperty (sectionname, propertyname, subsectionshortname){

eval('var sectionlist = ' + sectionname + 'sections')

	for (var i = 1; i < sectionlist.length; i++){
	
		if (sectionlist[i].shortname == subsectionshortname){
		eval ("var propertyvalue = sectionlist[i]." + propertyname)
		}
		
	}

return propertyvalue

}


var topsections = new Array()

topsections[1] = new sectionrecord("home","Overview","http://rmc.library.cornell.edu/index.html")
topsections[2] = new sectionrecord("collections","Collections","http://rmc.library.cornell.edu/collections/rmccollections.html","yes")
topsections[3] = new sectionrecord("visit","Visiting","http://rmc.library.cornell.edu/visit/visitor_information.html","yes")
topsections[4] = new sectionrecord("find","Finding Materials","http://rmc.library.cornell.edu/find/services_overview.html","yes")
topsections[5] = new sectionrecord("events","Exhibitions &amp; Events","http://rmc.library.cornell.edu/events/current_exhibitions.html","yes")

	
	var findsections = new Array()
	
	findsections.longname = "Finding Materials"

	findsections[1] = new sectionrecord("overview","Research Services Overview","http://rmc.library.cornell.edu/find/services_overview.html")
	findsections[2] = new sectionrecord("materialssearch","How to Find Rare Books &amp; Manuscripts","http://rmc.library.cornell.edu/find/materials_search.html")
	findsections[3] = new sectionrecord("registration","Registration &amp; Guidelines for Use","http://rmc.library.cornell.edu/find/registration.html")
	findsections[4] = new sectionrecord("requests","Registration &amp; Requests","http://rare.library.cornell.edu")
	findsections[5] = new sectionrecord("searchrmc","Search the RMC Website","http://rmc.library.cornell.edu/find/search.html","yes")
	findsections[6] = new sectionrecord("faq","Frequently Asked Questions","http://rmc.library.cornell.edu/find/faq.html")
	findsections[7] = new sectionrecord("reference","Ask a Question","http://rmc.library.cornell.edu/find/reference.php","yes")
	
	
	
		var reproductionssections = new Array()
	
		reproductionssections.longname = "Reproductions &amp; Permissions"

		reproductionssections[1] = new sectionrecord("repropricelist","Reproduction Services Price List","http://rmc.library.cornell.edu/find/repro_pricelist.html")
		reproductionssections[2] = new sectionrecord("reproorder","Request a Reproduction","http://rmc.library.cornell.edu/find/repro_request.php")
		
		
		var searchrmcsections = new Array()
	
		searchrmcsections.longname = "Search the RMC Website"

		searchrmcsections[1] = new sectionrecord("sitemap","RMC Website Map","http://rmc.library.cornell.edu/find/sitemap.html")
		
		
		var referencesections = new Array()
	
		referencesections.longname = "Ask a Question"

		referencesections[1] = new sectionrecord("privacy","Privacy Statement","http://rmc.library.cornell.edu/find/privacy_statement.html")
	


function fixchars(name){

name = name.replace(/&amp;/g,"&")
name = name.replace(/&#8217;/g,"\u0027")
name = name.replace(/&#8220;/g,"\u0022")
name = name.replace(/&#8221;/g,"\u0022")

return name

}


function showheader(currenttopsection){

document.write('<div id="cu-identity">')

document.write('<div id="cu-logo">')
document.write('<a id="insignia-link" href="http://www.cornell.edu/"><img src="css/images/cul_logo.gif" alt="Cornell University" width="350" height="75" border="0" /></a>')
document.write('<div id="unit-signature-links">')
document.write('<a id="cornell-link" href="http://www.cornell.edu/">Cornell University</a>')
document.write('<a id="unit-link1" href="http://www.library.cornell.edu/">Library</a>')
document.write('</div>')
document.write('</div>	')

document.write('<div id="search-form">')
// document.write('<form id="searchbox" method="get" action="http://www.cornell.edu/search" name="gs">')
// document.write('<div id="search-input">')
// 
// document.write('Search: <input id="search-form-query" type="text" class="textinput" name="q" size="20" maxlength="255" value="" />')
// document.write('<input id="search-form-submit" type="submit" class="inputsubmit"  name="sa" value="go" />')
// document.write('<input type="hidden" name="output" value="xml_no_dtd" />')
// document.write('<input type="hidden" name="client" value="default_frontend" />')
// document.write('<input type="hidden" name="proxystylesheet" value="default_frontend" />')
// document.write('</div>')
// document.write('<div id="search-filters">')
// document.write('<input id="search-filters1" checked name="as_sitesearch" type="radio" value="http://rmc.library.cornell.edu/" /><label for="search-filters1"> RMC</label>')
// document.write('<input id="search-filters2" name="as_sitesearch" type="radio" value="http://library.cornell.edu/" /><label for="search-filters2"> Cornell Library</label>')
// document.write('<input id="search-filters3" name="as_sitesearch" type="radio" value="http://cornell.edu/" /><label for="search-filters3"> Cornell</label>')
// document.write('</div>')
// document.write('</form>')
document.write('</div>')

document.write('</div>')


document.write('<p id="navbar">')

	for (var i = 1; i < topsections.length; i++){
	
		if (topsections[i].shortname == currenttopsection){
		document.write('<span class="selectednavtab"><a href="' + topsections[i].url + '">' + topsections[i].longname + '</a></span>')
		}
		else{
		document.write('<span class="unselectednavtab"><a href="' + topsections[i].url + '">' + topsections[i].longname + '</a></span>')
		}
	
	}

document.write('</p>')


}




function showtree(topsection, sublevel1, sublevel2, sublevel3){

var pagetitle = ""

// document.write('<form style="float: right;" name="querybox" action="http://www.library.cornell.edu/script/opac-redirect.php" method="get" autocomplete="OFF">')
// document.write('<a href="http://catalog.library.cornell.edu/">Library Catalog</a>: ')
// document.write('<input style="font-size: 10px;" size=10 maxlength="100" name="Search_Arg" id=searchInput>')
// document.write('<select style="font-size: 10px; margin-left: 5px;" name="Search_Code" size="1">')
// document.write('<option selected value="TALL">Title</option>')
// document.write('<option value="NAME_">Author</option>')
// document.write('<option value="SUBJ_">Subject</option>')
// document.write('<option value="FT*">Keyword</option>')
// document.write('</select>')
// document.write(' <input style="font-size: 10px;" type="submit" border="0" value="Go" name="Go"></form>')

document.write('<div id="navtree">')

	for (var i = 0; i < showtree.arguments.length; i++){
	
		if (i == 0){
		document.write('<a href="' + findsectionproperty("top", "url", showtree.arguments[i]) + '">' + findsectionproperty("top", "longname", showtree.arguments[i]) + '</a>')
		
		pagetitle =  "RMC - " + findsectionproperty("top", "longname", showtree.arguments[i])
		
		}
		else{
		
			pagetitle = pagetitle + " > " + findsectionproperty(showtree.arguments[i-1], "longname", showtree.arguments[i])
		
			if (i == showtree.arguments.length-1){
		
			document.write(' <img style="vertical-align: text-top; padding: 0px;" src="css/images/rightarrow_new.gif" width="15" height="13" alt="" /> ' + findsectionproperty(showtree.arguments[i-1], "longname", showtree.arguments[i]))
			}
			else{
	
			document.write(' <img style="vertical-align: text-top; padding: 0px;" src="css/images/rightarrow_new.gif" width="15" height="13" alt="" /> <a href="' + findsectionproperty(showtree.arguments[i-1], "url", showtree.arguments[i]) + '">' + findsectionproperty(showtree.arguments[i-1], "longname", showtree.arguments[i]) + '</a>')	
		
			}
		
		}
		
	}
	

document.write('</div>')

//document.title = fixchars(pagetitle)


}


