# Be sure to restart your server when you modify this file.

# Contains initialization for bento_search as suggested in the documentation:
# http://rubydoc.info/gems/bento_search/frames/

# Ensure that the configuration file is present
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

BentoSearch.register_engine("worldcat") do |conf|
  conf.engine = "BentoSearch::WorldcatSruDcEngine"
  conf.api_key = SEARCH_API_CONFIG['worldcat_api_key']
  # assume all users are affiliates and have servicelevel=full access.
  conf.auth = true
  # Link to Cornell WCL, ensure sort by "relevance only"
  conf.link = 'http://cornell.worldcat.org/search?qt=sort&se=nodgr&sd=desc&qt=sort_nodgr_desc&q='
end

BentoSearch.register_engine('summon') do |conf|
  conf.engine = 'BentoSearch::SummonEngine'
  conf.access_id =  SEARCH_API_CONFIG['summon_access_id']
  conf.secret_key = SEARCH_API_CONFIG['summon_secret_key']

  # More details on Summon Search API commands here:
  # http://api.summon.serialssolutions.com/help/api/search/commands
  conf.fixed_params = {
    's.cmd' => [
      # Limit to Journal Article, Book Chapter and Journal/eJournal
      'setFacetValueFilters(ContentType,Journal Article,Book Chapter,Journal / eJournal)',
      # Within Cornell's collection
      'setHoldingsOnly(true)'
    ]
  }

  # Convert Summon Command used for API to query parameter for URL
  conf.link = 'http://cornell.summon.serialssolutions.com/search?' + conf.fixed_params.map{|k,v| "#{k}=" + v.join(' ')}.join('&') + '&s.q='
end
