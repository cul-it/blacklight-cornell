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

Then /^I should not see the "([^\"]*)" element$/ do |id|
   page.should_not have_selector("##{id}")
end

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

@javascript
Then /^I should get results$/ do
  patiently do
    page.find(:css, "#documents")
  end
end

Then("I should get {int} results") do |int|
  patiently do
    expect(page.find(:css, "span#total-search-results")).to have_content(int)
  end
end

Then("I should have about {int} results") do |int|
  patiently do
    actual = page.find(:css, "span#total-search-results").text.to_i
    expect(actual).to be_within(10).of(int)
  end
end

Then /^I should not get results$/ do
  page.should_not have_selector("div.document")
end

Then("the search results should not contain title {string}") do |string|
  patiently do
    docs = page.all(:css, "div.document-data h2.blacklight-title_display a")
    docs.each do |doc|
      expect(doc.text).not_to include(string)
    end
  end
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

# this step requires .env to include DEBUG_USER and the development environment
When("I sign in to BookBag") do
	visit 'book_bags/index'
  # 'Sign In' blacklight-nav link is not available on Jenkins since
  # ENV['SAML_IDP_TARGET_URL’] is undefined there
  within "#main-container" do
    click_button "Sign in to email items or save them to Book Bag"
  end
  # wait for the redirect to happen
  expect(page).not_to have_content("Sign in to email items or save them to Book Bag")
end

Then("I should see {int} as the result number") do |int|
  expect(page.first('div.item-pagination > strong')).to have_content("#{int.to_s}")
end

Then("I remove facet constraint {string}") do |string|
  page.find(".selected-facets .filter-value", text: string).click
end

Then("I should see the {string} facet constraint") do |facet_label|
  page.should have_selector(".selected-facets .filter-label", text: facet_label)
end

Then("I should see only the first {int} Format facets") do |int|
  items = page.all('div#facet-format ul.facet-values > li')
  if items.count > 10
    expect(page).to have_selector('div#facet-format ul.facet-values > li', count: 11)
    expect(page).to have_selector('div#facet-format ul.facet-values > li.more_facets')
  end
end

Given("I search for everything") do
  fill_in('q', :with => '', fill_options: { clear: :backspace })
  page.find(:css, 'button#search-btn').click
end

Then("the Search Articles & Full Text link url should contain {string} but not {string}") do |string, string2|
  looking_for_more = find("#facets .expand-search")
  within looking_for_more do
    articles = find("a", :text => "Search Articles & Full Text")
    url = articles[:href]
    expect(url).to match(string)
    expect(url).not_to match(string2)
  end
end