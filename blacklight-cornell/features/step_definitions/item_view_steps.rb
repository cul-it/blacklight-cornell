# encoding: utf-8
Given /^I request the item view for (.*?)$/ do |bibid|
  patiently do
    visit "/catalog/#{bibid}"
    page.find("#doc_#{bibid}", visible: :all)
  end
end

Given /^I attempt the item view for (.*?)$/ do |bibid|
  # this version does not check for bibid exists
  visit "/catalog/#{bibid}"
end

Given("I request the export of item {int} in {string} format") do |int, string|
  visit "/catalog/#{int}.#{string}"
end

When /^(.*) within a cassette named "([^"]*)"$/ do |step, cassette_name|
  VCR.use_cassette(cassette_name) { When step }
end

Given /^I request the item holdings view for (.*?)$/ do |bibid|
  visit "/backend/holdings/#{bibid}"
end

Given("I request the item") do
  page.find("#id_request").click
end

Then /^(?:|I )click on link "(.*?)"$/ do |link|
  # click <a> text that contains link
  click_link link
end

# click first <a> text that contains link
Then /^click on first link "(.*?)"$/ do |link|
  click_first_link_by_text!(link)
end

# ==============================================================================
# Clicks the first <a> whose *visible text* includes the given snippet.
# Normalizes whitespace *and* non-breaking spaces (&nbsp;) so DOM formatting
# (nested spans, linebreaks, NBSPs) won't break text matching.
# ------------------------------------------------------------------------------
def click_first_link_by_text!(snippet)
  normalize = ->(s) { s.gsub(/\u00A0/, ' ').gsub(/\s+/, ' ').strip }

  target = normalize.call(snippet)
  link = all('a').find { |a| normalize.call(a.text).include?(target) }

  unless link
    puts "[DEBUG] Wanted link containing: #{target.inspect}"
    puts "[DEBUG] Available <a> texts (normalized):"
    all('a').each { |a| puts "- #{normalize.call(a.text)}" }
    raise Capybara::ExpectationNotMet, "No link containing #{target.inspect}"
  end

  link.click
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

Then(/^I (should|should not) see the label '(.*?)'$/) do |yesno, expected|
  page_text = page.text.tr("\u00A0", ' ') # Normalize NBSPs
  # Start from an escaped version of the expected text
  pattern = Regexp.escape(expected)
  # Allow optional colon and optional operator between label and value
  pattern = pattern.gsub(/\\:/, ':?\\s*(?:All|Any|Begins\\ With|Phrase)?\\s*')
  # turn *escaped spaces* (`\ `) into `\s+`
  pattern = pattern.gsub(/\\[[:space:]]+/, '\\s+')
  # collapse multiple \s+
  pattern = pattern.gsub(/(?:\\s\+){2,}/, '\\s+')

  regex = Regexp.new(pattern, Regexp::MULTILINE)

  if yesno == 'should'
    expect(page_text).to match(regex)
  else
    expect(page_text).not_to match(regex)
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
