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

end