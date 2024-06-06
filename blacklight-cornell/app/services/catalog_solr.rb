require "net/http"

class CatalogSolr < StatusPage::Services::Base
  def check!
    begin
      solr_config = YAML.load(ERB.new(File.read("#{::Rails.root}/config/blacklight.yml")).result)
      uri = solr_config[ENV["RAILS_ENV"]]["url"] unless SOLR_CONFIG.nil? or SOLR_CONFIG[ENV["RAILS_ENV"]].nil?

      # Parse the uri and replace the path and query
      uri = URI(uri)
      uri.path = "/solr/admin/cores"
      uri.query = "action=STATUS&indexInfo=false"

      response = Net::HTTP.get_response(uri)
    rescue SocketError => e
      raise "SocketError occurred"
    rescue SocketError, URI::InvalidURIError, Net::OpenTimeout, Net::ReadTimeout, StandardError => e
      raise e
    else
      begin
        parsed_response = JSON.parse(response.body)
      rescue JSON::ParserError => e
        raise e
      end

      if parsed_response.nil? || parsed_response.empty?
        raise StandardError.new("Received an empty response")
      end
    end
  end
end
