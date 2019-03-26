class BentoSearch::InstitutionalRepositoriesEngine

  include BentoSearch::SearchEngine

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
    q = URI::encode(args[:oq])
    uri = configuration.solr_url
    url = Addressable::URI.parse(uri)
    url.normalize

    solr = RSolr.connect :url => url.to_s
    solr_response = solr.get 'select', :params => {
                                        :q => q,
                                        :rows => 10,
                                        :fl => 'id,title_ssi,title_tesim,author_t,collection_tesim,solr_loader_tesim,abstract_tesim,content_metadata_image_iiif_info_ssm,date_tesim,handle_tesim,collection_website_ss'
                                       }
  
   
    results = solr_response['response']['docs']

    Rails.logger.level = Logger::DEBUG # jgr25
    Rails.logger.debug "jgr25_debug results = #{results[0].to_yaml} \n#{__FILE__}:#{__LINE__}"
    Rails.logger.level = Logger::WARN # jgr25

    results.each do |i|
      item = BentoSearch::ResultItem.new

      item.title =
        if i['title_ssi'].present?
          i['title_ssi'].to_s
        elsif i['title_tesim'].present?
          i['title_tesim'][0].to_s
        else 
          'Unknown title field'
        end
      
      if i['author_t'].present?
        item.authors << i['author_t'].to_s
      else
        item.authors << 'Unknown author field'
      end

      if i['collection_tesim'].present? && i['solr_loader_tesim'].present? && i['solr_loader_tesim'][0] == "eCommons"
        item.abstract = i['collection_tesim'][0].to_s + " Collection in eCommons"
      elsif i['collection_tesim'].present?
        item.abstract = i['collection_tesim'][0].to_s
      elsif i['abstract_tesim'].present?
        item.abstract = i['abstract_tesim'][0].to_s
      end

      if i['content_metadata_image_iiif_info_ssm'].present?
        item.format_str = i['content_metadata_image_iiif_info_ssm'][0].to_s
        item.format_str = item.format_str.gsub('info.json','full/100,/0/native.jpg')
      end

      if i['date_tesim'].present?
        item.publication_date = i['date_tesim'][0].to_s
      end

      item.link =
        if i['solr_loader_tesim'].present? && i['solr_loader_tesim'][0] == "eCommons"
          i['handle_tesim'][0]
        elsif i['collection_website_ss'].present?
          i['collection_website_ss'][0]
        else 
          "Unknown link"
        end

      bento_results << item
    end
    bento_results.total_items = solr_response['response']['numFound']
    
    Rails.logger.level = Logger::DEBUG # jgr25
    Rails.logger.debug "jgr25_debug bento_results = #{bento_results.to_yaml} \n#{__FILE__}:#{__LINE__}"
    Rails.logger.level = Logger::WARN # jgr25
    return bento_results
  end

  def self.default_configuration
    {
      :solr_url => "http://digcoll.internal.library.cornell.edu:8983/solr/digitalcollections2/"
    }
  end


end
