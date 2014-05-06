When /^I fill in the search box with '(.*?)'$/ do |query|
  query.gsub!(/\\"/, '"')
  fill_in('q', :with => query)
end

Then /^there should be at least (\d+) search results?$/ do |count|
 # print page.html
  page.find("meta[name=totalResults]")['content'].to_i.should >= count.to_i
end

Then /^there should be (\d+) search results$/ do |count|
 # print page.html
  page.find("meta[name=totalResults]")['content'].to_i.should == count.to_i
end

Then /^I should see 'Displaying all (\d+) items' or I should see 'Displaying items (\d+) \- (\d+) of (\d+)'$/ do |arg1, arg2, arg3, arg4|
 # print page.html
  (page.should have_content("Displaying all #{arg1} items")) || (page.should have_content("Displaying items #{arg2} - #{arg3} of #{arg4}"))

end

Then /^I should not see a list of search results$/ do
  #page.has_selector?('div#documents')
  page.has_selector?('#documents')
end

Then /^I should see the per_page select list$/ do
  page.should have_selector('#per_page-dropdown')
end

Then /^the '(.*?)' select list should default to '(.*?)'$/ do |list, option|
  page.find('#' + list + '-dropdown ul.css-dropdown li.btn > a').text.should == option
end

Then /^the '(.*?)' select list should have an option for '(.*?)'$/ do |list, option|
  page.all('#' + list + '-dropdown ul.css-dropdown li.btn li', :text => option)
end

Then /^I should see each item format$/ do
  within('#documents') do
  	page.should have_css('.blacklight-title_display')
  	page.should have_css('.blacklight-author_display')
  end
end

Then /^results should have a select checkbox$/ do
  within('#documents') do
  	page.should have_selector('.bookmark_add')
  end
end

Then /^results should have a title field$/ do
  within('#documents') do
    page.should have_css('.blacklight-title_display')
  end
end

Then /^it should contain filter "(.*?)" with value "(.*?)"/ do |filter, value|
  page.should have_selector('span.filter-label', :text => filter)
  page.should have_selector('span.filter-value', :text => value)
end
