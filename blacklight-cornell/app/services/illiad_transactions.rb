require "net/http"
require "uri"
require "json"

class IlliadTransactions < StatusPage::Services::Base
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

    # Check for HTTP 200 status
    if response.code.to_i != 200
      raise "ILLiad API Error: #{response.code} - #{response.message}"
    end

    # Parse JSON response (expecting an array)
    body = JSON.parse(response.body)

    if body.empty?
      raise "ILLiad API returned an empty response"
    end

    true # Success
  rescue StandardError => e
    raise "ILLiad API Check Failed: #{e.message}"
  end
end
