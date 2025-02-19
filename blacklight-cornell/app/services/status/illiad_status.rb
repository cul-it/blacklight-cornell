require "net/http"
require "uri"
require "json"

module Status
  class IlliadStatus < StatusPage::Services::Base
    API_URL = ENV["MY_ACCOUNT_ILLIAD_API_URL"]
    API_KEY = ENV["MY_ACCOUNT_ILLIAD_API_KEY"]
    USER_ID = ENV["ILLIAD_TEST_USER_ID"] || "jpd294" # test user

    def check!
      raise "ILLiad API environment variables not set" if API_URL.nil? || API_KEY.nil?

      uri = URI("#{API_URL}/Transaction/UserRequests/#{USER_ID}")
      request = Net::HTTP::Get.new(uri)
      request["Accept"] = "application/json"
      request["APIKey"] = API_KEY

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.request(request)
      end

      # check if the status is 200
      if response.code.to_i == 200
        return true # API is up
      else
        raise "ILLiad API Error: #{response.code} - #{response.message}"
      end
    rescue StandardError => e
      raise "ILLiad API Check Failed: #{e.message}"
    end
  end
end