# -*- encoding : utf-8 -*-
# User added
Then /^I should see a search field$/ do
  page.should have_selector("input#q")
end

Then /^I should see a selectable list with field choices$/ do
  page.should have_selector("select#search_field")
end

# Then /^I should see a selectable list with per page choices$/ do
#   page.should have_selector("select#per_page")
# end

Then /^I should see a "([^\"]*)" button$/ do |label|
  page.should have_selector('button.btn-search')
end

#Then /^I should see a "([^\"]*)" button$/ do |label|
#  page.should have_selector("#{label}")
#end

Given /^I select ["'](.*?)["'] from the ["'](.*?)["'] drop\-down$/ do |option, menu|
  #select(option, :from => menu)
  find('#' + menu).find(:option,"#{option}").select_option
end

# Then /^I should not see the "([^\"]*)" element$/ do |id|
#   page.should_not have_selector("##{id}")
# end

Then /^I should see the "([^\"]*)" element$/ do |id|
   page.should have_selector("##{id}")
end

Then(/^I should see the "([^\"]*)" class$/) do |id|
   page.should have_selector(".#{id}")
end

#Then(/^I should see the 'fa\-on\-site' class (\d+) times$/) do |arg1|
#Then(/^I should see the "([^\"]*)" class (\d+) times$/) do |id, times|
Then(/^I should see the "([^\"]*)" class (\d+) times$/) do |id, times|
   page.should have_css(".#{id}", :count => times)
end

# Given /^the application is configured to have searchable fields "([^\"]*)" with values "([^\"]*)"$/ do |fields, values|
#   labels = fields.split(", ")
#   values = values.split(", ")
#   combined = labels.zip(values)
#   CatalogController.blacklight_config[:search_fields] = []
#   combined.each do |pair|
#     CatalogController.blacklight_config[:search_fields] << pair
#   end
# end

# Then /^I should see select list "([^\"]*)" with field labels "([^\"]*)"$/ do |list_css, names|
#   page.should have_selector(list_css) do
#     labels = names.split(", ")
#     labels.each do |label|
#       with_tag('option', label)
#     end
#   end
# end

# Then /^I should see select list "([^\"]*)" with "([^\"]*)" selected$/ do |list_css, label|
#   page.should have_selector(list_css) do |e|
#     with_tag("[selected=selected]", {:count => 1}) do
#       with_tag("option", {:count => 1, :text => label})
#     end
#   end
# end

# # Results Page
# Given /^the application is configured to have sort fields "([^\"]*)" with values "([^\"]*)"$/ do |fields, values|
#   labels = fields.split(", ")
#   values = values.split(", ")
#   combined = labels.zip(values)
#   CatalogController.blacklight_config[:sort_fields] = []
#   combined.each do |pair|
#     CatalogController.blacklight_config[:sort_fields] << pair
#   end
# end

Then /^I should get results$/ do
  page.should have_selector(".document")
end

Then /^I should not get results$/ do
  page.should_not have_selector("div.document")
end

# Then /^I should see the applied filter "([^\"]*)" with the value "([^\"]*)"$/ do |filter, text|
#   page.should have_selector("div#facets div h3", :content => filter)
#   page.should have_selector("div#facets div span.selected", :content => text)
# end

Then /^I should see an RSS discovery link/ do
 page.should have_selector("link[rel='alternate'][type='application/rss+xml']",visible:false)
 #page.body.should have_xpath("//link",visible:false)
 #page.should have_xpath("//link[@rel='alternate' and @type='application/rss+xml']",visible:false)
end

Then /^I should see an Atom discovery link/ do
  page.should have_selector("link[rel=alternate][type='application/atom+xml']",visible:false)
end

Then /^I should see OpenSearch response metadata tags/ do
  page.should have_selector("meta[name=totalResults]",visible:false)
  page.should have_selector("meta[name=startIndex]",visible:false)
  page.should have_selector("meta[name=itemsPerPage]",visible:false)
end

# Then /^I should see the applied filter "([^\"]*)" with the value
# "([^\"]*)"$/ do |filter, text|
#  page.should have_tag("div#facets div") do |node|
#    node.should have_selector("h3", :content => filter)
#    node.should have_selector("span.selected", :content => /#{text}.*/)
#  end
# end

