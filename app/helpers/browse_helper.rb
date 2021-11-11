module BrowseHelper

def search_field(headingType)
	if headingType == "Personal Name" 
		search_field = 'pers'
	elsif headingType=="Corporate Name"
		search_field = 'corp'
	elsif headingType == "Event"
		search_field = 'event'
	elsif headingType == 'Geographic Name'
		search_field = "geo"
	elsif headingType == 'Chronological Term'
		search_field = 'era'
	elsif headingType == 'Genre/Form Term'
		search_field = 'genr'
	elsif headingType == "Topical Term"
		search_field = 'topic'
	elsif headingType=='Work'
		search_field='work'
	else search_field='all_fields'

	end

	return search_field
end

def browse_uri_encode (link_url)
    link_url = link_url.gsub('&','%26')
    link_url = link_url.gsub('"','%22')
end
	
def call_number_browse_link(call_number)
	link_url = '/browse?start=0&browse_type=Call-Number&authq=' + call_number
	link_to(h(call_number), link_url)
end

def cleanup_bio_data(bd)
  if bd.key?("Occupation")
    bd.except!("Field")
  end
  return bd
end

def render_bio_data(bd)
  html = ""
  bd.each do |t,d|
    unless t == "Gender"
      if t == "Group/Organization"
        t = "Affiliation"
      end
      html += "<dt>" + t + ":</dt><dd style='margin-left:120px'>"
      if t == "Occupation"
        d.each do |data|
          if !data.equal?(d.last)
            html += data.gsub(/s$/, '') + ", "
          else
            html += data.gsub(/s$/, '')
          end
        end
      else
        html += d if !d.kind_of?(Array)
        html += d.join(", ") if d.kind_of?(Array)
      end
      html += "</dd>"
    end
  end
  return html.html_safe
end

def render_reference_info(type,h_response,loc_localname)
  alt_form_count = h_response[0]["alternateForm"].present? ? h_response[0]["alternateForm"].size : 0
  html = ""
  if h_response[0]["headingTypeDesc"].present? 
    html += build_heading_type(h_response[0]["headingTypeDesc"]) 
  end 
  if alt_form_count > 0 
    if type == "subject"
      html += build_alt_forms_subjects(h_response[0]["alternateForm"])
    else
      html += build_alt_forms_authors(h_response[0]["alternateForm"])
    end
  end
  if !loc_localname.blank?
    if loc_localname[1..2] == "sh"
      html += build_lcsh_link(loc_localname.gsub('"',''))
    else
      html += build_lcnaf_link(loc_localname.gsub('"',''))
    end
  end
  return html.html_safe
end

def build_heading_type(heading_type)
   html = '<dl class="dl-horizontal"><dt>Heading Type:</dt><dd>' + heading_type + '</dd></dt></dl>'
   return html.html_safe
 end

 def build_lcnaf_link(localname)
   html = '<div id="lcnaf-link" class="mt-2 mb-4"><span><a href="https://id.loc.gov/authorities/names/' + localname
   html += '.html" target="_blank">Library of Congress Name Authority File (LCNAF) <i class="fa fa-external-link"></i></a></span></div>'
   return html.html_safe
 end

 def build_lcsh_link(localname)
   html = '<div id="lcnaf-link" class="mt-2 mb-4"><span><a href="https://id.loc.gov/authorities/subjects/' + localname
   html += '.html" target="_blank">Library of Congress Subject Headings (LCSH) <i class="fa fa-external-link"></i></a></span></div>'
   return html.html_safe
 end

 def build_alt_forms_authors(alt_forms)
   alt_form_count = alt_forms.size
   html = ""
   if alt_form_count > 0 && alt_form_count < 8
     html = '<dl class="dl-horizontal"><dt>Alternate Form(s):</dt>'
     alt_forms.each do |af|
       html += '<dd>' + af + '</dd>'
  	 end
     html += "</dl>"
  elsif alt_form_count > 0 and alt_form_count >= 4
    html += '<div>Alternate Forms: </div><div class="row" style="margin: 0;padding-top: 10px;">'
    divisor = 2 if alt_form_count <= 8
    divisor = 3 if alt_form_count > 8
     html += '<div class="col-md-4">'
     count = 0
     split_at = alt_form_count / divisor
     list = ""
     alt_forms.each do |af|
       if count <= split_at
         list += "<p>" + af + "</p>"
         count = count + 1
       elsif
         list += '</div> <!-- elsif div--><div class="col-md-4">'
         count = 0
         list += '<p>' + af + '</p>'
         count = count + 1
       end
     end
     html += list + "</div><!-- first closing div--></div><!-- second closing div-->"
   end
   return html.html_safe   
 end

 def build_alt_forms_subjects(alt_forms)
   alt_form_count = alt_forms.size
   html = ""
   if alt_form_count > 0 && alt_form_count < 13
     html = '<dl class="dl-horizontal"><dt>Alternate Form(s):</dt>'
     alt_forms.each do |af|
       html += '<dd>' + af + '</dd>'
  	 end
     html += "</dl>"
   elsif alt_form_count > 0 and alt_form_count >= 13
     html = '<div>Alternate Form(s)
     : </div><div class="row" style="margin: 0;padding-top: 10px;"><div class="col-md-6">'
     count = 0
     alt_form_count = alt_form_count + 1 unless alt_form_count.even?
     split_at = alt_form_count / 2
     list = ""
     alt_forms.each do |af|
       if count <= split_at
         list += "<p>" + af + "</p>"
         count = count + 1
       elsif
         list += '</div> <!-- elsif div--><div class="col-md-6">'
         count = 0
         list += '<p>' + af + '</p>'
         count = count + 1
       end
     end
     html += list + "</div><!-- first closing div--></div><!-- second closing div-->"
   end
    return html.html_safe   
 end

  def build_search_link(format_type, encoded_heading, search_type)
    if search_type == "pers" || search_type == "corp" || search_type == "event"
      the_search_field = 'search_field_row[]=author_' + search_type + '_browse&search_field_row[]=subject_' + search_type + '_browse'
      return format_the_formats(format_type, encoded_heading, the_search_field, "OR")
    else
      the_search_field = 'search_field_row[]=subject_' + search_type + '_browse&search_field_row[]=author_' + search_type + '_browse'
      return format_the_formats(format_type, encoded_heading, the_search_field, "NOT")    
    end
    return ""#%2F
  end
  
  def format_the_formats(f_type, encoded_heading, the_search_field, bool)
    html = ""    
    f = f_type.split(" (")[0]
    case f
    when "Books"
      html = '<i class="fa fa-book"></i>'
      html += '<a id="facet_link_book" href="/?advanced_query=yes&boolean_row[1]=' + bool + '&f[format][]=Book&op_row[]=AND&op_row[]=AND'
      html += '&q_row[]=' + encoded_heading + '&q_row[]=' + encoded_heading + '&search_field=advanced&' + the_search_field + '">' + f_type + '</a>'
    when "Journals/Periodicals"
      html = '<i class="fa fa-book-open"></i>'
      html += '<a id="facet_link_journal_periodical" href="/?advanced_query=yes&boolean_row[1]=' + bool + '&f[format][]=Journal/Periodical&op_row[]=AND&op_row[]=AND'
      html += '&q_row[]=' + encoded_heading + '&q_row[]=' + encoded_heading + '&search_field=advanced&' + the_search_field + '">' + f_type + '</a>'
    when "Manuscripts/Archives"
      html = '<i class="fa fa-archive"></i>'
      html += '<a id="facet_link_manuscript_archive" href="/?advanced_query=yes&boolean_row[1]=' + bool + '&f[format][]=Manuscript/Archive&op_row[]=AND&op_row[]=AND'
      html += '&q_row[]=' + encoded_heading + '&q_row[]=' + encoded_heading + '&search_field=advanced&' + the_search_field + '">' + f_type + '</a>'
    when "Maps"
      html = '<i class="fa fa-globe"></i>'
      html += '<a id="facet_link_map" href="/?advanced_query=yes&boolean_row[1]=' + bool + '&f[format][]=Map&op_row[]=AND&op_row[]=AND'
      html += '&q_row[]=' + encoded_heading + '&q_row[]=' + encoded_heading + '&search_field=advanced&' + the_search_field + '">' + f_type + '</a>'
    when "Musical Scores"
      html = '<i class="fa-musical-score"></i>'
      html += '<a id="facet_link_musical_score" href="/?advanced_query=yes&boolean_row[1]=' + bool + '&f[format][]=Musical%20Score&op_row[]=AND&op_row[]=AND'
      html += '&q_row[]=' + encoded_heading + '&q_row[]=' + encoded_heading + '&search_field=advanced&' + the_search_field + '">' + f_type + '</a>'
    when "Non-musical Recordings"
      html = '<i class="fa fa-headphones"></i>'
      html += '<a id="facet_link_non_musical_recording" href="/?advanced_query=yes&boolean_row[1]=' + bool + '&f[format][]=Non-musical%20Recording&op_row[]=AND&op_row[]=AND'
      html += '&q_row[]=' + encoded_heading + '&q_row[]=' + encoded_heading + '&search_field=advanced&' + the_search_field + '">' + f_type + '</a>'
    when "Videos"
      html = '<i class="fa fa-video-camera"></i>'
      html += '<a id="facet_link_video" href="/?advanced_query=yes&boolean_row[1]=' + bool + '&f[format][]=Video&op_row[]=AND&op_row[]=AND'
      html += '&q_row[]=' + encoded_heading + '&q_row[]=' + encoded_heading + '&search_field=advanced&' + the_search_field + '">' + f_type + '</a>'
    when "Computer Files"
      html = '<i class="fa fa-save"></i>'
      html += '<a id="facet_link_computer_file" href="/?advanced_query=yes&boolean_row[1]=' + bool + '&f[format][]=Computer%20File&op_row[]=AND&op_row[]=AND'
      html += '&q_row[]=' + encoded_heading + '&q_row[]=' + encoded_heading + '&search_field=advanced&' + the_search_field + '">' + f_type + '</a>'
    when "Databases"
      html = '<i class="fa fa-database"></i>'
      html += '<a id="facet_link_database" href="/?advanced_query=yes&boolean_row[1]=' + bool + '&f[format][]=Database&op_row[]=AND&op_row[]=AND'
      html += '&q_row[]=' + encoded_heading + '&q_row[]=' + encoded_heading + '&search_field=advanced&' + the_search_field + '">' + f_type + '</a>'
    when "Musical Recordings"
      html = '<i class="fa fa-music"></i>'
      html += '<a id="facet_link_musical_recording" href="/?advanced_query=yes&boolean_row[1]=' + bool + '&f[format][]=Musical%20Recording&op_row[]=AND&op_row[]=AND'
      html += '&q_row[]=' + encoded_heading + '&q_row[]=' + encoded_heading + '&search_field=advanced&' + the_search_field + '">' + f_type + '</a>'
    when "Theses"
      html = '<i class="fa fa-file-text-o"></i>'
      html += '<a id="facet_link_thesis" href="/?advanced_query=yes&boolean_row[1]=' + bool + '&f[format][]=Thesis&op_row[]=AND&op_row[]=AND'
      html += '&q_row[]=' + encoded_heading + '&q_row[]=' + encoded_heading + '&search_field=advanced&' + the_search_field + '">' + f_type + '</a>'
    when "Microforms"
      html = '<i class="fa fa-film"></i>'
      html += '<a id="facet_link_microform" href="/?advanced_query=yes&boolean_row[1]=' + bool + '&f[format][]=Microform&op_row[]=AND&op_row[]=AND'
      html += '&q_row[]=' + encoded_heading + '&q_row[]=' + encoded_heading + '&search_field=advanced&' + the_search_field + '">' + f_type + '</a>'
    when "Miscellaneous"
      html = '<i class="fa fa-ellipsis-h"></i>'
      html += '<a id="facet_link_miscellaneous" href="/?advanced_query=yes&boolean_row[1]=' + bool + '&f[format][]=Miscellaneous&op_row[]=AND&op_row[]=AND'
      html += '&q_row[]=' + encoded_heading + '&q_row[]=' + encoded_heading + '&search_field=advanced&' + the_search_field + '">' + f_type + '</a>'
    end
    return html.html_safe
  end
end
