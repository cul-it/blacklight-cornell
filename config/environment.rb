# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
BlacklightCornell::Application.initialize!

ActionMailer::Base.smtp_settings = {
  :from => "culsearch@cornell.edu",
  :address    => 'appsmtp.mail.cornell.edu',
}
BlacklightCornellRequests::VoyagerRequest.use_rest(true) 
BlacklightCornellRequests.config do |config|
  # URL of service which returns JSON holding info.
  config.voyager_holdings = ENV['VOYAGER_HOLDINGS_HOST']  ?
                   ENV['VOYAGER_HOLDINGS_HOST']  :
                   "http://culholdingsdev.library.cornell.edu" 
  config.voyager_get_holds = "http://catalog-test.library.cornell.edu:7074/vxws/GetHoldingsService"
  config.voyager_req_holds = "http://catalog-test.library.cornell.edu:7074/vxws/SendPatronRequestService"

  ## URL of metasearch service
  config.borrow_direct_webservices_host = "http://localhost"
  config.borrow_direct_webservices_port = 9004
end

