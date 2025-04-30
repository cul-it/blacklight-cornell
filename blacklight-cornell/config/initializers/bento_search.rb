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
