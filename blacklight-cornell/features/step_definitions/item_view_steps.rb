# encoding: utf-8
Given /^I request the item view for (.*?)$/ do |bibid|
  patiently do
    do_visit "/catalog/#{bibid}"
    page.find("#doc_#{bibid}", visible: :all)
  end
end

Given /^I attempt the item view for (.*?)$/ do |bibid|
  # this version does not check for bibid exists
  do_visit "/catalog/#{bibid}"
end

Given("I request the export of item {int} in {string} format") do |int, string|
  do_visit "/catalog/#{int}.#{string}"
end

When /^(.*) within a cassette named "([^"]*)"$/ do |step, cassette_name|
  VCR.use_cassette(cassette_name) { When step }
end

Given /^I request the item holdings view for (.*?)$/ do |bibid|
  do_visit "/backend/holdings/#{bibid}"
end

Given("I request the item") do
  page.find("#id_request").click
end

Then /^(?:|I )click on link "(.*?)"$/ do |link|
  # click <a> text that contains link
  click_link link
end

Then /^click on first link "(.*?)"$/ do |link|
  # click first <a> text that contains link
  page.first(:xpath, "//a[contains(.,'#{link}')]").click
end

Then("I click and confirm {string}") do |string|
  accept_confirm do
    click_link(string)
  end
end

Then("I click and cancel {string}") do |string|
  dismiss_confirm do
    click_link(string)
  end
end

Then /^results should contain "(.*?)" with value "(.*?)"$/ do |field, author|
  page.should have_selector(field_to(field), :text => author, :exact => false)
end

Then /^it should contain "(.*?)" with value "(.*?)"$/ do |field, author|
  page.should have_selector(field_result_to(field), :text => author, :exact => false)
end

Then /^it should have link ["'](.*?)["'] with value ["'](.*?)["']$/ do |txt, alink|
  #print page.html
  expect(page).to have_link(txt, :href => alink)
  #res.should == true
end

Then /^it should have a "(.*?)" that looks sort of like "(.*?)"/ do |field, author|
  #page.should have_selector(field_to(field), :text => author,:exact =>false)
  page.should have_selector(field_to(field))
end

Then /^results should have a "(.*?)" that looks sort of like "(.*?)"/ do |field, author|
  patiently do
    expect(page.first(field_result_to(field))).to have_content(author)
    # page.should have_selector(field_result_to(field), :text => author,:exact =>false)
  end
end

Then /^I (should|should not) see the label '(.*?)'$/ do |yesno, label|
  if yesno == "should not"
    page.should_not have_content(label)
  else
    page.should have_content(label)
  end
end

Then /^I (should|should not) see the label '(.*?)' And I should see the label '(.*?)'$/ do |yesno, label, label2|
  if yesno == "should not"
    page.should_not have_content(label) and page.should have_content(label2)
  else
    page.should have_content(label) and page.should have_content(label2)
  end
end

Then /^I (should|should not) see the labels '(.*?)'$/ do |yesno, llist|
  labels = llist.split(",")
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

Then(/^in modal ['"](.*?)['"] I should see label ['"](.*?)['"]$/) do |modal, label|
  within(modal) do
    page.should have_content(label) # async
  end
end

Then("it should have title {string}") do |string|
  expect(page.find("div.document-header > h2")).to have_content(string)
end

Then("it should have the heading {string}") do |string|
  expect(page.find("h2")).to have_content(string)
end

Then("it should have a discogs disclaimer") do
  expect(page).to have_css("#discogs_disclaimer")
end
