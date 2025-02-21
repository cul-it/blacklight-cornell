require "net/http"
module Status

  class RepositoriesSolrStatus < StatusPage::Services::Base

    def check!
      uri = ENV["IR_SOLR_URL"]

      # Parse the uri and replace the path and query
      uri = URI(uri)
      uri.path = "/solr/admin/cores"
      uri.query = "action=STATUS&indexInfo=false"
      response = ""

      begin
        Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == "https") do |http|
          request = Net::HTTP::Get.new(uri)
          request.basic_auth ENV["IR_SOLR_USER"], ENV["IR_SOLR_PAW"]
          response = http.request request
        end
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
          parsed_response = JSON.parse(response.body)
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
end
