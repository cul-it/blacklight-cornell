# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
BlacklightCornell::Application.initialize!

ActionMailer::Base.smtp_settings = {
  :from => "culsearch@cornell.edu",
  :address    => 'appsmtp.mail.cornell.edu',
}

