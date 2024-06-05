require "net/http"
require "folio_requester"

class FolioHoldings < StatusPage::Services::Base
  include FolioRequester

  def check!
    title_id = 1720322
    url = "#{ENV["OKAPI_URL"]}/eholdings/titles/#{title_id}?include=resources"
    response = folio_request(url)

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
    if response.present?
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
