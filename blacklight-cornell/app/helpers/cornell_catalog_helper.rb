# froozen_string_literal: true
module CornellCatalogHelper
 require "pp"
 require "maybe"
 require "htmlentities"
 require "date"
# require 'pry'
# require 'pry-byebug'

  # In Rails 5 ActionController::Params are an object, so to_h is needed. But in some cases the session contains params that
  # are already a hash. So we need the check. Probably better to do this where the params are getting added to the search.
  def session_params_for_search(session_params)
    session_params.each do |key, value|
      session_params[key] = value.to_h if value.present? && value.is_a?(ActionController::Parameters)
    end
    session_params
  end

  # Determine if user query can be expanded to WCL & Summon
  def expandable_search?
    params[:q].present? && !advanced_search? && !params[:click_to_search]
  end

  def advanced_search?
    params[:q_row].present? || params[:f_inclusive].present?
  end

  def process_online_title(title)
    # Trim leading and trailing text
    # Reformat coverage dates to simply mm/yy (drop day) and wrap in span for display
    title_dirty = ERB::Util.html_escape(title)
    title_clean = title_dirty.to_s.gsub(/^Full text available from /, '').gsub(/(\d{1,2})\/\d{1,2}(\/\d{4})/, '\1\2').gsub(/\sConnect to (full )?text\.$/, '').gsub(/(:\s)(.*)/, ' <span class="online-coverage">(\2)</span>')
    # Address the Factiva links that come with a lengthy note
    title_clean.to_s.gsub(/(Please check resource for coverage or contact a librarian for assistance.)$/, '<span class="online-note">\1</span>').html_safe
  end

	def facet_field_labels
	# this was D*EPRECATED
		Hash[*blacklight_config.facet_fields.map { |key, facet| [key, facet.label] }.flatten]
	end

	def  cornell_item_page_entry_info
	if search_session['counter'].nil?
		search_session['counter'] = 1
	end
	t('blacklight.search.entry_pagination_info.other',
		:current => number_with_delimiter(search_session['counter']), :total => number_with_delimiter(search_session[:total]),
		:count => search_session[:total].to_i).html_safe
	end

	LOC_CODES = {
	"afr"=>"Africana Library (Africana Center)",
	"afr,anx"=>"Library Annex",
	"afr,res"=>"Africana Library Reserve",
	"afr,ref"=>"Africana Library Reference ( Non-Circulating)",
	"asia,av"=>"Uris Library Asia A/V",
	"cise"=>"CISER Data Archive",
	"cons"=>"Preservation Department (B32 Olin)",
	"cons,opt"=>"",
	"ech"=>"Kroch Library Asia",
	"ech,anx"=>"Library Annex",
	"ech,av"=>"Uris Library Asia A/V",
	"ech,ref"=>"Kroch Library Asia Reference (Non-Circulating)",
	"engr"=>"Library Annex",
	"engr,anx"=>"Library Annex",
	"engr,base"=>"Library Annex",
	"engr,res"=>"Library Annex",
	"ent"=>"Entomology Library (Comstock Hall)",
	"ent,anx"=>"Library Annex",
	"ent,rare"=>"Entomology Library Rare (Non-Circulating)",
	"ent,ref"=>"Entomology Library Reference (Non-Circulating)",
	"fine"=>"Fine Arts Library (Rand Hall)",
	"fine,res"=>"Fine Arts Library Reserve",
	"fine,lock"=>"Fine Arts Library (Ask at Circulation)",
	"fine,ref"=>"Fine Arts Library Reference (Non-Circulating)",
	"gnva"=>"Geneva Experiment Station Library",
	"gnva,anx"=>"Library Annex",
	"gnva,ref"=>"Geneva Library Reference (Non-Circulating)",
	"hote,anx"=>"Library Annex",
	"hote,rare"=>"Kroch Library Rare & Manuscripts (Non-Circulating)",
	"hote,ref"=>"ILR Library Reference (Non-Circulating)",
	"rmc,anx"=>"Kroch Library Rare & Manuscripts Reference (Request in advance)",
	"rmc,ref"=>"Kroch Library Rare & Manuscripts Reference (Non-Circulating)",
	"rmc,ice"=>"Olin Library",
	"ilr"=>"ILR Library (Ives Hall)",
	"ilr,anx"=>"Library Annex",
	"ilr,ref"=>"ILR Library Reference (Non-Circulating)",
	"ilr,kanx"=>"ILR Library Kheel Center (Request in advance)",
	"ilr,lmdr"=>"ILR Library Kheel Center Reference",
	"ilr,rare"=>"ILR Library Kheel Center",
	"jgsm"=>"ILR Library (Ives Hall)",
	"jgsm,anx"=>"Library Annex",
	"jgsm,res"=>"Sage Hall Management Library Reserve",
	"law"=>"Law Library (Myron Taylor Hall)",
	"law,lega"=>"Legal Aid Clinic",
	"law,ts"=>"Law Library Technical Services",
	"mann"=>"Mann Library",
	"mann,ts"=>"Mann Library Technical Services (Non-Circulating)",
	"mann,anx"=>"Library Annex",
	"mann,anxt"=>"Library Annex",
	"mann,spec"=>"Mann Library Special Collections (Non-Circulating)",
	"mann,cd"=>"Mann Library Collection Development (Non-Circulating)",
	"mann,ref"=>"Mann Library Reference (Non-Circulating)",
	"mann,gate"=>"Networked Resource",
	"mann,res"=>"Mann Library Reserve",
	"math"=>"Mathematics Library (Malott Hall)",
	"math,desk"=>"Mathematics Library (Circulation Desk)",
	"math,ref"=>"Mathematics Library Reference (Non-Circulating)",
	"math,res"=>"Mathematics Library Reserve",
	"mus,anx"=>"Library Annex",
	"mus,lock"=>"Music Library Locked Press (Reference Desk)",
	"mus,ref"=>"Music Library Reference (Non-Circulating)",
	"nus"=>"",
	"oclc,afrp"=>"Africana Library Reserve",
	"oclc,olim"=>"Olin Library",
	"oclc,olir"=>"Olin Library Reference (Non-Circulating)",
	"olin"=>"Olin Library",
	"cts"=>"",
	"olin,str1"=>"Request at Olin Circulation Desk",
	"olin,ref"=>"Olin Library Reference (Non-Circulating)",
	"olin,301"=>"Olin Library Room 301 (Non-Circulating)",
	"olin,404"=>"Olin Library Room 404 (Non-Circulating)",
	"olin,405"=>"Olin Library Room 405 (Non-Circulating)",
	"orni"=>"Adelson Library (Lab of Ornithology)",
	"phys"=>"Physical Sciences Library (Clark Hall)",
	"phys,anx"=>"Library Annex",
	"phys,ref"=>"Physical Sciences Library Reference (Non-Circulating)",
	"cts,rev"=>"Library Technical Services Review Shelves",
	"rmc,icer"=>"Kroch Library Rare & Manuscripts (Non-Circulating)",
	"sasa"=>"Kroch Library Asia",
	"sasa,av"=>"Uris Library Asia A/V",
	"sasa,str1"=>"Request at Olin Circulation Desk",
	"sasa,ref"=>"Kroch Library Asia Reference (Non-Circulating)",
	"serv,remo"=>"*Networked Resource",
	"uris,ref"=>"Uris Library Reference (Non-Circulating)",
	"uris,res"=>"Uris Library Reserve",
	"vet"=>"Veterinary Library (Schurman Hall)",
	"vet,anx"=>"Library Annex",
	"vet,rare"=>"Veterinary Library Rare Books (Non-Circulating)",
	"vet,ref"=>"Veterinary Library Reference (Non-Circulating)",
	"was"=>"Kroch Library Asia",
	"was,anx"=>"Library Annex",
	"was,str1"=>"Request at Olin Circulation Desk",
	"was,rare"=>"Kroch Library Rare & Manuscripts (Non-Circulating)",
	"was,ref"=>"Kroch Library Asia Reference (Non-Circulating)",
	"agen"=>"Ag Engineering Library (Riley Robb Hall) (Dept. use only)",
	"bioc"=>"Biochem Reading Room (Biotech Building) (Dept. use only)",
	"cons,lab"=>"Conservation Laboratory (Library Annex)",
	"ech,rare"=>"Kroch Library Rare & Manuscripts (Non-Circulating)",
	"ech,str1"=>"Request at Olin Circulation Desk",
	"engr,ref"=>"Library Annex",
	"engr,wpe"=>"Library Annex",
	"ent,rar2"=>"Entomology Library Rare (Non-Circulating)",
	"ent,res"=>"Entomology Library Reserve",
	"fine,anx"=>"Library Annex",
	"fine,nine"=>"Fine Arts Library (Ask at Circulation)",
	"food"=>"Food Science Library (Stocking Hall) (Dept. use only)",
	"gnva,rare"=>"Geneva Library Rare Books (Non-Circulating)",
	"hote"=>"ILR Library (Ives Hall)",
	"hote,res"=>"Nestle Library Reserve",
	"ilr,lmdc"=>"ILR Library Kheel Center",
	"ilr,mcs"=>"ILR Multi-Copy Storage",
	"ilr,res"=>"ILR Library Reserve",
	"jgsm,ref"=>"ILR Library Reference (Non-Circulating)",
	"law,anx"=>"Library Annex",
	"law,res"=>"Law Library Reserve",
	"mann,href"=>"Bailey Hortorium Reference (Non-Circulating)",
	"maps"=>"Olin Library Maps (Non-Circulating)",
	"math,anx"=>"Library Annex",
	"math,lock"=>"Mathematics Library Locked Press",
	"mus"=>"Cox Library of Music (Lincoln Hall)",
	"mus,av"=>"Music Library A/V (Non-Circulating)",
	"mus,res"=>"Music Library Reserve",
	"oclc,echm"=>"Kroch Library Asia",
	"olin,305"=>"Olin Library Room 305 (Non-Circulating)",
	"olin,anx"=>"Library Annex",
	"olin,str2"=>"Special Location -- Ask at Olin Circulation Desk",
	"orni,ref"=>"Adelson Library Reference (Lab of Ornithology)",
	"phys,res"=>"Physical Sciences Reserve",
	"rmc"=>"Kroch Library Rare & Manuscripts (Non-Circulating)",
	"rmc,hsci"=>"Kroch Library Rare & Manuscripts (Non-Circulating)",
	"sasa,anx"=>"Library Annex",
	"sasa,rare"=>"Kroch Library Rare & Manuscripts (Non-Circulating)",
	"uris"=>"Uris Library",
	"uris,res2"=>"Uris Library Reserve Willis Room",
	"vet,core"=>"Veterinary Library Core Resource (Non-Circulating)",
	"vet,res"=>"Veterinary Library Reserve",
	"was,av"=>"Uris Library Asia A/V",
	"mann,hort"=>"Bailey Hortorium (ask at Mann Library Circulation)",
	"law,ref"=>"Law Library Reference (Non-Circulating)",
	"olin,401"=>"Olin Library Room 401 (Non-Circulating)",
	"olin,601"=>"Olin Library Room 601 (Non-Circulating)",
	"olin,604"=>"Olin Library Room 604-605 (Non-Circulating)",
	"olin,605"=>"Olin Library Room 604-605 (Non-Circulating)",
	}

	def code_to_name(code)
	LOC_CODES[code]
	end

  # Determines if the request buttons should be hidden because item is in Aspace
  # searches for the Aspace PUI resources id in the marc 035 field
  # resource id: is the value after (CULAspaceURI)in the marc 035 field
  #
  # @param [Hash] document - metadata for the item
  #
  # @return [Boolean] true if the PUI resources item ID exists
  def aspace_pui_id?(document)
	return false unless document['marc_display']
	item_field_035_values = document['marc_display'].scan(/<datafield tag="035".*?>.*?<subfield code="a">(.*?)<\/subfield>/m).flatten
	itemid = item_field_035_values.find { |value| value.include?('CULAspaceURI') }&.match(/\(CULAspaceURI\)(.+)/)&.captures&.first
	itemid.present? && ENV['AEON_PUI_REQUEST'].present?
  end

  # Generates the target url
  #
  # @param [String] group - "Circulating" or "AEON_SCAN_REQUEST"
  # @param [String] id
  # @param [Array<String>] aeon_codes
  # @param [Hash] document - metadata for the item
  # @param [Boolean] scan - photoduplication request flag
  #
  # @return [String] the target URL
  def request_path(group, id, aeon_codes, document, scan)
    id_scan = scan ? "#{id}.scan" : "#{id}"
    magic_path  = blacklight_cornell_request.magic_request_path("#{id_scan}")

    if ENV['SAML_IDP_TARGET_URL'].present?
      magic_path = blacklight_cornell_request.auth_magic_request_path("#{id_scan}")
    end

    if ENV['AEON_REQUEST'].blank? && group != 'AEON_SCAN_REQUEST'
      aeon_req = "/aeon/#{id}"
    else
      url = group == 'AEON_SCAN_REQUEST' ? ENV['AEON_SCAN_REQUEST'] : ENV['AEON_REQUEST']
      aeon_req = url.gsub('~id~', id.to_s).gsub('~libid~',aeon_codes.join('|'))
    end

		# NOTE: In order to support display of multiple finding aids (see, e.g., bib 3272126),
		# I'm using a different way of handling the finding aid URLs (the @finding_aids variable
		# in the aeon_controller). So I'm not sure if we even need to do the following anymore.
		# We should probably test this and remove it if it's not needed. (2/27/2025)

		# If there is a finding aid URL, replace the placeholder in the AEON request URL with it
		if document['url_findingaid_display'] && document['url_findingaid_display'].size > 0
			finding_a = (document['url_findingaid_display'][0]).split('|')[0]
			# only replace the placeholder if a finding aid value exists
			aeon_req = aeon_req.gsub('~fa~', finding_a)
		else
			# otherwise remove the finding aid placeholder
			aeon_req = aeon_req.gsub('&finding=~fa~', '')
		end

    (group == "Circulating" ) ? magic_path : aeon_req
  end

  def acquired_date(document)
	if document['acquired_dt'].present?
		# use acquired date as a date
		acquired_date = DateTime.parse(document['acquired_dt'])
	else
		# nil means the acquired date is unknown!
		acquired_date = nil
	end
	return acquired_date
  end

  def feed_item_title(document)
	title = document['fulltitle_display'].blank? ? document.id : document['fulltitle_display']
	return title
  end

  def feed_item_content(document)

	# example content from http://newbooks.mannlib.cornell.edu/?class=G*#GR
	# Zombies
	# Zombies : an anthropological investigation of the living dead / Philippe Charlier ; translated by Richard J. Gray II.
	# University Press of Florida, 2017. -- xv, 138 pages : map ; 23 cm
	# GR581 .C4313 2017 -- Olin Library
	pub_disc = []
	pub_disc << document['pub_info_display'].join(' ') unless document['pub_info_display'].blank?
	pub_disc << document['description_display'] unless document['description_display'].blank?

	holdings_condensed = JSON.parse(document[:holdings_json]).with_indifferent_access
	holdArray = document['holdings_display'].to_a

	col_loc = []
	holdings_condensed.each do |k,v|
		if v["call"].present?
      col_loc << v["call"]
		end
		if v["location"].present? && v["location"]["name"].present?
      col_loc << v["location"]["name"]
		end
	end

	description = []
	description << document['subtitle_display'] unless document['subtitle_display'].blank?
	description << pub_disc.join(' -- ') unless pub_disc.blank?
	description << col_loc.join(' -- ') unless col_loc.blank?
	formatted = description.join("<br>")
	return formatted
  end

# Check if the document is in the user's bookbag
  def bookbagged? did
    d = did.to_s
    value = "bibid-#{d}"
    if @bb
      @bb.index.any? {  |x|  x == value }
    else
      false
    end
  end

  # For musical recordings, renders the image returned by Discogs when available.
  def format_discogs_image url
    image_html = "<div id='discogs-image'><img src='" + url + "' alt='' class='img-thumbnail'></div>"
    return image_html.html_safe
  end
  
  def build_returned_display item
    returned_size = item['items']['returned'].size
    the_html = ""
    if item['items']["count"] == 1
      returned_time = item['items']['returned'][0]["status"]["returned"]
      short = is_short_loan(item['items']['returned'][0])
      if short
        the_time = Time.at(returned_time).strftime("%m/%d/%y %I:%M%P")
        the_html += "<span class='text-nowrap' style='padding-left:20px'>Returned " + the_time + "</span>"
      else
        the_time = Time.at(returned_time).strftime("%m/%d/%y")
        the_html += "<span class='text-nowrap'>Returned " + the_time + "</span>"
      end
    else
      item["items"]["returned"].sort_by! { |i| [i["status"]["returned"], i["status"]["enum"]] }
      current_r_date = ""
      first_time_through = true
      count = 0
      item["items"]["returned"].each do |r|
        enum = r["enum"].present? ? r["enum"] : ""
        if item["items"]["returned"].size < 11
          if r["status"]["status"] == "Available"
            if Time.at(r["status"]["returned"]).strftime("%m/%d/%y") != current_r_date
              current_r_date = Time.at(r["status"]["returned"]).strftime("%m/%d/%y")
              time_returned = r["status"]["returned"]
              short = is_short_loan(r)
              the_html += "</ul></div>" if !first_time_through
              the_html += "<div style='padding-left:20px'>" + "Returned "
              the_html += Time.at(time_returned).strftime("%m/%d/%y") if short == false || item["items"]["returned"].size > 1
              the_html += Time.at(time_returned).strftime("%m/%d/%y %I:%M%P") if short == true && item["items"]["returned"].size == 1
              the_html += ":<ul><li style='margin-left:-25px'>" + enum + "</li>"
              first_time_through = false
            else
              the_html += "<li style='margin-left:-25px'>" + enum + "</li>"
            end
            the_html += "</ul></div>" if r.equal?(item["items"]["returned"].last)
          end
        else
          if r["status"]["status"] == "Available"
            if Time.at(r["status"]["returned"]).strftime("%m/%d/%y") != current_r_date
              time_returned = r["status"]["returned"]
              if !first_time_through
                the_html += "<li style='margin-left:-6px'>"
                the_html += count.to_s + " item returned on " if count == 1
                the_html += count.to_s + " items returned on " if count.to_i > 1
                the_html += current_r_date + "</li>"
              else
                the_html = "<ul>"
              end
              count = 1
              current_r_date = Time.at(r["status"]["returned"]).strftime("%m/%d/%y")
              first_time_through = false
            else
              count = count + 1
            end
          end
          if r.equal?(item["items"]["returned"].last)
            the_html += "<li style='margin-left:-6px'>"
            the_html += count.to_s + " item returned on " if count == 1
            the_html += count.to_s + " items returned on " if count.to_i > 1
            the_html += current_r_date + "</li></ul>"
          end
        end
      end
    end
    return the_html.html_safe
  end
  
  def is_short_loan returned
    return true if returned["status"]["shortLoan"].present? && returned["status"]["shortLoan"] == true
    return false if !returned["status"]["shortLoan"].present? || returned["status"]["shortLoan"] == false
  end

	# Can we show a FOLIO link? Only for valid instance_ids and logged-in users in the right groups
	# N.B. This only checks to see if the user is a member of 'employee' and 'staff', which isn't really right.
	# We should be limiting this to library staff only, but I'm not sure how to specify that in the groups.
	def show_folio_link? instance_id
		instance_id.present? &&
		session[:cu_authenticated_groups].present? &&
		session[:cu_authenticated_groups].include?('employee') #&&
		#session[:cu_authenticated_groups].include?('staff')
	end
end

# End of Module
