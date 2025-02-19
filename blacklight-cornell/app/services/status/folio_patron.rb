require "net/http"
require "cul/folio/edge"

module Status
  class FolioPatron < StatusPage::Services::Base

    def folio_patron_token
      url    = ENV["OKAPI_URL"]
      tenant = ENV["OKAPI_TENANT"]
      user   = ENV["OKAPI_USER"]
      pw     = ENV["OKAPI_PW"]

      if url.nil? || tenant.nil? || user.nil? || pw.nil?
        raise "Folio environment variables not set"
      end

      response = CUL::FOLIO::Edge.authenticate(url, tenant, user, pw)

      if response[:code] >= 300
        raise "Authentication failed: #{response[:code]}  #{response[:message]}"
      end

      response[:token] # Return the token
    end

    def check!
      begin
        token    = folio_patron_token
        response = CUL::FOLIO::Edge.patron_record(ENV["OKAPI_URL"], ENV["OKAPI_TENANT"], token, ENV["OKAPI_USER"])
      rescue StandardError => e
        raise "Folio Patron: #{e.message}"
      end

      if response[:code] >= 300
        raise "Patron record not found"
      end
    end
  end
end