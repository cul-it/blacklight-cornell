require "net/http"
require_relative "edge"

class FolioPatron < StatusPage::Services::Base
  def folio_token
    url = ENV["OKAPI_URL"]
    tenant = ENV["OKAPI_TENANT"]
    response = CUL::FOLIO::Edge.authenticate(url, tenant, ENV["OKAPI_USER"], ENV["OKAPI_PW"])
    if response[:code] >= 300
      raise "Authentication failed"
    end
    token = response[:token]
  end

  def check!
    begin
      token = folio_token
      response = CUL::FOLIO::Edge.patron_record(ENV["OKAPI_URL"], ENV["OKAPI_TENANT"], token, ENV["OKAPI_USER"])
      if response[:code] >= 300
        raise "Patron record not found"
      end
    rescue StandardError => e
      raise "Folio Patron: #{e.message}"
    end
  end
end
