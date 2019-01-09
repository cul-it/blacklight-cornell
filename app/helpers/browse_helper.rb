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

def availability_location_filter()
	libs = ["All",
	  "Adelson Library",
	  "Africana Library",
	  "Bailey Hortorium ",
	  "CISER Data Archive",
	  "Fine Arts Library",
	  "ILR Library",
	  "ILR Library Kheel Center",
	  "Kroch Library Asia",
	  "Kroch Library Rare & Manuscripts",
	  "Law Library",
	  "Library Annex",
	  "Mann Library",
	  "Mathematics Library",
	  "Music Library",
	  "Nestle Library",
	  "Olin Library",
	  "Sage Hall Management Library",
	  "Space Sciences Building",
	  "Uris Library",
	  "Veterinary Library"
	]
	output = []
	output << '<div class="btn-group">'
	output << '<a href="#" class="btn btn-default btn-sm" data-toggle="dropdown" id="location-filter-menu" aria-haspopup="true" aria-expanded="false">Availability <b class="caret"></b></a>'
	output << '<ul class="dropdown-menu" role="menu" aria-labelledby="location-filter-menu">'
	
	# libs.each { |lib|
	#   line = '<li><%= link_to "' + lib + '", '
	#   if lib != 'All'
	#     line << ':fq => "location:\"' + URI::encode(lib) + '\", '
	#   end
	#   line << ':start => params[:start], :browse_type => params[:browse_type], :authq => params[:authq] %></li>'
	#   output << line
	# }
	output << '</ul>'
	output << '</div>'
  return output.join("\n")
end

end