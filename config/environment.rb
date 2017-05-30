# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
BlacklightCornell::Application.initialize!

ActionMailer::Base.smtp_settings = {
  :from => "culsearch@cornell.edu",
  :address    => 'appsmtp.mail.cornell.edu',
}
MARC::XMLReader.nokogiri!
BlacklightCornellRequests::VoyagerRequest.use_rest(true)
BlacklightCornellRequests.config do |config|
#  # URL of service which returns JSON holding info.
  config.voyager_holdings = "http://" + (ENV['VOYAGER_HOLDINGS_HOST']  ?
                   ENV['VOYAGER_HOLDINGS_HOST']  :
                   ENV['HOLDINGSHOST'])
  config.voyager_get_holds = ENV['VXWS_URL'] +"/GetHoldingsService"
  config.voyager_req_holds = ENV['VXWS_URL'] + "/SendPatronRequestService"
  config.voyager_req_holds_rest = ENV['VXWS_URL']

  ## URL of metasearch service
  config.borrow_direct_webservices_host = "http://localhost"
  config.borrow_direct_webservices_port = 9004
end

class Logger
  def format_message(severity, timestamp, progname, msg)
    "[#{timestamp}] #{severity}  (#{$$}) #{msg}\n"
  end
end
