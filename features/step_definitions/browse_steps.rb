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
  find(:xpath, "//div[@id='#{id}']//a[text()='#{text}']", visible:false).click
end

Then("call number {string} should be available in {string}") do |title, location|
  # check that both are in the same table row
  page.all("table.browse-callnumber > tbody > tr").each do |tr|
    next unless tr.has_selector?('td', text: title)

    what_is(tr)
  end
  sleep 2
  patiently do
    expect(find(:xpath, "//td", :text => title, :visible => :all).first(:xpath, "//td" , :text => location, :visible => :all)).to have_content(location)
  end
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