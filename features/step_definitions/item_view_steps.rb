Given /^I request the item view for (.*?)$/ do |bibid|
  visit "/catalog/#{bibid}"
end

When /^(.*) within a cassette named "([^"]*)"$/ do |step, cassette_name|
  VCR.use_cassette(cassette_name) { When step }
end


Given /^I request the item holdings view for (.*?)$/ do |bibid|
  visit "/backend/holdings/#{bibid}"
end

Then /^click on link "(.*?)"$/ do |link|
  # click <a> text that contains link
  click_link link
end

Then /^click on first link "(.*?)"$/ do |link|
  # click first <a> text that contains link
  page.first(:xpath, "//a[contains(.,'#{link}')]").click
end

Given("I text the first available item") do
  within(page.first(".holding")) do
    page.find('#smsLink').trigger('click')
  end
end

Then("I click and confirm {string}") do |string|
  accept_confirm do
    page.find('a', :text => string).trigger('click')
  end
end

Then("I click and cancel {string}") do |string|
  dismiss_confirm do
    page.find('a', :text => string).trigger('click')
  end
end

Then /^results should contain "(.*?)" with value "(.*?)"$/ do |field, author|
  page.should have_selector(field_to(field), :text => author,:exact =>false )
end

Then /^it should contain "(.*?)" with value "(.*?)"$/ do |field, author|
  page.should have_selector(field_result_to(field), :text => author,:exact =>false )
end

Then /^it should have link ["'](.*?)["'] with value ["'](.*?)["']$/ do |txt, alink|
  #print page.html
  expect(page).to have_link(txt, :href =>alink)
  #res.should == true
end

Then /^it should have a "(.*?)" that looks sort of like "(.*?)"/ do |field, author|
  #page.should have_selector(field_to(field), :text => author,:exact =>false)
  page.should have_selector(field_to(field))
end

Then /^results should have a "(.*?)" that looks sort of like "(.*?)"/ do |field, author|
  page.should have_selector(field_result_to(field), :text => author,:exact =>false)
end

Then /^I (should|should not) see the label '(.*?)'$/ do |yesno, label|
  if yesno == "should not"
	page.should_not have_content(label)
  else
  	page.should have_content(label)
  end
end

Then /^I (should|should not) see the label '(.*?)' And I should see the label '(.*?)'$/ do |yesno, label,label2|
  if yesno == "should not"
	page.should_not have_content(label) and page.should have_content(label2)
  else
  	page.should have_content(label) and  page.should have_content(label2)
  end
end

Then /^I (should|should not) see the labels '(.*?)'$/ do |yesno, llist|
  labels = llist.split(',')
  if yesno == "should not"
        labels.each do |label|
	  page.should_not have_content(label)
        end
  else
        labels.each do |label|
	  page.should have_content(label)
        end
  end
end

Then(/^in modal ['"](.*?)['"] I should see label ['"](.*?)['"]$/) do |modal,label|
  within(modal) do
    page.should have_content(label) # async
  end

end
