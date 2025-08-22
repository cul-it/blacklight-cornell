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

    def call_number_locations
      query_params = {
        :q => '*:*',
        :rows => 0,
        'facet.field' => 'location',
        'facet.limit' => -1,
        'facet.matches' => '[^>]*'
      }
      solr_response = solr_for_browse('Call-Number').get 'browse', :params => query_params
      locations_with_counts = solr_response.dig('facet_counts', 'facet_fields', 'location')
      browse_locations = ['All', 'Online']
      if solr_response.present? && locations_with_counts.present?
        # Remove counts from the array
        browse_locations += locations_with_counts.select.each_with_index { |_, i| i.even? }
      end
      browse_locations
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
