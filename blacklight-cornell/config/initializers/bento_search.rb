# Be sure to restart your server when you modify this file.

# Contains initialization for bento_search as suggested in the documentation:
# http://rubydoc.info/gems/bento_search/frames/

# Partially override BentoSearch classes using prepend pattern
Rails.application.config.to_prepare do
  BentoSearch::StandardDecorator.prepend BentoSearch::Prepends::StandardDecorator
end

# official supported eds search
BentoSearch.register_engine('ebsco_eds') do |conf|
	conf.engine = 'BentoSearch::EbscoEdsEngine'
	conf.user_id = ENV['EDS_USER']
	conf.password = ENV['EDS_PASS']
	conf.profile = ENV['EDS_PROFILE']
	conf.title = "Articles & Full Text"
	conf.for_display = {:decorator => "EbscoEdsArticleDecorator"}
	conf.highlighting = false
end

# TODO: I don't think we use this engine at all - we just use the configuration link in CornellCatalog#index
# Engine defined in bento_search
BentoSearch.register_engine('worldcat') do |conf|
  conf.engine = "BentoSearch::WorldcatSruDcEngine"
  conf.api_key = ENV['WORLDCAT_API_KEY']
  # assume all users are affiliates and have servicelevel=full access.
  conf.auth = true
  # Link to Worldcat Discovery, ensure sort by "relevance only"
  conf.link = "#{ENV['WORLDCAT_URL']}/search?qt=sort&se=nodgr&sd=desc&qt=sort_nodgr_desc&queryString="
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

BentoSearch.register_engine('institutionalRepositories') do |conf|
  conf.engine = 'BentoSearch::InstitutionalRepositoriesEngine'
  conf.title = 'Repositories'
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
	conf.engine = 'SolrEngine'
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
