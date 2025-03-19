module BlacklightCornell
  module Browse
    BROWSE_INDEX_AUTHOR = ENV['BROWSE_INDEX_AUTHOR'].nil? ? 'author' : ENV['BROWSE_INDEX_AUTHOR']
    BROWSE_INDEX_SUBJECT = ENV['BROWSE_INDEX_SUBJECT'].nil? ? 'subject' : ENV['BROWSE_INDEX_SUBJECT']
    BROWSE_INDEX_AUTHORTITLE = ENV['BROWSE_INDEX_AUTHORTITLE'].nil? ? 'authortitle' : ENV['BROWSE_INDEX_AUTHORTITLE']
    BROWSE_INDEX_CALLNUMBER = ENV['BROWSE_INDEX_CALLNUMBER'].nil? ? 'callnum' : ENV['BROWSE_INDEX_CALLNUMBER']

    def browse_solr(query:, fq:, order:, rows:, start: 0, browse_type:)
      return {} if query.nil?

      # } instead of ] at end of reverse query means get exclusive range
      q = order != 'reverse' ? "[\"#{query}\" TO *]" : "[* TO \"#{query}\"}"
      query_params = {
        :q => q,
        :start => start,
        :wt => :ruby
      }
      query_params[:fq] = fq if fq.present?
      query_params[:rows] = rows if rows.present?
      solr_endpoint = order == 'reverse' ? 'reverse' : 'browse'
      solr_for_browse(browse_type).get solr_endpoint, :params => query_params
    end

    def solr_for_browse(browse_type)
      solr_collection = solr_collection(browse_type)
      RSolr.connect :url => "#{base_solr_url}/#{solr_collection}"
    end

    def base_solr_url
      base_solr_url ||= Blacklight.connection_config[:url].gsub(/\/solr\/.*/,'/solr')
    end

    def solr_collection(browseType)
      case browseType
      when 'Author'
        BROWSE_INDEX_AUTHOR
      when 'Subject'
        BROWSE_INDEX_SUBJECT
      when 'Author-Title'
        BROWSE_INDEX_AUTHORTITLE
      when 'Call-Number', 'virtual'
        BROWSE_INDEX_CALLNUMBER
      end
    end
  end
end
