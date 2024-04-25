
# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
BlacklightCornell::Application.initialize!

ActionMailer::Base.smtp_settings = {
  :from => ENV["SMTP_FROM"],
  :address    => ENV["SMTP_ADDRESS"],
}
MARC::XMLReader.nokogiri!
BlacklightCornellRequests.config do |config|
  ## URL of metasearch service
  config.borrow_direct_webservices_host = "http://localhost"
  config.borrow_direct_webservices_port = 9004
end

class Logger
  def format_message(severity, timestamp, progname, msg)
    "[#{timestamp}] #{severity}  (#{$$}) #{msg}\n"
  end
end
