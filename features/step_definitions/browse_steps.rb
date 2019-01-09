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
  within (page.find(:id, id).find(:xpath,"//a[text()='#{text}']", visible: :all)) {
    click_link(text);
  }
end