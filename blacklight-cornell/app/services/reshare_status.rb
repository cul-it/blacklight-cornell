require "net/http"
require "uri"
require "json"
require "rest-client"
require "cul/folio/edge"

class ReshareStatus < StatusPage::Services::Base
  NET_ID   = ENV["ILLIAD_TEST_USER_ID"] || "jpd294" # Test user
  API_URL  = ENV["RESHARE_STATUS_URL"]
  TENANT   = ENV["RESHARE_TENANT"]
  USER     = ENV["RESHARE_USER"]
  PASSWORD = ENV["RESHARE_PW"]

  def check!
    raise "ReShare API environment variables not set" if API_URL.nil? || TENANT.nil? || USER.nil? || PASSWORD.nil?

    token = authenticate!
    response = fetch_patron_requests(token)

    # Check if the response is HTTP 200
    if response.code.to_i == 200
      return true # API is up
    else
      raise "ReShare API Error: #{response.code} - #{response.message}"
    end
  rescue StandardError => e
    raise "ReShare API Check Failed: #{e.message}"
  end

  private
  def authenticate!
    response = CUL::FOLIO::Edge.authenticate(API_URL, TENANT, USER, PASSWORD, method: :old)

    if response[:code] >= 300
      raise "ReShare Authentication Failed: Could not create a token for #{USER}"
    end

    response[:token]
  end

  def fetch_patron_requests(token)
    uri = URI("#{API_URL}/rs/patronrequests?match=patronIdentifier&term=#{NET_ID}&perPage=1&state.terminal==false")
    request = Net::HTTP::Get.new(uri)
    request["X-Okapi-Tenant"] = TENANT
    request["x-okapi-token"] = token
    request["Accept"] = "application/json"

    Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.request(request)
    end
  end
end

