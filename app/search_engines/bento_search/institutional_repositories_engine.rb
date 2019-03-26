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

    start = args[:page].is_a?(Integer) ? args[:page] - 1 : 0
    per_page = args[:per_page].is_a?(Integer) ? args[:per_page] : 5

    solr = RSolr.connect :url => url.to_s
    solr_response = solr.get 'select', :params => {
                                        :q => q,
                                        :start => start,
                                        :rows => per_page,
                                        :fl => '*'
                                       }
  
   
    results = solr_response['response']['docs']

    # Rails.logger.level = Logger::DEBUG # jgr25
    # Rails.logger.debug "jgr25_debug results = #{results[0].to_yaml} \n#{__FILE__}:#{__LINE__}"
    # Rails.logger.level = Logger::WARN # jgr25

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
      
      if i['author_tesim'].present?
        [i['author_tesim']].each do |a|
          next if a.nil?
          item.authors << a
        end
      elsif i['creator_tesim'].present?
        [i['creator_tesim']].each do |a|
          next if a.nil?
          item.authors << a
        end
      elsif i['creator_facet_tesim'].present?
        [i['creator_facet_tesim']].each do |a|
          next if a.nil?
          item.authors << a
        end
      elsif i['author_display'].present?
        [i['author_display']].each do |a|
          next if a.nil?
          # author_display comes in as a combined name and date with a pipe-delimited display name.
          # bento_search does some slightly odd things to author strings in order to display them,
          # so the raw string coming out of *our* display value turns into nonsense by default
          # Telling to create a new Author with an explicit 'display' value seems to work.
          item.authors << BentoSearch::Author.new({:display => a.to_s})
        end
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
        elsif i['id'].starts_with?('ss:')
          "http://digital.library.cornell.edu/catalog/#{i['id']}"
        else 
          "Unknown link"
        end

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
      :solr_url => "http://digcoll.internal.library.cornell.edu:8983/solr/digitalcollections2/"
    }
  end


end
