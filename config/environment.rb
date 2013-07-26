# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
BlacklightCornell::Application.initialize!

ActionMailer::Base.smtp_settings = {
  :from => "culsearch@cornell.edu",
  :address    => 'appsmtp.mail.cornell.edu',
}

BlacklightCornellRequests.config do |config|
  # URL of service which returns JSON holding info.
 config.voyager_holdings = ENV['VOYAGER_HOLDINGS_HOST']  ?
                   ENV['VOYAGER_HOLDINGS_HOST']  :
                   "http://culholdingsdev.library.cornell.edu" 
  config.voyager_get_holds= "http://catalog-test.library.cornell.edu:7074/vxws/GetHoldingsService"
  
  # URL of service which handles item requests
  config.voyager_request_handler_host = "http://culholdingsdev.library.cornell.edu"
  config.voyager_request_handler_port = 80

  ## URL of metasearch service
  config.borrow_direct_webservices_host = "http://localhost"
  config.borrow_direct_webservices_port = 9004
end

