# Be sure to restart your server when you modify this file.

# Contains initialization for bento_search as suggested in the documentation:
# http://rubydoc.info/gems/bento_search/frames/
begin
  SEARCH_API_CONFIG = YAML.load_file("#{::Rails.root}/config/search_apis.yml")
rescue Errno::ENOENT
  puts <<-eos

  ******************************************************************************
  Your search_apis.yml config file is missing.
  See config/search_apis.yml.example
  ******************************************************************************

  eos


end
#conf = YAML.load(ERB.new(File.read("#{Rails.root}/config/database.yml")).result
begin
  SOLR_CONFIG = YAML.load(ERB.new(File.read("#{::Rails.root}/config/blacklight.yml")).result)
rescue Errno::ENOENT
  puts <<-eos
  ******************************************************************************
  Your solr.yml config file is missing.
  See config/solr.yml.example
  ******************************************************************************
  eos
end


# This connection to Summon is used by the bento/single search
BentoSearch.register_engine('summon_bento') do |conf|
	conf.engine = 'BentoSearch::SummonEngine'
	conf.title = 'Articles & Full Text'
	conf.access_id =  ENV['SUMMON_ACCESS_ID']
	conf.secret_key = ENV['SUMMON_SECRET_KEY']
	conf.for_display = {:decorator => "ArticleDecorator"}
	conf.highlighting = false
	# More details on Summon Search API commands here:
	# http://api.summon.serialssolutions.com/help/api/search/commands
	conf.fixed_params = {
		's.cmd' => [
			# Limit to Journal Articles
			'setFacetValueFilters(ContentType,Newspaper Article)',
			# Within Cornell's collection
			'setHoldingsOnly(true)',
      'negateFacetValueFilter(ContentType)'
		]

	}

end

# And this connection to Summon is used within the Blacklight catalog
BentoSearch.register_engine('summon') do |conf|
  conf.engine = 'BentoSearch::SummonEngine'
  conf.access_id =  ENV['SUMMON_ACCESS_ID']
  conf.secret_key = ENV['SUMMON_SECRET_KEY']

  # More details on Summon Search API commands here:
  # http://api.summon.serialssolutions.com/help/api/search/commands
  conf.fixed_params = {
    's.cmd' => [
      # Limit to Journal Article, Book Chapter and Journal/eJournal
      'setFacetValueFilters(ContentType,Newspaper Article)',
      'negateFacetValueFilter(ContentType)',
      # Within Cornell's collection
      'setHoldingsOnly(true)'
    ]
  }

  # Convert Summon Command used for API to query parameter for URL
  conf.link = 'http://encompass.library.cornell.edu/cgi-bin/checkIP.cgi?access=gateway_standard%26url=http://cornell.summon.serialssolutions.com/search?s.fvf=ContentType,Newspaper+Article,t&s.q='
end

BentoSearch.register_engine('worldcat') do |conf|
  conf.engine = "BentoSearch::WorldcatSruDcEngine"
  conf.api_key = ENV['WORLDCAT_API_KEY']
  # assume all users are affiliates and have servicelevel=full access.
  conf.auth = true
  # Link to Cornell WCL, ensure sort by "relevance only"
  conf.link = 'http://cornell.worldcat.org/search?qt=sort&se=nodgr&sd=desc&qt=sort_nodgr_desc&q='
end


BentoSearch.register_engine('summonArticles') do |conf|
  conf.engine = 'BentoSearch::SummonEngine'
  conf.title = 'Newspaper Articles'
	conf.access_id =  ENV['SUMMON_ACCESS_ID']
	conf.secret_key = ENV['SUMMON_SECRET_KEY']
  conf.for_display = {:decorator => "ArticleDecorator"}
  conf.highlighting = false
  # More details on Summon Search API commands here:
  # http://api.summon.serialssolutions.com/help/api/search/commands
  conf.fixed_params = {
    's.cmd' => [
      # Limit to Journal Articles
      'setFacetValueFilters(ContentType,Newspaper Article)',
      # Within Cornell's collection
      'setHoldingsOnly(true)'
    ]

  }

end

BentoSearch.register_engine('bestbet') do |conf|
	conf.engine = 'BentoSearch::BestBetEngine'
	conf.title = 'Best Bet'
end

BentoSearch.register_engine('digitalCollections') do |conf|
	conf.engine = 'BentoSearch::DigitalCollectionsEngine'
	conf.title = 'Digital Collections'
	conf.for_display = {:decorator => "DigitalCollections"}
end

BentoSearch.register_engine('libguides') do |conf|
	conf.engine = 'BentoSearch::LibguidesEngine'
	conf.title = 'Research Guides'
	conf.for_display = {:decorator => "DigitalCollections"}
end

BentoSearch.register_engine('solr') do |conf|
	conf.engine = 'BentoSearch::SolrEngineSingle'
	conf.title = 'Solr Query'
  conf.solr_url = SOLR_CONFIG[ENV['RAILS_ENV']]["url"]
end

BentoSearch.register_engine('Book') do |conf|
	conf.engine = 'SolrEngine'
	conf.title = 'Books'
	conf.blacklight_format = 'Book'
end

BentoSearch.register_engine('Journal/Periodical') do |conf|
	conf.engine = 'SolrEngine'
	conf.title = 'Journals/Periodicals'
	conf.blacklight_format = 'Journal/Periodical'
end

BentoSearch.register_engine('Database') do |conf|
	conf.engine = 'SolrEngine'
	conf.title = 'Databases'
	conf.blacklight_format = 'Database'
end

BentoSearch.register_engine('Thesis') do |conf|
	conf.engine = 'SolrEngine'
	conf.title = 'Theses'
	conf.blacklight_format = 'Thesis'
end

BentoSearch.register_engine('Musical Recording') do |conf|
	conf.engine = 'BentoSearch::SolrEngineSingle'
	conf.title = 'Musical Recordings'
	conf.blacklight_format = 'Musical Recording'
end

BentoSearch.register_engine('Musical Score') do |conf|
	conf.engine = 'SolrEngine'
	conf.title = 'Musical Scores'
	conf.blacklight_format = 'Musical Score'
end

BentoSearch.register_engine('Map') do |conf|
  conf.engine = 'SolrEngine'
  conf.title = 'Maps'
  conf.blacklight_format = 'Map'
end

BentoSearch.register_engine('Video') do |conf|
	conf.engine = 'SolrEngine'
	conf.title = 'Videos'
	conf.blacklight_format = 'Video'
end

BentoSearch.register_engine('Manuscript/Archive') do |conf|
	conf.engine = 'SolrEngine'
	conf.title = 'Manuscripts / Archives'
	conf.blacklight_format = 'Manuscript/Archive'
end

BentoSearch.register_engine('Non-musical Recording') do |conf|
	conf.engine = 'SolrEngine'
	conf.title = 'Non-musical Recordings'
	conf.blacklight_format = 'Non-musical Recording'
end

BentoSearch.register_engine('Website') do |conf|
	conf.engine = 'SolrEngine'
	conf.title = 'Websites'
	conf.blacklight_format = 'Website'
end

BentoSearch.register_engine('Computer File') do |conf|
	conf.engine = 'SolrEngine'
	conf.title = 'Computer Files'
	conf.blacklight_format = 'Computer File'
end

BentoSearch.register_engine('Image') do |conf|
	conf.engine = 'SolrEngine'
	conf.title = 'Images'
	conf.blacklight_format = 'Image'
end

BentoSearch.register_engine('Miscellaneous') do |conf|
	conf.engine = 'SolrEngine'
	conf.title = 'Miscellaneous'
	conf.blacklight_format = 'Miscellaneous'
end

BentoSearch.register_engine('Kit') do |conf|
	conf.engine = 'SolrEngine'
	conf.title = 'Kits'
	conf.blacklight_format = 'Kit'
end

BentoSearch.register_engine('Research Guide') do |conf|
	conf.engine = 'SolrEngine'
	conf.title = 'Research Guides'
	conf.blacklight_format = 'Research Guide'
end

BentoSearch.register_engine('Microform') do |conf|
	conf.engine = 'SolrEngine'
	conf.title = 'Microforms'
	conf.blacklight_format = 'Microform'
end

BentoSearch.register_engine('Course Guide') do |conf|
	conf.engine = 'SolrEngine'
	conf.title = 'Course Guides'
	conf.blacklight_format = 'Course Guide'
end

BentoSearch.register_engine('Object') do |conf|
	conf.engine = 'SolrEngine'
	conf.title = 'Objects'
	conf.blacklight_format = 'Object'
end
