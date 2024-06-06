require "net/http"

class FolioHoldings < StatusPage::Services::Base
  def folio_request(request)
    url = ENV["OKAPI_URL"]
    tenant = ENV["OKAPI_TENANT"]
    response = CUL::FOLIO::Edge.authenticate(url, tenant, ENV["OKAPI_USER"], ENV["OKAPI_PW"])
    if response[:code] >= 300
      raise "Authentication failed"
    end
    token = response[:token]

    if request && token
      headers = {
        "X-Okapi-Tenant" => ENV["TENANT_ID"],
        "x-okapi-token" => token,
        :accept => "application/json, application/vnd.api+json",
      }
      #******************
      save_level = Rails.logger.level; Rails.logger.level = Logger::WARN
      jgr25_context = "#{__FILE__}:#{__LINE__}"
      Rails.logger.warn "jgr25_log\n#{jgr25_context}:"
      msg = [" #{__method__} ".center(60, "Z")]
      msg << jgr25_context
      msg << "headers: " + headers.inspect
      msg << "Z" * 60
      msg.each { |x| puts "ZZZ " + x.to_yaml }
      Rails.logger.level = save_level
      #binding.pry
      begin
        response = RestClient.get(request, headers)
      rescue RestClient::ExceptionWithResponse => e
        raise "RestClient exception: #{e.response}"
      end
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
      if response && response.code == 200
        JSON.parse(response.body)
      else
        raise "Failed to get a good response"
      end
    end
  end

  def check!
    issn = "1050-3331"
    id = "12769773"
    title_id = "14046327"
    url = "#{ENV["OKAPI_URL"]}/eholdings/titles/#{title_id}&include=resources"

    #******************
    save_level = Rails.logger.level; Rails.logger.level = Logger::WARN
    jgr25_context = "#{__FILE__}:#{__LINE__}"
    Rails.logger.warn "jgr25_log\n#{jgr25_context}:"
    msg = [" #{__method__} ".center(60, "Z")]
    msg << jgr25_context
    msg << "url: " + url.inspect
    msg << "Z" * 60
    msg.each { |x| puts "ZZZ " + x.to_yaml }
    Rails.logger.level = save_level
    #binding.pry
    #*******************

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
  end
end
