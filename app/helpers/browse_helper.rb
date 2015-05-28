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

	end

	return search_field
end



end

