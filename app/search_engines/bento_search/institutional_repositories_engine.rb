class BentoSearch::InstitutionalRepositoriesEngine

  include BentoSearch::SearchEngine
  include InstitutionalRepositoriesHelper

  # Next, at a minimum, you need to implement a #search_implementation method,
  # which takes a normalized hash of search instructions as input (see documentation
  # at #normalized_search_arguments), and returns BentoSearch::Results item.
  #
  # The Results object should have #total_items set with total hitcount, and contain
  # BentoSearch::ResultItem objects for each hit in the current page. See individual class
  # documentation for more info.
  def search_implementation(args)

    # 'args' should be a normalized search arguments hash including the following elements:
    # :query, :per_page, :start, :page, :search_field, :sort
    Rails.logger.level = Logger::DEBUG # jgr25
    Rails.logger.debug("jgr25_debug BlacklightEngine search called. Query is #{args[:query]}}")
    Rails.logger.debug("jgr25_debug BlacklightEngine search called. args is #{args.inspect}}")
    Rails.logger.level = Logger::WARN # jgr25
    bento_results = BentoSearch::Results.new

    # Format is passed to the engine using the configuration set up in the bento_search initializer
    # If not specified, we can maybe default to books for now.
    format = configuration[:blacklight_format] || 'Institutional Repositories'
    q = URI::encode(args[:oq].gsub(" ","+"))
    Rails.logger.level = Logger::DEBUG # jgr25
    Rails.logger.debug "jgr25_debug q = #{q.to_yaml} \n#{__FILE__}:#{__LINE__}"
    Rails.logger.level = Logger::WARN # jgr25

    uri = configuration.solr_url
    url = Addressable::URI.parse(uri)
    url.normalize

    start = args[:page].is_a?(Integer) ? args[:page] - 1 : 0
    per_page = args[:per_page].is_a?(Integer) ? args[:per_page] : 5

    solr = RSolr.connect :url => url.to_s
    solr_response = solr.get 'select', :params => {
                                        :q => q,
                                        :start => start * per_page,
                                        :rows => per_page,
                                        :fl => '*'
                                       }
  
   
    results = solr_response['response']['docs']

    # Rails.logger.level = Logger::DEBUG # jgr25
    # Rails.logger.debug "jgr25_debug results = #{results[0].to_yaml} \n#{__FILE__}:#{__LINE__}"
    # Rails.logger.level = Logger::WARN # jgr25

    results.each do |i|
      item = BentoSearch::ResultItem.new

      item = solrResult2Bento(i, item)
      Rails.logger.level = Logger::DEBUG # jgr25
      Rails.logger.debug "jgr25_debug test = #{item.to_yaml} \n#{__FILE__}:#{__LINE__}"
      Rails.logger.level = Logger::WARN # jgr25

      bento_results << item
    end
    bento_results.total_items = solr_response['response']['numFound']
    
    # Rails.logger.level = Logger::DEBUG # jgr25
    # Rails.logger.debug "jgr25_debug bento_results = #{bento_results.to_yaml} \n#{__FILE__}:#{__LINE__}"
    # Rails.logger.level = Logger::WARN # jgr25
    return bento_results
  end

  def self.default_configuration
    {
      # use this address for servers
      :solr_url => "http://digcoll.library.cornell.edu:8983/solr/digitalcollections2/"

      # use this address for local development
      #:solr_url => "http://digcoll.internal.library.cornell.edu:8983/solr/digitalcollections2/"
    }
  end
  
end
