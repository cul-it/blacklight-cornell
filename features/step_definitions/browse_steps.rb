When /^I fill in the authorities search box with '(.*?)'$/ do |query|
  query.gsub!(/\\"/, '"')
  fill_in('authq', :with => query)
end

Given /^I request the personal name author item view for (.*?)$/ do |author|
  visit "/browse/info?authq=#{author}&browse_type=Author&headingtype=Personal%20Name"
end

Given /^I request the geographic name subject item view for (.*?)$/ do |subject|
  visit "/browse/info?authq=#{subject}&browse_type=Subject&headingtype=Geographic%20Name"
end

Given /^I request the author title item view for (.*?)$/ do |at|
  visit "/browse/info?authq=#{at}&browse_type=Author-Title"
end

Given /^I click a link with text '(.*?)' within '(.*?)'$/ do |text, id|
  find(:xpath, "//*[@id='#{id}']//a[text()='#{text}']", visible:false).click
end

Given /^I click '(.*?)' in the first page navigator$/ do |text|
  within(:xpath, "(//div[contains(@class, 'results-count')])[1]") do
    click_link(text)
  end
end

Given /^I click '(.*?)' in the last page navigator$/ do |text|
  within(:xpath, "(//div[contains(@class, 'results-count')])[last()]") do
    click_link(text)
  end
end