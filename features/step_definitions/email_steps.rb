Then /^"([^"]*)" receives an email with "([^"]*)" as the subject$/ do |email_address, subject|
  open_email(email_address)
  expect(current_email.subject).to eq subject
end

Then /^.*show all emails$/ do
   print all_emails.inspect
end

Then /^"([^"]*)" receives an email with "([^"]*)" in the content$/ do |email_address, content|
  open_email(email_address)
  expect(current_email.body).to include(content) 
end

#Then I should see "Marvel masterworks" in the email body
Then /^current email has  "([^"]*)" in the content$/ do |content|
  expect(current_email.body).to include(content) 
end

#Then I should see "Marvel masterworks" in the email body
Then /^I should see "([^"]*)" in the email body$/ do |content|
  expect(current_email.body).to include(content) 
end
