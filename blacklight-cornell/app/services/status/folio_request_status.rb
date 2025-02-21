require 'net/http'
require 'json'

module Status
  class FolioRequestStatus < StatusPage::Services::Base
    HEALTH_ENDPOINT = '/admin/health'.freeze

    def check!
      base_url = "https://okapi-cornell.folio.ebsco.com" # Use ENV["OKAPI_URL"] in prod
      module_path = "/mod-circulation" # Example module path
      tenant = ENV["OKAPI_TENANT"]

      raise "Folio environment variables not set" if base_url.nil? || tenant.nil?

      # Correct URL construction
      health_url = URI("#{base_url}#{module_path}#{HEALTH_ENDPOINT}")
      puts "Performing Health Check on URL: #{health_url}"

      response = perform_health_check(health_url)

      puts "HTTP Response Code: #{response.code}"
      puts "HTTP Response Body: #{response.body}"

      if response.code.to_i == 200
        body = response.body.strip
        cleaned_body = body.gsub(/\A"|"\Z/, '')
        if cleaned_body == "OK" || cleaned_body == "UP"
          puts "Health check passed with status: #{cleaned_body}"
          true
        else
          parsed_body = try_parse_json(body)
          status = parsed_body["status"]
          if status == "UP"
            puts "Health check passed with JSON status: #{status}"
            true
          else
            raise "Health check failed: #{status || 'Unknown status'}"
          end
        end
      else
        raise "Health check HTTP error: #{response.code}, Body: #{response.body}"
      end
    rescue StandardError => e
      puts "Folio Health Check Error: #{e.message}"
      raise "Folio Health Check Error: #{e.message}"
    end

    private

    def perform_health_check(uri)
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
        request = Net::HTTP::Get.new(uri)
        request["X-Okapi-Tenant"] = ENV["OKAPI_TENANT"]
        http.request(request)
      end
    end

    def try_parse_json(body)
      JSON.parse(body)
    rescue JSON::ParserError
      puts "JSON parsing failed. Raw body: #{body}"
      {}
    end
  end
end
