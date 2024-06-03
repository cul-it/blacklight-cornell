require 'net/http'

class CheckSolrService < StatusPage::Services::Base
  def check!
    solr_config = YAML.load(ERB.new(File.read("#{::Rails.root}/config/blacklight.yml")).result)
    uri = solr_config[ENV['RAILS_ENV']]["url"] unless SOLR_CONFIG.nil? or SOLR_CONFIG[ENV['RAILS_ENV']].nil?

    # Parse the uri and replace the path and query
    uri = URI(uri)
    uri.path = '/solr/admin/cores'
    uri.query = 'action=STATUS&indexInfo=false'

    begin
      response = Net::HTTP.get_response(uri)
    rescue SocketError => e
      raise "SocketError occurred"
    rescue URI::InvalidURIError => e
      raise "Invalid URL"
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      raise "Network timeout occurred"
    rescue StandardError => e
      raise "An error occurred while checking Solr"
    else
        begin
            parsed_response = JSON.parse(response)
        rescue JSON::ParserError => e
            raise "Failed to parse JSON response"
        end
        if parsed_response.nil? || parsed_response.empty?
            # Handle empty response
            raise "Received an empty response"
        end
    end
  end
end