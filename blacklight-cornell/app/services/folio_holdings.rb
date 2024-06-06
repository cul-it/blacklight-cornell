require "net/http"
require_relative "edge"

class FolioHoldings < StatusPage::Services::Base
  def folio_request(request)
    url = ENV["OKAPI_URL"]
    tenant = ENV["OKAPI_TENANT"]
    response = CUL::FOLIO::Edge.authenticate(url, tenant, ENV["OKAPI_USER"], ENV["OKAPI_PW"])
    if response[:code] >= 300
      raise "Authentication failed"
    end
    token = response[:token]
  def check!
    response = CUL::FOLIO::Edge.patron_record(ENV["OKAPI_URL"], ENV["OKAPI_TENANT"], ENV["OKAPI_USER"], ENV["OKAPI_PW"])
    #******************
    save_level = Rails.logger.level; Rails.logger.level = Logger::WARN
    jgr25_context = "#{__FILE__}:#{__LINE__}"
    Rails.logger.warn "jgr25_log\n#{jgr25_context}:"
    msg = [" #{__method__} ".center(60, "Z")]
    msg << jgr25_context
    msg << "response: " + response.inspect
    msg << "Z" * 60
    msg.each { |x| puts "ZZZ " + x.to_yaml }
    Rails.logger.level = save_level
    #binding.pry
    #*******************
  end
end
