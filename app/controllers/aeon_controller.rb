# -*- encoding : utf-8 -*-
class AeonController < ApplicationController
  layout "aeon/index"
  include Blacklight::Catalog
  
  require 'net/sftp'
  require 'net/scp'
  require 'net/ssh'
 
  @ic = 0
  @bcc = 0
  @bibid = ""
  prelim = ""
  body = ""
  ho = ""
  submit_button = ""
  fo = ""
  bibdata = {}
  @title = ""
  author = ""
  bib_format = ""
  doctype = ""
  aeon_type = ""
  webreq = ""
  boxtype = 'radio'
  warning = ""
  holdingsHash = {}
  libid_ar = []
  @@finding_aid = ""
  sortable = []
  datable = []
  delivery_time = ""
  preview_text = "Keep this request saved in your account for later review. It will not be sent to library staff for fulfillment."
  schedule_text = 'Select a date to visit. Materials held on site are available immediately; off site items require scheduling 2 business days in advance, as indicated above. Please be sure that you choose a date when we are <a href="https://www.library.cornell.edu/libraries/rmc">open</a>.'
  quest_text = "Please email <a href=mailto:rareref@cornell.edu>rareref@cornell.edu</a> if you have any questions."
  
  bibtext = ""
  @warning = ""
  @schedule_text = ""
  @review_text = ""
  def reading_room
 
  	@url = 'www.google.com'
  end
 
 def index
 	@url = 'www.google.com'
   @review_text = "Keep this request saved in your account for later review. It will not be sent to library staff for fulfillment."
	
 end

 def reading_room_request  #rewrite of monograph.php from voy-api.library.cornell.edu
 	@title
 	@reading_room_request
 	@re506
 	libid_ar = []
 	@finding_aid = ""
 	holdingsHash = {}
	@url = 'http://www.googles.com'
	@bibid = params[:id]
	libid = params[:libid]
	if !params[:libid].nil?
		libid_ar = params[:libid].split('|')
    end
    if !params[:finding].nil?
    	@finding_aid = params[:finding]
    end
	resp, @document = search_service.fetch(params[:id])
	@bibdata = make_bibdata(@document)
	@bibdata_string = @bibdata.to_s
	@title = @document["fulltitle_display"]
	@author = @document["author_display"]
	@doctype = "Manuscript"
	@aeon_type = "GenericRequestManuscript"
	@webreq = "GenericRequestManuscript"
	holdingsJsonHash = Hash(JSON.parse(@document["holdings_json"]))
	if !@document["items_json"].nil?
	  itemsJsonHash = Hash(JSON.parse(@document["items_json"]))
	else
           itemsJsonHash = {}
        end
	@ho = holdings(holdingsJsonHash, itemsJsonHash )
	boxtype = "checkbox"
	#type = "PhotoduplicationRequest"
	#doctype = "Photoduplication"
	#webreq = "Copy"
	submitter = ""
	@this_sub = submitter
	@the_loginurl = loginurl
	if @document["restrictions_display"].nil?
		@re506 = ""
    else
	    @re506 = @document["restrictions_display"][0]
	end
    
	#@ho = "The printer & the pardoner :an unrecorded indulgence printed by William Caxton for the Hospital of St. Mary Rounceval, Charing Cross /Paul Needham.	Finding Aid" #@holdings
    @schedule_text = 'Select a date to visit. Materials held on site are available immediately; off site items require scheduling 2 business days in advance, as indicated above. Please be sure that you choose a date when we are <a href="https://www.library.cornell.edu/libraries/rmc">open</a>.'
    @review_text = 'Keep this request saved in your account for later review. It will not be sent to library staff for fulfillment.'	
	@quest_text = 'Please email <a href=mailto:rareref@cornell.edu>rareref@cornell.edu</a> if you have any questions.'
#	@the_prelim = prelim(@bibid, @title, @doctype, @webreq, @selected, @the_loginurl, @re506)
#	@warning = warning(@title)
#    @body = aeon_body(@title, @author, @aeon_type, @bibdata, @doctype, @re506)
#	the_sub = submitter
#	@clear = clearer
#	@form = former 
#	@fo = footer 
#    @all.html_safe = @the_prelim.html_safe + @warning.html_safe + @ho.html_safe + @body.html_safe + this_sub.html_safe + @clear.html_safe + @form.html_safe + @fo.html_safe
#    @all = @this_sub + @clear + @form + @fo
    session[:current_user_id] = 1
 #    File.write("#{Rails.root}/tmp/form2.html", @all)
 #    reading
 end
  
 
 
  def scan_aeon
  	libid_ar = []
  	@re506 = ""
 	finding_aid = ""
 	holdingsHash = {}
	url = 'http://www.google.com'
	@bibid = params[:id]
	libid = params[:libid]
	if !params[:libid].nil?
		libid_ar = params[:libid].split('|')
    end
    if !params[:finding].nil?
    	@@finding_aid = params[:finding]
    end
    if !params[:finding].nil?
    	@finding_aid = params[:finding]
    end

	resp, @document = search_service.fetch(params[:id])
	bibdata = make_bibdata(@document)
	@title = @document["fulltitle_display"]
	@author = @document["author_display"]
	@doctype = "Photoduplication"
	@aeon_type = "PhotoduplicationRequest"
	@webreq = "Copy"
	holdingsJsonHash = Hash(JSON.parse(@document["holdings_json"]))
	if !@document["items_json"].nil?
	 itemsJsonHash = Hash(JSON.parse(@document["items_json"]))
	else
     itemsJsonHash = {}
    end
	@ho = holdings(holdingsJsonHash, itemsJsonHash )
	boxtype = "checkbox"
	@type = "PhotoduplicationRequest"
	@doctype = "Photoduplication"
	@webreq = "Copy"
	submitter = ""
	this_sub = submitter
	@cart = selecter
	@the_loginurl = loginurl
	if @document["restrictions_display"].nil?
		@re506 = ""
    else
	    @re506 = @document["restrictions_display"][0].delete_suffix("'")
	end
    @disclaimer = "Once your order is reviewed by our staff you will then be sent an invoice. Your invoice will include information on how to pay for your order. You must pre-pay, staff cannot fulfill your request until you pay the charges."
	#@ho = "The printer & the pardoner :an unrecorded indulgence printed by William Caxton for the Hospital of St. Mary Rounceval, Charing Cross /Paul Needham.	Finding Aid" #@holdings
    @schedule_text = 'Select a date to visit. Materials held on site are available immediately; off site items require scheduling 2 business days in advance, as indicated above. Please be sure that you choose a date when we are <a href="https://www.library.cornell.edu/libraries/rmc">open</a>.'
    @review_text = 'Keep this request saved in your account for later review. It will not be sent to library staff for fulfillment.'	
	@quest_text = 'Please email <a href=mailto:rareref@cornell.edu>rareref@cornell.edu</a> if you have any questions.'
#	@the_prelim = scan_prelim(bibid, @title, @doctype, @webreq, @cart, the_loginurl, @re506)
	@warning = warning(@title)
#    @body = scan_body(@title, @author, @aeon_type, bibdata, @doctype, @re506)
#	the_sub = submitter
#	@clear = clearer
#	@form = former 
#	@fo = footer 
#    @all.html_safe = @the_prelim.html_safe + @warning.html_safe + @ho.html_safe + @body.html_safe + this_sub.html_safe + @clear.html_safe + @form.html_safe + @fo.html_safe
#    @all = @the_prelim + @warning + @ho + @body + this_sub + @clear + @form + @fo
    session[:current_user_id] = 1
#    File.write("#{Rails.root}/tmp/scan_form.html", @all)
#    scanning

  end
  
#  def request_aeon
#    #resp, document = get_solr_response_for_doc_id(params[:bibid])
    # DISCOVERYACCESS-5324 update to use BL7 search service.
#    resp, document = search_service.fetch(@id) 
#    aeon = Aeon.new
#    request_options, target, @holdings = aeon.request_aeon document, params
#    _display request_options, target, document
#  end
  
#  def _display request_options, service, doc
#    @document = doc
#    @ti = @document[:title_display]
#    @au = @document[:author_display]
#    @isbn = @document[:isbn_display]
#    @id = params[:bibid]
#    @iis = {}
#    @alternate_request_options = []
#    seen = {}
#    request_options.each do |item|
#      if item[:service] == service
#        @estimate = item[:estimate]
#        iids = item[:iid]
#        iids.each do |iid|
#          @iis[iid['itemid']] = {
#            :location => iid['location'],
#            :location_id => iid['location_id'],
#            :call_number => iid['callNumber'],
#            :copy => iid['copy'],
#            :enumeration => iid['enumeration'],
#            :url => iid['url'],
#            :chron => iid['chron'],
#            :exclude_location_id => iid['exclude_location_id']
#          }
#        end
#      else
#        if ! seen[item[:service]] || seen[item[:service]] > item[:estimate]
#          seen[item[:service]] = item[:estimate]
#        end
#      end
#    end

#    seen.each do |service, estimate|
#      @alternate_request_options.push({ :option => service, :estimate => estimate})
#    end
#    @alternate_request_options = sort_request_options @alternate_request_options
#    
#    @service = service

#    render service
#  end
  
#  def sort_request_options request_options
#    return request_options.sort_by { |option| option[:estimate] }
#  end
 
#  def prelim( bibid, title, doctype, webreq, cart, loginurl, re506)
#  	global bibid;
#	global boxtype;
#	global finding_aid;
#	delivery_time = ""
#	disclaimer = "Once your order is reviewed by our staff you will then be sent an invoice. Your invoice will include information on how to pay for your order. You must pre-pay, staff cannot fulfill your request until you pay the charges."
#    #re506 = ""
#    #webreq = ""
#	fa = '';
#	if (!@@finding_aid.empty? and @@finding_aid != '?') 
# 		fa = "
#        <a href='" + @@finding_aid + "' target='_blank'>  Finding Aid</a>
#        <br/>
#		"
#	else
#		fa = "<a href='?scan=" + params["scan"] + "' target='_blank'>Finding Aid<a/>
#		fa = "<br/>" 
#    end 
#	prelim = '
#	<!DOCTYPE html>
#	<html lang="en-US">
#	<head>
#	<title>Request for ' + title + '</title>
#	<script>var itemdata = {};</script>
#    <meta data-name="aeon_wpv" data-bn="v5.1.14" data-bid="17648" data-cid="5169011a1c864ea61424ec386d248ba1398a6730" />
#	<meta name="viewport" content="width=device-width, initial-scale=1.0">
#	<meta name="apple-mobile-web-app-capable" content="yes">
#	<meta name="apple-mobile-web-app-status-bar-style" content="default">
#	<link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css" integrity="sha384-ggOyR0iXCbMQv3Xipma34MD+dH/1fQ784/j6cY/iJTQUOhcWr7x9JvoRxT2MZw1T" crossorigin="anonymous"	
# <link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.2.0/css/all.css" integrity="sha384-hWVjflwFxL6sNzntih27bfxkr27PmbbK/iSvJ+a4+0owXq79v+lsFkW54bOGbiDQ" crossorigin="anonymous">
#<link rel="stylesheet" type="text/css" href="rmc-aeon.library.cornell.edu/aeon/css/cookieconsent.min.css" />

#<!-- Optional JavaScript -->
#<!-- jQuery first, then Popper.js, then Bootstrap JS -->

#<script src="https://code.jquery.com/jquery-3.5.1.min.js" integrity="sha256-9/aliU8dGd2tb6OSsuzixeV4y/faTqgFtohetphbbj0=" crossorigin="anonymous"></script>
#<script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.14.7/umd/popper.min.js" integrity="sha384-UO2eT0CpHqdSJQ6hJty5KVphtPhzWj9WO1clHTMGa3JDZwrnQq4sF86dIHNDz0W1" crossorigin="anonymous"></script>
#<script src="https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/js/bootstrap.min.js" integrity="sha384-JjSmVgyd0p3pXB1rRibZUAYoIIy6OrQ6VrjIEaFf/nJGzIxFDsf4x0xIM+B07jRM" crossorigin="anonymous"></script>
#<script src="https://rmc-aeon.library.cornell.edu/aeon/js/atlasUtility.js"></script>
#<script src="https://rmc-aeon.library.cornell.edu/aeon/js/custom.js"></script>
#<script src="https://cdnjs.cloudflare.com/ajax/libs/moment.js/2.22.2/moment-with-locales.min.js" integrity="sha256-VrmtNHAdGzjNsUNtWYG55xxE9xDTz4gF63x/prKXKH0=" crossorigin="anonymous"></script>
#<script src="https://cdnjs.cloudflare.com/ajax/libs/moment-timezone/0.5.21/moment-timezone-with-data.min.js" integrity="sha256-VX6SyoDzanqBxHY3YQyaYB/R7t5TpgjF4ZvotrViKAY=" crossorigin="anonymous"></script>
#<script src="https://rmc-aeon.library.cornell.edu/aeon/js/webAlerts.js"></script>
#<script src="https://rmc-aeon.library.cornell.edu/aeon/js/cookieconsent.min.js" data-cfasync="false"></script>
#<script src="https://rmc-aeon.library.cornell.edu/aeon/js/atlasCookieConsent.js"></script>
#<script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.8/jquery.min.js" ></script>
#<link rel="stylesheet" type="text/css" href="https://ajax.googleapis.com/ajax/libs/jqueryui/1.8/themes/redmond/jquery-ui.css" media="screen" />
#<script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jqueryui/1.8/jquery-ui.min.js"></script>
#<script type="text/javascript" src="https://newcatalog-login.library.cornell.edu/aeon511/js/request.js"></script>
#<link rel="stylesheet" type="text/css" href="https://newcatalog-login.library.cornell.edu/aeon/css/request.css" >
#<link rel="stylesheet" type="text/css" href="https://newcatalog-login.library.cornell.edu/aeon511/css/aeon.css" >
#<link rel="stylesheet" type="text/css" href="https://newcatalog-login.library.cornell.edu/aeon511/css/custom.css" >
#<script type="text/javascript" src="https://newcatalog-login.library.cornell.edu/aeon511/js/rmc_scripts.js"></script>
#	</head>
#	<body>
#    <header class="head">
#  <div>
#    <a href="#content" accesskey="S" onclick="$(\'#content\').focus();" class="offscreen">Skip to Main Content</a>
#  </div>
#  <div class="container">
#    <div class="cornell-logo d-none d-sm-block">
#      <a href="http://www.cornell.edu" class="insignia">Cornell University</a>
#      <div class="library-brand">
#        <a href="https://library.cornell.edu">Library</a>
#      </div>
#    </div>
#    <div class="d-block d-sm-none">
#      <a class="mobile-cornell-logo" href="https://www.cornell.edu">Cornell University</a>
#      <a class="library-brand-mobile" href="https://library.cornell.edu">Library</a>
#    </div>
#    <h1>Division of Rare and Manuscript Collections</h1>
#  </div>
#</header>

#	<div id="main-content" class="container-fluid">
#	<form id="EADRequest" name="EADRequest"
#	action="' + loginurl + '"
#              method="GET" class="form-horizontal">
#	<h4>' + title + '</h4>' + fa +
#	'<strong> ' + re506 + '</strong>' +
#	cart + '
#	<input type="hidden" id="ReferenceNumber" name="ReferenceNumber" value="' + bibid + '"/>
#	<input type="hidden" id="ItemNumber" name="ItemNumber" value=""/>
#	<input type="hidden" id="DocumentType" name="DocumentType" value="' + doctype + '"/>
#	<input type="hidden" name="WebRequestForm" value="' + webreq + '"/> '
	
#	return prelim
# end

  def scan_prelim( bibid, title, doctype, webreq, cart, loginurl, re506)
#  	global bibid;
#	global boxtype;
#	global finding_aid;
	delivery_time = ""
	disclaimer = "Once your order is reviewed by our staff you will then be sent an invoice. Your invoice will include information on how to pay for your order. You must pre-pay, staff cannot fulfill your request until you pay the charges."
    #re506 = ""
    #webreq = ""
	fa = '';
	if (!@@finding_aid.empty? and @@finding_aid != '?') 
 		fa = "
        <a href='" + @@finding_aid + "' target='_blank'>  Finding Aid</a>
        <br/>
		"
	else
#		fa = "<a href='?scan=" + params["scan"] + "' target='_blank'>Finding Aid<a/>
		fa = "<br/>"
    end 
	prelim = '
	<!DOCTYPE html>
	<html lang="en">
	<head>
	<title>Scanning Request for ' + title + '</title>
	
	<script>var itemdata = {};</script>
    <meta data-name="aeon_wpv" data-bn="v5.1.14" data-bid="17648" data-cid="5169011a1c864ea61424ec386d248ba1398a6730" />
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<meta name="apple-mobile-web-app-capable" content="yes">
	<meta name="apple-mobile-web-app-status-bar-style" content="default">
	<link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css" integrity="sha384-ggOyR0iXCbMQv3Xipma34MD+dH/1fQ784/j6cY/iJTQUOhcWr7x9JvoRxT2MZw1T" crossorigin="anonymous"	
<link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.2.0/css/all.css" integrity="sha384-hWVjflwFxL6sNzntih27bfxkr27PmbbK/iSvJ+a4+0owXq79v+lsFkW54bOGbiDQ" crossorigin="anonymous">
<link rel="stylesheet" type="text/css" href="rmc-aeon.library.cornell.edu/aeon/css/cookieconsent.min.css" />

<!-- Optional JavaScript -->
<!-- jQuery first, then Popper.js, then Bootstrap JS -->

<script src="https://code.jquery.com/jquery-3.5.1.min.js" integrity="sha256-9/aliU8dGd2tb6OSsuzixeV4y/faTqgFtohetphbbj0=" crossorigin="anonymous"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.14.7/umd/popper.min.js" integrity="sha384-UO2eT0CpHqdSJQ6hJty5KVphtPhzWj9WO1clHTMGa3JDZwrnQq4sF86dIHNDz0W1" crossorigin="anonymous"></script>
<script src="https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/js/bootstrap.min.js" integrity="sha384-JjSmVgyd0p3pXB1rRibZUAYoIIy6OrQ6VrjIEaFf/nJGzIxFDsf4x0xIM+B07jRM" crossorigin="anonymous"></script>
<script src="https://rmc-aeon.library.cornell.edu/aeon/js/atlasUtility.js"></script>
<script src="https://rmc-aeon.library.cornell.edu/aeon/js/custom.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/moment.js/2.22.2/moment-with-locales.min.js" integrity="sha256-VrmtNHAdGzjNsUNtWYG55xxE9xDTz4gF63x/prKXKH0=" crossorigin="anonymous"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/moment-timezone/0.5.21/moment-timezone-with-data.min.js" integrity="sha256-VX6SyoDzanqBxHY3YQyaYB/R7t5TpgjF4ZvotrViKAY=" crossorigin="anonymous"></script>
<script src="https://rmc-aeon.library.cornell.edu/aeon/js/webAlerts.js"></script>
<script src="https://rmc-aeon.library.cornell.edu/aeon/js/cookieconsent.min.js" data-cfasync="false"></script>
<script src="https://rmc-aeon.library.cornell.edu/aeon/js/atlasCookieConsent.js"></script>
<script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.8/jquery.min.js" ></script>
<link rel="stylesheet" type="text/css" href="https://ajax.googleapis.com/ajax/libs/jqueryui/1.8/themes/redmond/jquery-ui.css" media="screen" />
<script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jqueryui/1.8/jquery-ui.min.js"></script>
<script type="text/javascript" src="https://newcatalog-login.library.cornell.edu/aeon511/js/request.js"></script>
<link rel="stylesheet" type="text/css" href="https://newcatalog-login.library.cornell.edu/aeon/css/request.css" >
<link rel="stylesheet" type="text/css" href="https://newcatalog-login.library.cornell.edu/aeon511/css/aeon.css" >
<link rel="stylesheet" type="text/css" href="https://newcatalog-login.library.cornell.edu/aeon511/css/custom.css" >
<script type="text/javascript" src="https://newcatalog-login.library.cornell.edu/aeon511/js/rmc_scripts.js"></script>
	</head>
	<body>

    <header class="head">
  <div>
    <a href="#content" accesskey="S" onclick="$(\'#content\').focus();" class="offscreen">Skip to Main Content</a>
  </div>
  <div class="container">
    <div class="cornell-logo d-none d-sm-block">
      <a href="http://www.cornell.edu" class="insignia">Cornell University</a>
      <div class="library-brand">
        <a href="https://library.cornell.edu">Library</a>
      </div>
    </div>
    <div class="d-block d-sm-none">
      <a class="mobile-cornell-logo" href="https://www.cornell.edu">Cornell University</a>
      <a class="library-brand-mobile" href="https://library.cornell.edu">Library</a>
    </div>
    <h1>Division of Rare and Manuscript Collections</h1>
  </div>
</header>
    <h1>RMC Scanning Request</h1>
    
    <div>' + disclaimer + '</div> 
	<div id="main-content">
	<form id="RequestForm" 
	action="' + loginurl + '"
              method="GET" class="form-horizontal">
	<h4>' + title + '</h4>' + fa +
	'<strong> ' + re506 + '</strong>' +
	cart + '
	<input type="hidden" name="AeonForm" value="PhotoduplicationRequest">
	<input type="hidden" name="SkipOrderEstimate" value="Yes">
	<input type="hidden" id="ReferenceNumber" name="ReferenceNumber" value="' + bibid + '"/>
	<input type="hidden" id="ItemNumber" name="ItemNumber" value=""/>
	<input type="hidden" name="RequestType" value="Copy"/>
	<input type="hidden" id="DocumentType" name="DocumentType" value="' + doctype + '"/>
	<input type="hidden" name="FormValidationOverride" value="AllRequests">
	<input type="hidden" name="SkipFieldLengthValidation" value="yes">'
	
	
	return prelim
  end

 
  def selecter
	sel = '
	<div id="shoppingcart">
	<span id="numitems">Number of items selected:</span>
	<span id="num-selections-wrapper">
	<span id="num-selections">
	</span>
	</span>

	<div id="selections-wrapper">
	<ol><div id="selections"></div>
	</ol>
	</div>
	</div>
	'
	return sel;
  end
 
  def loginurl
#  	return "/aeon/aeon_login"
#	return "https://newcatalog-login.library.cornell.edu/aeon511/aeon_test-login.php"  	
# 	return "http://dev-jac2445.library.cornell.edu/aeon511/aeon-login.php" 
 # 	return "http://voy-api.library.cornell.edu/aeon/aeon_test-login.php"
    return "http://newcatalog-login.library.cornell.edu/aeon511_test/aeon-login.php" 
  end
 
  def warning(title)
  	w = ''
  	if title.include?('[electronic resource]')
  		w = "There is an electronic version of this resource -- do you really want to request this?"
    end
   return w
  end
 
 

  
   def clearer
   	dub = '
        <div class="control-group">
        <label class="control-label sr-only" for="SubmitButton">Submit request</label>
        <input type="submit" class="btn btn-dark" id="SubmitButton" name="SubmitButton" value="Submit Request">
        <label class="control-label sr-only" for="clear">Clear</label>
        <input type="button" class="btn btn-secondary" id="clear"  name="clear" value="Clear Form">
       	
        <br/>' + @quest_text + '<br/>
        </div>
      '
     return dub
    end  
   
  def former
  	dub = '
  	  </form>
  	 '
  	return dub
  end
 
  def submitter
  	return ""
  end
 
  def xsubmitter
  	dub = '  
        <div class="control-group">
        <div class="controls">
        <label class="control-label sr-only" for="SubmitButton">Submit request</label>
        <input type="submit" class="btn" id="SubmitButton" name="SubmitButton" value="Submit Request">
        </div>
        </div>
'
    return dub
  end
 
  def footer
    foot = '
        </div>
        </form>
        </body>
        </html>
     '
    return foot
  end
 
  def login
  	aeonParams = []
  	aeonParams = cleanupAeonParamsX #(params)
  	
  	return "woops"
  end
 
  def cleanupAeonParamsX#(params)
  	aeonParams = []
  end
 
  def redirect_shib
  	redirect_to 'https://rmc-aeon.library.cornell.edu'
  end

  def make_bibdata(document)
  	output = ""
  	holdingID = ""
  	pubplace = ""
  	publisher = ""
  	edition = ""
  	bib_format = ""
  	callNumber = ""
  	barcode = ""
  	permLocation = ""
  	permLocationCode = ""
  	status = ""
  	item_id = ""
  	if document["publisher_display"].nil?
  		publisher = ""
    else
    	publisher = document["publisher_display"][0]
    end
    if document["pub_date_display"].nil?
    	pubdate = ""
    else
    	pubdate = document["pub_date_display"][0]
    end
    if document["pubplace_display"].nil?
    	pubplace = ""
    else
    	pubplace = document["pubplace_display"][0]
    end
     	holdings_json = Hash(JSON.parse(document['holdings_json']))
  #	bibdata_hash = Hash(JSON.parse(document['holdings_json']))
  	callnum = "" #holdings_json["call"]

    firstkeyout = ""
    	count = 0
  	bibdata_output_hash = '{"items": [{"author":null,"title":null,"pub_place":null,"publisher":null,"publisher_date":null,"edition":null,"bib_format":null,"permlocation":null,"permlocationcode":null,"holdings":[]}]}'
    if !document['items_json'].nil?
  	  bibdata_hash = Hash(JSON.parse(document['items_json']))
  	  bibdata_hash.each do | firstKey, value |
  		if count == 0 
  			firstkeyout = firstKey
  			count = count + 1
  			valueHash = Hash(value[0])
 # 	        bibdata_output_hash = bibdata_output_hash + firstkeyout + '":['  	    
  	    end
  	  end
  	 end
  	if firstkeyout != ""
  	  callnum = holdings_json[firstkeyout]["call"]
  	else
  	  callnum = ""
  	end
  
    if !document['items_json'].nil?
  	  bibdata_hash.each do | key, value |
  	#	if count == 0
  		  holdingID = key
  		  valueArray = value.to_a
  		  valueArray.each do | key, hold |
  		  valueHash = Hash(hold)
  		  keyout = Hash[key]

    	  end
  	  end
  	 end   
    
    return bibdata_output_hash
  end
 
  def holdings(holdingsJsonHash, itemsJsonHash)
  	 holdingsHash = {}
  	 holdingsHash = holdingsJsonHash
  	 itemsHash = itemsJsonHash
  	 valholding = []
  	 count = 0
  	 itemsHash.each do | key, value |
  	  if count < itemsJsonHash.count
  	     if !key.nil?
  	       value.each do |val|
  	     	   if !val["enum"].nil?
  	            valholding << val #"no date"
  	           else
  	              val["enum"] = ""
  	              valholding << val
  	           end
  	       end
  	       value = valholding
               begin
  	 	  value.sort_by! { |e| e['enum'].scan(/\D+|\d+/).map { |x| x =~ /\d/ ? x.to_i : x } }
               rescue
                  value.sort_by! { |k| k["enum"]}
               end 
 	       itemsHash[key]= value  	 	
  	     end
  	     count = count + 1
  	   end
  	 end
  	 return_ho = "<div id='holdings' class='scrollable'>" + xholdings(holdingsHash, itemsHash) + "</div>"
  	 
   	 return_ho = xholdings(holdingsHash, itemsHash)
  	 return return_ho
  end
 
  def xholdings(holdingsHash, itemsHash)
  	holdHash = {}
  	ret = ""
  	holdingID = ""
    count = 0
    if !itemsHash.empty?
     itemsHash.each do |key, value|
     if count < 1
  	  holdingID = key
  	  thisItemArray = itemsHash[holdingID]
#  	  thisItemHash = Hash(JSON.parse(thisItemArray[0]))
       c = ""
       b = ""
       d = ""

  	   if !thisItemArray.nil? and !thisItemArray.empty? 
  	     thisItemArray.each do | itemHash |
  	       unless (!itemHash["location"]["code"].include?('rmc') and !itemHash["location"]["code"].include?('rare'))
  	     	b = itemHash['call'].to_s
  	     	if b.include?('Archives ')
  	     		b = b.gsub('Archives ','')
  	        end
                if itemHash["location"]["library"] == 'Library Annex'
                   itemHash["location"]["library"] = "ANNEX"
                end
  	  	 	#stuffHash = Hash(JSON.parse(otherstuff))
  	  	   	if !itemHash["copy"].nil? and !itemHash['enum'].nil?
  	  	   	  c =  " c. " + itemHash["copy"].to_s + " " + itemHash['enum']
  	  	   	  if !itemHash["caption"].nil?
  	  	   	  	c = c + " " + itemHash["caption"]
  	  	   	  end
  	  	   	end
  	  	   	if !itemHash["caption"].nil?
  	  	   	 	d = " " + itemHash["caption"]
  	  	   	else
  	  	   	 	d = ""
  	  	   	end
  	  	   	if itemHash['enum'].nil?  
  	  	   	  	itemHash['enum'] = ''
    	   	end
  	        if holdingsHash[holdingID]["call"].nil?
  	       	  holdingsHash[holdingID]["call"] = ""
  	        end 
  	  	    if !itemHash["barcode"].nil?
  	  	   	  restrictions = ""
  	  	      if !itemHash["rmc"].nil?
  	  	      	if !itemHash["rmc"]["Restrictions"].nil?
  	  	      	   restrictions = itemHash["rmc"]["Restrictions"]
  	  	      	else
  	  	      		restrictions = ""
  	  	        end
  	  	      else
  	  	      	 if !itemHash["location"].nil?
  	  	      	 	  itemHash["rmc"] = {}
  	  	      	 	  itemHash["rmc"]["Vault location"] = itemHash["location"]["code"] + ' ' + itemHash["location"]["library"]
                 else         
                      itemHash["rmc"] = {}
                      itemHash["rmc"]["Vault location"] = "Not in record"
                 end
              end  	  	   	
  	          if itemHash["location"]["name"].include?('Non-Circulating')
  	            ret = ret + "<div><label for='" + itemHash["barcode"] + "' class='sr-only'>i" + itemHash["barcode"] + "</label><input class='ItemNo'  id='" + itemHash["barcode"] + "' name='" + itemHash["barcode"] + "' type='checkbox' VALUE='" + itemHash["barcode"] + "'>"
  	        	if itemHash["rmc"].nil?
  	        	  ret = ret + " (Available Immediately) " + b +  c + " " + restrictions + '</div><script> itemdata["' + itemHash["barcode"] + '"] = { location:"' + itemHash["location"]["code"] + '",enumeration:"' + itemHash["enum"] + '",barcode:"' + itemHash["barcode"] + '",loc_code:"' + itemHash["location"]["code"] +'",chron:"",copy:"' + itemHash["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + itemHash["location"]["code"] + ' ' + itemHash["location"]["library"] + '",code:"rmc' +  '",callnumber:"' + itemHash["call"] + '",Restrictions:"' + restrictions + '"};</script>'
  	            else
  	              if itemHash["rmc"]["Vault location"].nil?
  	        	    ret = ret + " (Available Immediately) " + b +  c + " " + restrictions + '</div><script> itemdata["' + itemHash["barcode"] + '"] = { location:"' + itemHash["location"]["code"] + '",enumeration:"' + itemHash["enum"] + '",barcode:"' + itemHash["barcode"] + '",loc_code:"' + itemHash["location"]["code"] +'",chron:"",copy:"' + itemHash["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + itemHash["location"]["code"] + ' ' + itemHash["location"]["library"] + '",code:"rmc' +  '",callnumber:"' + itemHash["call"] + '",Restrictions:"' + restrictions + '"};</script>'
  	        	  else
  	        	    ret = ret + " (Available Immediately) " + b +  c + " " + restrictions + '</div><script> itemdata["' + itemHash["barcode"] + '"] = { location:"' + itemHash["rmc"]["Vault location"] + '",enumeration:"' + itemHash["enum"] + '",barcode:"' + itemHash["barcode"] + '",loc_code:"' + itemHash["rmc"]["Vault location"] +'",chron:"",copy:"' + itemHash["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + itemHash["rmc"]["Vault location"]  + '",code:"rmc' +  '",callnumber:"' + itemHash["call"] + '",Restrictions:"' + restrictions + '"};</script>'
  	        	  end  	            	
  	            end 
  	          else    
   	            ret = ret + "<div><label for='" + itemHash["barcode"] + "' class='sr-only'>" + itemHash["barcode"] + "</label><input class='ItemNo'  id='" + itemHash["barcode"] + "' name='" + itemHash["barcode"] + "' type='checkbox' VALUE='" + itemHash["barcode"] + "'>"
				if itemHash["rmc"]["Vault location"].nil?
    				ret = ret + " (Request in Advance) " + b + c + "  " + restrictions + '</div><script> itemdata["' + itemHash["barcode"] + '"] = { location:"' + itemHash["location"]["code"] + '",enumeration:"' + itemHash["enum"] + '",barcode:"' + itemHash["barcode"] + '",loc_code:"' + itemHash["location"]["code"] +'",chron:"",copy:"' + itemHash["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + itemHash["location"]["code"] + ' ' + itemHash["location"]["library"] + '",code:"rmc' +  '",callnumber:"' + itemHash["call"] + '",Restrictions:"' + restrictions + '"};</script>'
                else
    				ret = ret + " (Request in Advance) " + b + c  + " " + restrictions  +  '</div><script> itemdata["' + itemHash["barcode"] + '"] = { location:"' + itemHash["rmc"]["Vault location"] + '",enumeration:"' + itemHash["enum"] + '",barcode:"' + itemHash["barcode"] + '",loc_code:"' + itemHash["location"]["code"] +'",chron:"",copy:"' + itemHash["copy"].to_s + '",free:"",caption:"' + d + '",spine:"",cslocation:"' + itemHash["rmc"]["Vault location"] + '",code:"' + itemHash['location']["code"] + '",callnumber:"' + itemHash["call"] + '",Restrictions:"' + restrictions + '"};</script>'
				end
 	              	
  	          end
  	        else
  	       	  restrictions = ""
  	  	      if !itemHash["rmc"].nil?
  	  	      	if !itemHash["rmc"]["Restrictions"].nil?
  	  	      	   restrictions = itemHash["rmc"]["Restrictions"]
  	  	      	end
  	  	      else
  	  	      	restrictions = ""
  	  	      end
  	  	      if itemHash["rmc"].nil? 
  	  	      	itemHash["rmc"] = {}
  	  	      	if !itemHash["location"]['library'].nil?
  	  	      		itemHash['rmc']['Vault location'] = itemHash['location']['library']
  	  	      	else
  	  	      	    itemHash["rmc"]["Vault location"] = "not in record"
  	  	      	end
  	  	      end
                      if itemHash["rmc"]["Vault location"].nil?
                         itemHash["rmc"]["Vault location"] = ""
                      end                  
  	       	  if itemHash["location"]["name"].include?('Non-Circulating')
  	  #     	  	ret = itemHash["rmc"]["Vault location"]
  	           if itemHash["call"].nil?
  	           	 itemHash["call"] == ""
  	           end
  	  #THIS IS WHERE THE PROBLEM IS
  	            ret = ret + "<div><label for='iid-" + itemHash["id"].to_s + "' class='sr-only'>iid-" + itemHash["id"].to_s + "</label><input class='ItemNo'  id='iid-" + itemHash["id"].to_s + "' name='iid-" + itemHash["id"].to_s + "' type='checkbox' VALUE='iid-" + itemHash["id"].to_s + "'>"
  	        	ret = ret + " (Available Immediately) " + b + c + " " + restrictions + '</div><script> itemdata["iid-' + itemHash["id"].to_s + '"] = { location:"' + itemHash["rmc"]["Vault location"] + '",enumeration:"' + itemHash["enum"] + '",barcode:"iid-' + itemHash["id"].to_s + '",loc_code:"' + itemHash["location"]["code"] +'",chron:"",copy:"' + itemHash["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + itemHash["location"]["code"] + ' ' + itemHash["rmc"]["Vault location"] + '",code:"' + itemHash['location']["code"] + '",callnumber:"' + itemHash["call"] + '",Restrictions:"' + restrictions + '"};</script>'
  	          else
  	          	
  	        	#ret = ret + itemHash["barcode"]
  	            ret = ret + "<div><label for='iid-" + itemHash["id"].to_s + "' class='sr-only'>iid-" + itemHash["id"].to_s + "</label><input class='ItemNo'  id='iid-" + itemHash["id"].to_s + "' name='iid-" + itemHash["id"].to_s + "' type='checkbox' VALUE='iid-" + itemHash["id"].to_s + "'>"
  	        	ret = ret + " (Request in Advance) " + b + c + " " + restrictions + '</div><script> itemdata["iid-' + itemHash["id"].to_s + '"] = { location:"' + itemHash["rmc"]["Vault location"] + '",enumeration:"' + itemHash["enum"] + '",barcode:"iid-' + itemHash["id"].to_s + '",loc_code:"' + itemHash["location"]["code"] +'",chron:"",copy:"' + itemHash["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + itemHash["rmc"]["Vault location"] + '",code:"' + itemHash['location']["code"] + '",callnumber:"' + itemHash["call"] + '",Restrictions:"' + restrictions + '"};</script>'
 
 	          end
             d = ""
  	       end #barcode else
  	      end
  	     end #do end
  	    else #nil end
  	    	itemsHash = {}
  	    	valArray = []
  	    	enum = ""
  	    	restrictions = ""
  	    	if !@document["items_json"].nil?  
  	    		count = 0
  	    		itemsHash = JSON.parse(@document["items_json"])
  	    		itemsHash.each do |key, value|
  	    			if count < 1
  	    				value.each do |val|
                           if val["location"]["library"] == 'Library Annex'
                   			       val["location"]["library"] = "ANNEX"
                          end
  	    				  if !val["barcode"].nil?
  	    				  	restrictions = ""
  	    				  	if !val["rmc"].nil?
  	    				  		if !val["rmc"]["Restrictions"].nil?
  	    				  			restrictions = val["rmc"]["Restrictions"]
  	    				  		end
  	    				  	else
  	  	       		        	val["rmc"] = {}
  	  	       		          #  val["rmc"]["Vault location"].nil?
  	  	       		        	val["rmc"]["Vault location"] = "not in record"
  	  	       		        end
  	    				    if val["enum"].nil?
  	    				    	enum = ""
  	    				    else
  	    				    	enum = val["enum"]
  	    				    end
  	    				    if val["location"]["name"].include?('Non-Circulating') #or val["location"]["name"].include?('Olin Library')
  	        			#		ret = ret + val.inspect
  	            				ret = ret + "<div><label for='" + val["barcode"] + "' class='sr-only'>" + val["barcode"] + "</label><input class='ItemNo'  id='" + val["barcode"] + "' name='" + val["barcode"] + "' type='checkbox' VALUE='" + val["barcode"] + "'>"
  	        					if val["rmc"].nil?
  	        	  					ret = ret + " (Available Immediately) " + val["call"] + " c " +  val["copy"].to_s + " " + restrictions + '</div><script> itemdata["' + val["barcode"] + '"] = { location:"' + val["location"]["code"] + '",enumeration:"' + enum + '",barcode:"' + val["barcode"] + '",loc_code:"' + val["location"]["code"] +'",chron:"",copy:"' + val["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val["location"]["code"] + ' ' + val["location"]["library"] + '",code:"rmc' +  '",callnumber:"' + val["call"] + '",Restrictions:"' + restrictions + '"};</script>'
  	            				else
  	              					if val["rmc"]["Vault location"].nil?
  	        	    					ret = ret + " (Available Immediately) " + val["call"] + " c" + val["copy"].to_s + " " + restrictions + '</div><script> itemdata["' + val["barcode"] + '"] = { location:"' + val["location"]["code"] + '",enumeration:"' + enum + '",barcode:"' + val["barcode"] + '",loc_code:"' + val["location"]["code"] +'",chron:"",copy:"' + val["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val["location"]["code"] + ' ' + val["location"]["library"] + '",code:"rmc' +  '",callnumber:"' + val["call"] + '",Restrictions:"' + restrictions + '"};</script>'
  	        	  					else
  	        	    					ret = ret + " (Available Immediately) " + val["call"] + " c " + val["copy"].to_s + " " + restrictions + '</div><script> itemdata["' + val["barcode"] + '"] = { location:"' + val["rmc"]["Vault location"] + '",enumeration:"' + enum + '",barcode:"' + val["barcode"] + '",loc_code:"' + val["location"]["code"] +'",chron:"",copy:"' + val["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val["location"]["code"] + ' ' + val["location"]["library"] + '",code:"rmc' +  '",callnumber:"' + val["call"] + '",Restrictions:"' + restrictions + '"};</script>'
  	        	  					end  	            	
  	            				end 
  	          				else
  	            				ret = ret + "<div><label for='" + val["barcode"] + "' class='sr-only'>" + val["barcode"] + "</label><input class='ItemNo'  id='" + val["barcode"] + "' name='" + val["barcode"] + "' type='checkbox' VALUE='" + val["barcode"] + "'>"
  	          					if val["rmc"]["Vault location"].nil?
  	        	    				ret = ret + " (Request in Advance) " + val["call"] + " c" + val["copy"].to_s + " " + restrictions + '</div><script> itemdata["' + val["barcode"] + '"] = { location:"' + val["location"]["code"] + '",enumeration:"' + enum + '",barcode:"' + val["barcode"] + '",loc_code:"' + val["location"]["code"] +'",chron:"",copy:"' + val["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val["location"]["code"] + ' ' + val["location"]["library"] + '",code:"rmc' +  '",callnumber:"' + val["call"] + '",Restrictions:"' + restrictions + '"};</script>'
                                else
    	        					ret = ret + " (Request in Advance) " + val["call"] + " c " + val["copy"].to_s + " " + restrictions  +  '</div><script> itemdata["' + val["barcode"] + '"] = { location:"' + val["rmc"]["Vault location"] + '",enumeration:"' + enum + '",barcode:"' + val["barcode"] + '",loc_code:"' + val["location"]["code"] +'",chron:"",copy:"' + val["copy"].to_s + '",free:"",caption:"' + d + '",spine:"",cslocation:"' + val["location"]["code"] + ' ' + val["location"]["library"] + '",code:"' + val['location']["code"] + '",callnumber:"' + val["call"] + '",Restrictions:"' + restrictions + '"};</script>'
    	        				end
  	          				end

			  	        else
  	       	  				restrictions = ""
  	  	      				if !val["rmc"].nil?
  	  	      					if !val["rmc"]["Restrictions"].nil?
  	  	      	   					restrictions = val["rmc"]["Restrictions"]
  	  	      					end
  	  	      				end  	  	  
  	       	  				if val["location"]["name"].include?('Non-Circulating')
  	            				ret = ret + "<div><label for='iid-" + val["id"].to_s + "' class='sr-only'>iid-" + val["id"].to_s + "</label><input class='ItemNo'  id='iid-" + val["id"].to_s + "' name='iid-" + val["id"].to_s + "' type='checkbox' VALUE='iid-" + val["id"].to_s + "'>"
  	        					ret = ret + " (Available Immediately) " + val["call"] + " c " + val["copy"].to_s + " " + restrictions + '</div><script> itemdata["iid-' + val["id"].to_s + '"] = { location:"' + val["rmc"]["Vault location"] + '",enumeration:"' + enum + '",barcode:"iid-' + val["id"].to_s + '",loc_code:"' + val["location"]["code"] +'",chron:"",copy:"' + val["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val["location"]["code"] + ' ' + val["location"]["library"] + '",code:"' + val['location']["code"] + '",callnumber:"' + val["call"] + '",Restrictions:"' + restrictions + '"};</script>'
  	          				else
  	        					#ret = ret + itemHash["barcode"]
  	            				ret = ret + "<div><label for='iid-" + val["id"].to_s + "' class='sr-only'>iid-" + val["id"].to_s + "</label><input class='ItemNo'  id='iid-" + val["id"].to_s + "' name='iid-" + val["id"].to_s + "' type='checkbox' VALUE='iid-" + val["id"].to_s + "'>"
  	        					ret = ret + " (Requests in Advance) " + val["call"] + " c " + val["copy"].to_s + " " + restrictions + '</div><script> itemdata["iid-' + val["id"].to_s + '"] = { location:"' + val["rmc"]["Vault location"] + '",enumeration:"' + enum + '",barcode:"iid-' + val["id"].to_s + '",loc_code:"' + val["location"]["code"] +'",chron:"",copy:"' + val["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val["location"]["code"] + ' ' + val["location"]["library"] + '",code:"' + val['location']["code"] + '",callnumber:"' + val["call"] + '",Restrictions:"' + restrictions + '"};</script>'
  	          				end
			  	        end #barcode else

  	    				end
  	    			    count = count + 1
  	    		    end
  	    		end
  	    	end
  	    		
  	    end
  	 #end
  	    count = count + 1
  	    end
  	  end # end of  itemsHash.each do |key, value|
    else # if itemsHash.empty
   	    	itemsHash = {}
  	    	valArray = []
  	    	enum = ""
  	    	restrictions = ""
  	    	if !holdingsHash.nil?
  	    		count = 0
  	    		itemsHash = JSON.parse(@document["holdings_json"])
  	    	#	ret = itemsHash.inspect
  	    		itemsHash.each do |key, val|
  	    			if count < 1
  	    		#		value.each do |key, val|
  	    		#		  ret = ret + val.inspect
  	    				  if !val["barcode"].nil?
  	    				  	restrictions = ""
  	    				  	if !val["rmc"].nil?
  	    				  		if !val["rmc"]["Restrictions"].nil?
  	    				  			restrictions = val["rmc"]["Restrictions"]
  	    				  		end
  	    				  	else
  	  	       		        	val["rmc"] = {}
  	  	       		          #  val["rmc"]["Vault location"].nil?
  	  	       		        	val["rmc"]["Vault location"] = "not in record"
  	  	       		        end
  	    				    if val["enum"].nil?
  	    				    	enum = ""
  	    				    end
  	    				    if val["location"]["name"].include?('Non-Circulating')
  	            				ret = ret + "<div><label for='" + val["barcode"] + "' class='sr-only'>" + val["barcode"] + "</label><input class='ItemNo'  id='" + val["barcode"] + "' name='" + val["barcode"] + "' type='checkbox' VALUE='" + val["barcode"] + "'>"
  	        					if val["rmc"].nil?
  	        	  			#		ret = ret + val["location"]["name"] + " (Available Immediately) " + val["call"] + " c " +  val["copy"].to_s + " " + restrictions + '</div><script> itemdata["' + val["barcode"] + '"] = { location:"' + val["location"]["code"] + '",enumeration:"' + enum + '",barcode:"' + val["barcode"] + '",loc_code:"' + val["location"]["code"] +'",chron:"",copy:"' + val["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val["location"]["code"] + ' ' + val["location"]["library"] + '",code:"rmc' +  '",callnumber:"' + val["call"] + '",Restrictions:"' + restrictions + '"};</script>'
  	        	  					ret = ret + val["location"]["name"] + " (Available Immediately) " + val["call"] + " c " +  val["copy"].to_s + " " + restrictions + '</div><script> itemdata["' + val["barcode"] + '"] = { location:"' + val["location"]["code"] + '",enumeration:"' + enum + '",barcode:"' + val["barcode"] + '",loc_code:"' + val["location"]["code"] +'",chron:"",copy:"' + val["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val["location"]["code"] + ' ' + val["rmc"]["Vault location"] + '",code:"rmc' +  '",callnumber:"' + val["call"] + '",Restrictions:"' + restrictions + '"};</script>'
  	            				else
  	              					if val["rmc"]["Vault location"].nil?
  	        	    					ret = ret + " (Available Immediately) " + val["call"] + " c " + val["copy"].to_s + " " + restrictions + '</div><script> itemdata["' + val["barcode"] + '"] = { location:"' + val["location"]["code"] + '",enumeration:"' + val["enum"] + '",barcode:"' + val["barcode"] + '",loc_code:"' + val["location"]["code"] +'",chron:"",copy:"' + val["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val["location"]["code"] + ' ' + val["location"]["library"] + '",code:"rmc' +  '",callnumber:"' + val["call"] + '",Restrictions:"' + restrictions + '"};</script>'
  	        	  					else
#  	        	    					ret = ret + " (Available Immediately) " + val["call"] + " c " + val["copy"].to_s + " " + restrictions + '</div><script> itemdata["' + val["barcode"] + '"] = { location:"' + val["rmc"]["Vault location"] + '",enumeration:"' + val["enum"] + '",barcode:"' + val["barcode"] + '",loc_code:"' + val["location"]["code"] +'",chron:"",copy:"' + val["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val["location"]["code"] + ' ' + val["location"]["library"] + '",code:"rmc' +  '",callnumber:"' + val["call"] + '",Restrictions:"' + restrictions + '"};</script>'
  	        	    					ret = ret + " (Available Immediately) " + val["call"] + " c " + val["copy"].to_s + " " + restrictions + '</div><script> itemdata["' + val["barcode"] + '"] = { location:"' + val["rmc"]["Vault location"] + '",enumeration:"' + val["enum"] + '",barcode:"' + val["barcode"] + '",loc_code:"' + val["location"]["code"] +'",chron:"",copy:"' + val["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val["location"]["code"] + ' ' + val["rmc"]["Vault loation"] + '",code:"rmc' +  '",callnumber:"' + val["call"] + '",Restrictions:"' + restrictions + '"};</script>'
  	        	  					end  	            	
  	            				end 
  	          				else
  	        					#ret = ret + itemHash["barcode"]
  	            				ret = ret + "<div><label for='" + val["barcode"] + "' class='sr-only'>" + val["barcode"] + "</label><input class='ItemNo'  id='" + val["barcode"] + "' name='" + val["barcode"] + "' type='checkbox' VALUE='" + val["barcode"] + "'>"
  	        					ret = ret + " (Request in Advance) " + val["call"] + " c " + val["copy"].to_s + " " + restrictions  +  '</div><script> itemdata["' + val["barcode"] + '"] = { location:"' + val["rmc"]["Vault location"] + '",enumeration:"' + val["enum"] + '",barcode:"' + val["barcode"] + '",loc_code:"' + val["location"]["code"] +'",chron:"",copy:"' + val["copy"].to_s + '",free:"",caption:"' + d + '",spine:"",cslocation:"' + val["location"]["code"] + ' ' + val["location"]["library"] + '",code:"' + val['location']["code"] + '",callnumber:"' + val["call"] + '",Restrictions:"' + restrictions + '"};</script>'
  	          				end
                         # ret = "baby"
			  	         else
  	       	  				restrictions = ""
  	  	      				if !val["rmc"].nil?
  	  	      					if !val["rmc"]["Restrictions"].nil?
  	  	      	   					restrictions = val["rmc"]["Restrictions"]
  	  	      				    end
  	  	       		        else
  	  	       		        	val["rmc"] = {}
  	  	       		          #  val["rmc"]["Vault location"].nil?
  	  	       		        	val["rmc"]["Vault location"] = "not in record"
  	  	       		        end
  	  	       		#        ret = ret + val.inspect	  	  
  	       	  				if val["location"]["name"].include?('Non-Circulating')
  	            				ret = ret + "<div><label for='iid-" + val["hrid"].to_s + "' class='sr-only'>iid-" + val["hrid"].to_s + "</label><input class='ItemNo'  id='iid-" + val["hrid"].to_s + "' name='iid-" + val["hrid"].to_s + "' type='checkbox' VALUE='iid-" + val["hrid"].to_s + "'>"
#  	        					ret = ret + val["location"]["library"] + " (Available Immediately) " + val["call"] + " c " + val["copy"].to_s + " " + restrictions + '</div><script> itemdata["iid-' + val["hrid"].to_s + '"] = { location:"' + val["rmc"]["Vault location"] + '",enumeration:"' + enum + '",barcode:"iid-' + val["hrid"].to_s + '",loc_code:"' + val["location"]["code"] +'",chron:"",copy:"' + val["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val["location"]["code"] + ' ' + val["location"]["library"] + '",code:"' + val['location']["code"] + '",callnumber:"' + val["call"] + '",Restrictions:"' + restrictions + '"};</script>'
  	        					ret = ret + val["location"]["library"] + " (Available Immediately) " + val["call"] + " c " + val["copy"].to_s + " " + restrictions + '</div><script> itemdata["iid-' + val["hrid"].to_s + '"] = { location:"' + val["rmc"]["Vault location"] + '",enumeration:"' + enum + '",barcode:"iid-' + val["hrid"].to_s + '",loc_code:"' + val["location"]["code"] +'",chron:"",copy:"' + val["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val["location"]["code"] + ' ' + val["rmc"]["Vault location"] + '",code:"' + val['location']["code"] + '",callnumber:"' + val["call"] + '",Restrictions:"' + restrictions + '"};</script>'
  	          	 			else
  	        					#ret = ret + itemHash["barcode"]
  	            				ret = ret + "<div><label for='iid-" + val["id"].to_s + "' class='sr-only'>iid-" + val["id"].to_s + "</label><input class='ItemNo'  id='iid-" + val["id"].to_s + "' name='iid-" + val["id"].to_s + "' type='checkbox' VALUE='iid-" + val["id"].to_s + "'>"
  	    #    					ret = ret + " (Requests in Advance) " + val["call"] + " " + val["copy"].to_s + " " + restrictions + '</div><script> itemdata["iid-' + val["id"].to_s + '"] = { location:"' + val["rmc"]["Vault location"] + '",enumeration:"' + enum + '",barcode:"iid-' + val["id"].to_s + '",loc_code:"' + val["location"]["code"] +'",chron:"",copy:"' + val["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val["location"]["code"] + ' ' + val["location"]["library"] + '",code:"' + val['location']["code"] + '",callnumber:"' + val["call"] + '",Restrictions:"' + restrictions + '"};</script>'
  	        					ret = ret + " (Requests in Advance) " + val["call"] + " " + val["copy"].to_s + " " + restrictions + '</div><script> itemdata["iid-' + val["id"].to_s + '"] = { location:"' + val["rmc"]["Vault location"] + '",enumeration:"' + enum + '",barcode:"iid-' + val["id"].to_s + '",loc_code:"' + val["location"]["code"] +'",chron:"",copy:"' + val["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"' + val["location"]["code"] + ' ' + val["rmc"]["Vault location"] + '",code:"' + val['location']["code"] + '",callnumber:"' + val["call"] + '",Restrictions:"' + restrictions + '"};</script>'
  	          				end
			  	        end #barcode else

  	    		#		end
  	    			    count = count + 1
  	    		    end
  	    		end
  	    	end   	
    end #end of if itemsHash.empty
    ret = ret + "<!--Producing menu with items no need to refetch data. ic=**$ic**\n -->"
 #   ret = @document["items_json"]
   return ret 	
  end

 def aeon_login
    return params
  end

  def redirect_nonshib
 #   Rails.logger.info("BEEGER = #{params}")
  end

  def redirect_shib
        @user = User.new()
  #     @session = Session.new()
        #session.user = "jac244"
#        Rails.logger.info("SHIB = #{params}")
        uri = URI('https://rmc-aeon.library.cornell.edu/aeon/aeon.dll')
        res = Net::HTTP.get_response(uri)
 #       Rails.logger.info("COOOKIE = #{cookies.inspect}")
 #       Rails.logger.info("RESBODY= #{res.body if res.is_a?(Net::HTTPSuccess)}")
#        response = HTTParty.get('https://rmc-aeon.library.cornell.edu/aeon/boom.html?target=https://newcatalog-folio-int.library.cornell.edu')
 #       Rails.logger.info("HTTPARTY = #{response}")
 #       Rails.logger.info("COOOKIE = #{cookies.inspect}")
        @outbound_params = params
  end
  	                          
end
