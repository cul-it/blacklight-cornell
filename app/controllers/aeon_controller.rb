# -*- encoding : utf-8 -*-
class AeonController < ApplicationController
  layout "aeon"
  include Blacklight::Catalog
  
  require 'net/sftp'
  require 'net/scp'
  require 'net/ssh'
 
  ic = 0
  bcc = 0
  bibid = ""
  prelim = ""
  body = ""
  ho = ""
  submit_button = ""
  fo = ""
  bibdata = {}
  title = ""
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
  review_text = "Keep this request saved in your account for later review. It will not be sent to library staff for fulfillment."
  schedule_text = 'Select a date to visit. Materials held on site are available immediately; off site items require scheduling 2 business days in advance, as indicated above. Please be sure that you choose a date when we are <a href="https://www.library.cornell.edu/libraries/rmc">open</a>.'
  quest_text = "Please email <a href=mailto:rareref@cornell.edu>rareref@cornell.edu</a> if you have any questions."
  
  bibtext = ""
  @warning = ""
  @schedule_text = ""
  @review_text = ""
  def reading_room
 
  	@url = 'www.google.com'
  end
 
 def reading_room_request  #rewrite of monograph.php from voy-api.library.cornell.edu
 	libid_ar = []
 	finding_aid = ""
 	holdingsHash = {}
	url = 'http://www.google.com'
	bibid = params[:id]
	libid = params[:libid]
	if !params[:libid].nil?
		libid_ar = params[:libid].split('|')
    end
    if !params[:finding].nil?
    	@@finding_aid = params[:finding]
    end
	resp, @document = search_service.fetch(params[:id])
	bibdata = make_bibdata(@document)
	title = @document["fulltitle_display"]
	author = @document["author_display"]
	doctype = "Manuscript"
	aeon_type = "GenericRequestManuscript"
	webreq = "GenericRequestManuscript"
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
	this_sub = submitter
	selected = selecter
	the_loginurl = loginurl
	if @document["restrictions_display"].nil?
		re506 = ""
    else
	    re506 = @document["restrictions_display"][0]
	end
    
	#@ho = "The printer & the pardoner :an unrecorded indulgence printed by William Caxton for the Hospital of St. Mary Rounceval, Charing Cross /Paul Needham.	Finding Aid" #@holdings
    @schedule_text = 'Select a date to visit. Materials held on site are available immediately; off site items require scheduling 2 business days in advance, as indicated above. Please be sure that you choose a date when we are <a href="https://www.library.cornell.edu/libraries/rmc">open</a>.'
    @review_text = 'Keep this request saved in your account for later review. It will not be sent to library staff for fulfillment.'	
	@quest_text = 'Please email <a href=mailto:rareref@cornell.edu>rareref@cornell.edu</a> if you have any questions.'
	@the_prelim = prelim(bibid, title, doctype, webreq, selected, the_loginurl, re506)
	@warning = warning(title)
    @body = aeon_body(title, author, aeon_type, bibdata, doctype, re506)
#	the_sub = submitter
	@clear = clearer
	@form = former 
	@fo = footer 
#    @all.html_safe = @the_prelim.html_safe + @warning.html_safe + @ho.html_safe + @body.html_safe + this_sub.html_safe + @clear.html_safe + @form.html_safe + @fo.html_safe
    @all = @the_prelim + @warning + @ho + @body + this_sub + @clear + @form + @fo
    session[:current_user_id] = 1
     File.write("#{Rails.root}/tmp/form2.html", @all)
     reading
 end
  
  def reading
  	file = File.read("#{Rails.root}/tmp/form2.html")
  	render :html => file.html_safe
  end
 
  def scanning
  	file = File.read("#{Rails.root}/tmp/scan_form.html")
  	render :html => file.html_safe
  end
 
  def scan_aeon
  	libid_ar = []
 	finding_aid = ""
 	holdingsHash = {}
	url = 'http://www.google.com'
	bibid = params[:id]
	libid = params[:libid]
	if !params[:libid].nil?
		libid_ar = params[:libid].split('|')
    end
    if !params[:finding].nil?
    	@@finding_aid = params[:finding]
    end
	resp, @document = search_service.fetch(params[:id])
	bibdata = make_bibdata(@document)
	title = @document["fulltitle_display"]
	author = @document["author_display"]
	doctype = "Photoduplication"
	aeon_type = "PhotoduplicationRequest"
	webreq = "Copy"
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
	this_sub = submitter
	selected = selecter
	the_loginurl = loginurl
	if @document["restrictions_display"].nil?
		re506 = ""
    else
	    re506 = @document["restrictions_display"][0]
	end
	#@ho = "The printer & the pardoner :an unrecorded indulgence printed by William Caxton for the Hospital of St. Mary Rounceval, Charing Cross /Paul Needham.	Finding Aid" #@holdings
    @schedule_text = 'Select a date to visit. Materials held on site are available immediately; off site items require scheduling 2 business days in advance, as indicated above. Please be sure that you choose a date when we are <a href="https://www.library.cornell.edu/libraries/rmc">open</a>.'
    @review_text = 'Keep this request saved in your account for later review. It will not be sent to library staff for fulfillment.'	
	@quest_text = 'Please email <a href=mailto:rareref@cornell.edu>rareref@cornell.edu</a> if you have any questions.'
	@the_prelim = scan_prelim(bibid, title, doctype, webreq, selected, the_loginurl, re506)
	@warning = warning(title)
    @body = scan_body(title, author, aeon_type, bibdata, doctype, re506)
#	the_sub = submitter
	@clear = clearer
	@form = former 
	@fo = footer 
#    @all.html_safe = @the_prelim.html_safe + @warning.html_safe + @ho.html_safe + @body.html_safe + this_sub.html_safe + @clear.html_safe + @form.html_safe + @fo.html_safe
    @all = @the_prelim + @warning + @ho + @body + this_sub + @clear + @form + @fo
    session[:current_user_id] = 1
    File.write("#{Rails.root}/tmp/scan_form.html", @all)
    scanning

  end
  
  def request_aeon
    #resp, document = get_solr_response_for_doc_id(params[:bibid])
    # DISCOVERYACCESS-5324 update to use BL7 search service.
    resp, document = search_service.fetch(@id) 
    aeon = Aeon.new
    request_options, target, @holdings = aeon.request_aeon document, params
    _display request_options, target, document
  end
  
  def _display request_options, service, doc
    @document = doc
    @ti = @document[:title_display]
    @au = @document[:author_display]
    @isbn = @document[:isbn_display]
    @id = params[:bibid]
    @iis = {}
    @alternate_request_options = []
    seen = {}
    request_options.each do |item|
      if item[:service] == service
        @estimate = item[:estimate]
        iids = item[:iid]
        iids.each do |iid|
          @iis[iid['itemid']] = {
            :location => iid['location'],
            :location_id => iid['location_id'],
            :call_number => iid['callNumber'],
            :copy => iid['copy'],
            :enumeration => iid['enumeration'],
            :url => iid['url'],
            :chron => iid['chron'],
            :exclude_location_id => iid['exclude_location_id']
          }
        end
      else
        if ! seen[item[:service]] || seen[item[:service]] > item[:estimate]
          seen[item[:service]] = item[:estimate]
        end
      end
    end

    seen.each do |service, estimate|
      @alternate_request_options.push({ :option => service, :estimate => estimate})
    end
    @alternate_request_options = sort_request_options @alternate_request_options
    
    @service = service

    render service
  end
  
  def sort_request_options request_options
    return request_options.sort_by { |option| option[:estimate] }
  end
 
  def prelim( bibid, title, doctype, webreq, cart, loginurl, re506)
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
	<title>Request for ' + title + '</title>
	<script>var itemdata = {};</script>
	<script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.8/jquery.min.js" ></script>
	<link rel="stylesheet" type="text/css" href="https://ajax.googleapis.com/ajax/libs/jqueryui/1.8/themes/redmond/jquery-ui.css" media="screen" />
	<script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jqueryui/1.8/jquery-ui.min.js"></script>
	<link rel="stylesheet" type="text/css" href="https://newcatalog-login.library.cornell.edu/aeon/css/bootstrap.min.css">
	<script type="text/javascript" src="https://newcatalog-login.library.cornell.edu/aeon/date.js"></script>
	<script type="text/javascript" src="https://newcatalog-login.library.cornell.edu/aeon/js/request.js"></script>
	<link rel="stylesheet" type="text/css" href="https://newcatalog-login.library.cornell.edu/aeon/css/request.css" >
	<script type="text/javascript" src="https://newcatalog-login.library.cornell.edu/aeon/js/rmc_scripts.js"></script>
	</head>
	<body>
	<script type="text/javascript">
	<!--
	showheader("find")
	//-->
	</script>


	<div id="main-content">
	<form id="EADRequest" name="EADRequest"
	action="' + loginurl + '"
              method="POST" class="form-horizontal">
	<b>' + title + '</b>' + fa +
	'<b> ' + re506 + '</b>' +
	cart + '
	<input type="hidden" id="ReferenceNumber" name="ReferenceNumber" value="' + bibid + '"/>
	<input type="hidden" id="ItemNumber" name="ItemNumber" value=""/>
	<input type="hidden" id="DocumentType" name="DocumentType" value="' + doctype + '"/>
	<input type="hidden" name="WebRequestForm" value="' + webreq + '"/> '
	
	return prelim
  end

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
	<script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.8/jquery.min.js" ></script>
	<link rel="stylesheet" type="text/css" href="https://ajax.googleapis.com/ajax/libs/jqueryui/1.8/themes/redmond/jquery-ui.css" media="screen" />
	<script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jqueryui/1.8/jquery-ui.min.js"></script>
	<link rel="stylesheet" type="text/css" href="https://newcatalog-login.library.cornell.edu/aeon/css/bootstrap.min.css">
	<script type="text/javascript" src="https://newcatalog-login.library.cornell.edu/aeon/date.js"></script>
	<script type="text/javascript" src="https://newcatalog-login.library.cornell.edu/aeon/js/repro_request.js"></script>
	<link rel="stylesheet" type="text/css" href="https://newcatalog-login.library.cornell.edu/aeon/css/repro.css" >
	<script type="text/javascript" src="https://newcatalog-login.library.cornell.edu/aeon/js/rmc_scripts.js"></script>
	</head>
	<body>
	<script type="text/javascript">
	<!--
	showheader("find")
	//-->
	</script>

    <h1>RMC Scanning Request</h1>
    
    <div>' + disclaimer + '</div> 
	<div id="main-content">
	<form id="RequestForm" 
	action="' + loginurl + '"
              method="GET" class="form-horizontal">
	<h2>' + title + '</h2>' + fa +
	'<b> ' + re506 + '</b>' +
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
	<span id="numitems" >&nbsp;Number of items selected:</span>
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
 	return "https://newcatalog-login.library.cornell.edu/aeon/aeon-login.php"  	
#   	return "http://dev-jac244.library.cornell.edu/aeon/aeon-login.php"
  #	return "http://voy-api.library.cornell.edu/aeon/aeon_test-login.php"
  end
 
  def warning(title)
  	w = ''
  	if title.include?('[electronic resource]')
  		w = "There is an electronic version of this resource -- do you really want to request this?"
    end
   return w
  end
 
  def aeon_body(title, author, type, bibdata, doctype, re506)
  	if author.nil?
  		author = ""
    end

  	body = '
        <script> var bibdata = ' + bibdata.to_s  + '; </script>
        <div class="control-group">
        <div class="controls"><input type="hidden" id="Restrictions" name="Restrictions" value="' + re506 + '"/>
        </div>
        </div>
        <div class="control-group">
        <div class="controls"><input type="hidden" id="ItemInfo3" name="ItemInfo3" value="' + re506 + '"/>
        </div>
        </div>
        <div class="control-group">
        <div class="controls"><input type="hidden" id="ItemInfo5" name="ItemInfo5" value=""/>
        </div>
        </div>
        <div class="control-group">
        <div class="controls"><div id="Warningdis" name="Warningdis">' + @warning + '</div>
        <div><input type="hidden" id="AeonForm" name="AeonForm" value="' + type + '"/></div>
        <div class="row-fluid">
<div id="noshow">
        <div class="control-group">
        <label class="control-label" for="ItemTitle" >Title</label>
        <div class="controls"><textarea id="ItemTitle" name="ItemTitle">' + title + '</textarea>
        </div>
        </div>
        <div class="control-group">
        <label class="control-label">CallNumber</label>
        <div class="controls">
        <input type="text" id="CallNumber" name="CallNumber" value="">
        </div>
        </div>
        <div class="control-group">
        <label class="control-label">Box or item number(s)</label>
        <div class="controls">
        <input type="text" id="ItemVolume" name="ItemVolume" value="">
        </div>
        </div>
        <div class="control-group">
        <label class="control-label">Author</label>
        <div class="controls">
        <input type="text" name="ItemAuthor" value="' + author + '">
        </div>
        </div>
        <div class="control-group">
        <label class="control-label">Place of Publication</label>
        <div class="controls">
        <input type="text" id="ItemPlace" name="ItemPlace" value="">
        </div>
        </div>
        <div class="control-group">
        <label class="control-label">Publisher</label>
        <div class="controls">
        <input type="text" id="ItemPublisher" name="ItemPublisher" value=""/>
        </div>
        </div>
        <div class="control-group">
        <label class="control-label">Date</label>
        <div class="controls">
        <input type="text" id="ItemDate" name="ItemDate" value="">
        </div>
        </div>
        <div class="control-group">
        <label class="control-label">Edition</label>
        <div class="controls">
        <input type="text" id="ItemEdition" name="ItemEdition" value="">
        </div>
        </div>
        <div class="control-group">
        <label class="control-label">Location</label>
        <div class="controls">
        <input type="text" id="Location" name="Location" value="">
        </div>
        </div>
        <div class="control-group">
        <label class="control-label">Copy</label>
        <div class="controls">
        <input type="text" id="ItemIssue" name="ItemIssue" value="">
        </div>
        </div>
</div> <!-- id=noshow -->
        <div class="control-group">
           <label class="control-label"><b>Schedule or Save</b></label>
           <p>You may schedule a date to visit or save your request to review and schedule a visit later.</>
        </div>
        <div class="control-group">
          <input id="UserReview" name="UserReview" type="radio" value="Yes">
          <label class="control-label">Keep this request saved in your account for later review. It will not be sent to library staff for fulfillment.</label>
          <br/>
          <input id="UserDate" name="UserDate" type="radio" value="Yes">
          <label class="control-label">' + @schedule_text + '</label>
        </div>
        <div class="control-group">
        <input id="ScheduledDate" name="ScheduledDate" type="text" value="Select date">
        <label class="control-label">
        <span id="ScheduledText"></span></label>
        <div class="controls">
        </div>
        </div>

        <!-- <div class="control-group">
        <label class="control-label">
        <span id="ReviewText">' + @review_text + '</span></label>
        </div> -->
        </div>

                        
'
   return body
   end  

  def scan_body(title, author, type, bibdata, doctype, re506)
  	 if author.nil?
  	 	author = ""
  	 end

  	body = '
        <script> var bibdata = ' + bibdata.to_s  + '; </script>
        <div class="control-group">
        <div class="controls"><input type="hidden" id="Restrictions" name="Restrictions" value="' + re506 + '"/>
        </div>
        </div>
        <div class="control-group">
        <div class="controls"><input type="hidden" id="ItemInfo3" name="ItemInfo3" value="' + re506 + '"/>
        </div>
        </div>
        <div class="control-group">
        <div class="controls"><input type="hidden" id="ItemInfo5" name="ItemInfo5" value=""/>
        </div>
        </div>
        <div class="control-group">
        <div class="controls"><div id="Warningdis" name="Warningdis">' + @warning + '</div>
        <div><input type="hidden" id="AeonForm" name="AeonForm" value="' + type + '"/></div>
        <label for="Format">
        <span class="field">
        <span class="req">*</span>
        <span class="valid">
        <span class="bold">Format</span>
        </span>
        </span>
        <select id="Format" name="Format" size="1" class="f-name" tabindex="0">
        <option>a. PDF: $1</option>
        <option>b. TIFF 600 dpi: $35</option>
        <option>c. TIFF 600 dpi > 12x17: $45</option>
        <option>d. MP3 of audio: $75</option>
        <option>e. MP4 of video: $75</option>
        <option>f. MP4 of film: $200</option>
        <option>g. PDF of microfilm: $50</option>
        <option>h. PDF of thesis: $50</option>
        <option>i. Existing digital file: $10</option>
        </select>
        </label>
        <label for="ServiceLevel">
        <span class="field">
        <span class="req">*</span>
        <span class="valid">
        <span class="bold">Service Level</span>
        </span>
        </span>
        <select id="ServiceLevel" name="ServiceLevel" size="1" class="f-name" tabindex="0">
        <option>"a. Normal: $15"</option>
        <option>("b. Rush < 3 weeks: $40")</option>
        </select>
        </label>
        <label for="ShippingOption">
        <span class="field"> <span class="req">*</span>  
        <span class="valid"><span class="bold">Delivery Method</span></span> </span>
	    <select id="ShippingOption" name="ShippingOption" size="1" class="f-name" tabindex="0">
		<option>a. Digital file download: $0"<option>
		</select>
		</label>
		<br />
		<label for="Special Request"> 
  		  <span class="field"> 
    		<span class="valid">
      			<span class="bold">Date Needed/Special Requests/Questions?
      			Please enter any deadlines, special requests or questions for library staff. 
     			</span>
  			</span>
		<br/>
  		<textarea area id="SpecialRequest"  rows="2" cols="40" class="f-name" tabindex="0"></textarea>
		</label>        
		<br />
		<label for="Notes">
  			<span class="field">
    			<span class="valid"><span class="bold">Reference Notes</span></span><br />
  				<span class="note">You can use this field to add any notes about this item or request that may be helpful for your own personal reference later.</span>
  			</span>
  		<br/>
  		<textarea id="Notes" name="Notes" maxlength ="255" rows="2" cols="40" class="f-name" tabindex="0"></textarea><br />
		</label>
		<label for="ItemCitation">
  			<span class="field">
    			<span class="valid"><span class="bold">Online Image Citation</span>
    		</span>
    	<br /> 
  		<span class="note">If you have seen the image you are requesting online, type the URL here. You may also enter an image ID # if known. </span>
  		</span>
  		<br/>
  		<textarea id="ItemCitation" name="ItemCitation" maxlength ="255" rows="2" cols="40" class="f-name" tabindex="0"></textarea><br />
		</label>
		<label for="PageCount">
  		<span class="field">
    	<span class="valid"><span class="bold">Page Count, if Known</span></span><br />
  		</span>
  		<br/>
  		<textarea id="PageCount" name="PageCount" maxlength ="255" rows="2" cols="40" class="f-name" tabindex="0"></textarea><br />
		</label>    			
    			    			       
        <div class="row-fluid">
<div id="noshow">
        <div class="control-group">
        <label class="control-label" for="ItemTitle" >Title</label>
        <div class="controls"><textarea id="ItemTitle" name="ItemTitle">' + title + '</textarea>
        </div>
        </div>
        <div class="control-group">
        <label class="control-label">CallNumber</label>
        <div class="controls">
        <input type="text" id="CallNumber" name="CallNumber" value="">
        </div>
        </div>
        <div class="control-group">
        <label class="control-label">Box or item number(s)</label>
        <div class="controls">
        <input type="text" id="ItemVolume" name="ItemVolume" value="">
        </div>
        </div>
        <div class="control-group">
        <label class="control-label">Author</label>
        <div class="controls">
        <input type="text" name="ItemAuthor" value="' + author + '">
        </div>
        </div>
        <div class="control-group">
        <label class="control-label">Place of Publication</label>
        <div class="controls">
        <input type="text" id="ItemPlace" name="ItemPlace" value="">
        </div>
        </div>
        <div class="control-group">
        <label class="control-label">Publisher</label>
        <div class="controls">
        <input type="text" id="ItemPublisher" name="ItemPublisher" value=""/>
        </div>
        </div>
        <div class="control-group">
        <label class="control-label">Date</label>
        <div class="controls">
        <input type="text" id="ItemDate" name="ItemDate" value="">
        </div>
        </div>
        <div class="control-group">
        <label class="control-label">Edition</label>
        <div class="controls">
        <input type="text" id="ItemEdition" name="ItemEdition" value="">
        </div>
        </div>
        <div class="control-group">
        <label class="control-label">Location</label>
        <div class="controls">
        <input type="text" id="Location" name="Location" value="">
        </div>
        </div>
        <div class="control-group">
        <label class="control-label">Copy</label>
        <div class="controls">
        <input type="text" id="ItemIssue" name="ItemIssue" value="">
        </div>
        </div>
</div> <!-- id=noshow -->

        <!-- <div class="control-group">
        <label class="control-label">
        <span id="ReviewText">' + @review_text + '</span></label>
        </div> -->
        </div>

                        
'
   return body
   end  

  
   def clearer
   	dub = '
        <div class="control-group">
        <label class="control-label">
        <input type="submit" class="btn" id="SubmitButton" name="SubmitButton" value="Submit Request">
        </label>
        <input type="button" class="btn" id="clear"  name="clear" value="Clear Form">
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
  	#	 status = keyout["status"]["code"]["1"]
  	#	 bibdata_output_hash = bibdata_output_hash + '{"author":"' + document["author_display"] + '","title":"' + document["fulltitle_display"] + '","publisher":"' + publisher + '","publisher_date":"' + pubdate + '","pub_place":"' + pubplace + '","bib_format":"' + bib_format + '","holding_id":"' + holdingID + '","call_number":"' + callnum.inspect + '","barcode":"' + keyout['barcode'].inspect + '","PermLocation":"' + permLocation + '","PermLocationCode":"' + permLocationCode + '","status":"' + status + '","item_id":"' + keyout['id'].inspect + '"},'

    	  end
  #	    count = count + 1
  #	    if count > 1
  #	    end	
  	  end
  	 end   
  #  bibdata_output_hash = bibdata_output_hash + '}} ]}'
    
    return bibdata_output_hash
  end
 
  def holdings(holdingsJsonHash, itemsJsonHash)
  	 holdingsHash = holdingsJsonHash
  	 itemsHash = itemsJsonHash
   	 return_ho = "<div id='holdings' class='scrollable'>" + xholdings(holdingsHash, itemsHash) + "</div>"
  	 return return_ho
  end
 
  def xholdings(holdingsHash, itemsHash)
  	holdHash = {}
  	ret = ""
  	holdingID = ""
    
  	holdingsHash.each do |key, value|
  	  holdingID = key
  	  thisItemArray = itemsHash[holdingID]
#  	  thisItemHash = Hash(JSON.parse(thisItemArray[0]))
       c = ""
       b = ""
       d = ""
#       if holdingsHash[holdingID]["call"].include?('Archives')
#       	  b = holdingsHash[holdingID]["call"].split(' ')[1]
#       else
#       	  b = holdingsHash[holdingID]["call"]
#       end
  	   if !thisItemArray.nil?  
  	     thisItemArray.each do | itemHash |
  	     	b = itemHash['call'].to_s
  	     	if b.include?('Archives ')
  	     		b = b.gsub('Archives ','')
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
  	  	   	Rails.logger.info("SPARKY = #{itemHash}")
  	  	   	  restrictions = ""
  	  	      if !itemHash["rmc"].nil?
  	  	      	if !itemHash["rmc"]["Restrictions"].nil?
  	  	      	   restrictions = itemHash["rmc"]["Restrictions"]
  	  	      	end
  	  	      end  	  	   	
  	          if itemHash["location"]["name"].include?('Non-Circulating')
  	            ret = ret + " <div> <div><input class='ItemNo'  id='" + itemHash["barcode"] + "' name='" + itemHash["barcode"] + "' type='checkbox' VALUE='" + itemHash["barcode"] + "'>"
  	        	ret = ret + " (Available Immediately) " + b +  c + " " + restrictions + '</div></div><script> itemdata["' + itemHash["barcode"] + '"] = { location:"' + itemHash["location"]["code"] + '",enumeration:"' + itemHash["enum"] + '",barcode:"' + itemHash["barcode"] + '",loc_code:"' + itemHash["location"]["code"] +'",chron:"",copy:"' + itemHash["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"rmc ",code:"rmc' +  '",callnumber:"' + itemHash["call"] + '",Restrictions:"' + restrictions + '"};</script>'
  	          else
  	        	#ret = ret + itemHash["barcode"]
  	            ret = ret + " <div> <div><input class='ItemNo'  id='" + itemHash["barcode"] + "' name='" + itemHash["barcode"] + "' type='checkbox' VALUE='" + itemHash["barcode"] + "'>"
  	        	ret = ret + " (Request in Advance) " + b + c + " " + restrictions  +  '</div></div><script> itemdata["' + itemHash["barcode"] + '"] = { location:"' + itemHash["location"]["code"] + '",enumeration:"' + itemHash["enum"] + '",barcode:"' + itemHash["barcode"] + '",loc_code:"' + itemHash["location"]["code"] +'",chron:"",copy:"' + itemHash["copy"].to_s + '",free:"",caption:"' + d + '",spine:"",cslocation:"rmc ",code:"' + itemHash['location']["code"] + '",callnumber:"' + holdingsHash[holdingID]["call"] + '",Restrictions:"' + restrictions + '"};</script>'
  	          end
  	       else
  	       	 Rails.logger.info("SPARKY1 = #{itemHash}")
  	       	  restrictions = ""
  	  	      if !itemHash["rmc"].nil?
  	  	      	if !itemHash["rmc"]["Restrictions"].nil?
  	  	      	   restrictions = itemHash["rmc"]["Restrictions"]
  	  	      	end
  	  	      end  	  	  
  	       	  if itemHash["location"]["name"].include?('Non-Circulating')
  	            ret = ret + " <div> <div><input class='ItemNo'  id='iid-" + itemHash["id"].to_s + "' name='iid-" + itemHash["id"].to_s + "' type='checkbox' VALUE='iid-" + itemHash["id"].to_s + "'>"
  	        	ret = ret + " (Available Immediately) " + b + c + " " + restrictions + '</div></div><script> itemdata["iid-' + itemHash["id"].to_s + '"] = { location:"' + itemHash["location"]["code"] + '",enumeration:"' + itemHash["enum"] + '",barcode:"iid-' + itemHash["id"].to_s + '",loc_code:"' + itemHash["location"]["code"] +'",chron:"",copy:"' + itemHash["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"rmc ",code:"' + itemHash['location']["code"] + '",callnumber:"' + holdingsHash[holdingID]["call"] + '",Restrictions:"' + restrictions + '"};</script>'
  	          else
  	        	#ret = ret + itemHash["barcode"]
  	            ret = ret + " <div> <div><input class='ItemNo'  id='iid-" + itemHash["id"].to_s + "' name='iid-" + itemHash["id"].to_s + "' type='checkbox' VALUE='iid-" + itemHash["id"].to_s + "'>"
  	        	ret = ret + " (Requests in Advance) " + b + c + " " + restrictions + '</div></div><script> itemdata["iid-' + itemHash["id"].to_s + '"] = { location:"' + itemHash["location"]["code"] + '",enumeration:"' + itemHash["enum"] + '",barcode:"iid-' + itemHash["id"].to_s + '",loc_code:"' + itemHash["location"]["code"] +'",chron:"",copy:"' + itemHash["copy"].to_s + '",free:"",caption:"",spine:"",cslocation:"rmc ",code:"' + itemHash['location']["code"] + '",callnumber:"' + holdingsHash[holdingID]["call"] + '",Restrictions:"' + restrictions + '"};</script>'
  	          end
             d = ""
  	       end
  	     end
  	    end
  	 #end
  	end
    ret = ret + "<!--Producing menu with items no need to refetch data. ic=**$ic**\n -->"
   return ret 	
  end

  	                          
end
