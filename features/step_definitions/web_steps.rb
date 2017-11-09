Given /^(?:|I )am on (.+)$/ do |page_name|
  visit path_to(page_name)
end

When /^(?:|I )fill in "([^"]*)" with ['"]([^'"]*)['"]$/ do |field, value|
  fill_in(field, :with => value)
end

When /^(?:|I )fill in "([^"]*)" with quoted ['"]([^'"]*)['"]$/ do |field, value|
  fill_in(field, :with => '"' + value + '"')
end


When /^(?:|I )press '([^"]*)'$/ do |button|

  if button == 'search'
    page.find(:css, 'button#search-btn').click
  else
    click_button button
  end
end

When /^(?:|I )press "([^"]*)"$/ do |button|

  if button == 'search'
    page.find(:css, 'button#search-btn').click
  else
    click_button button
  end
end

When /^(?:|I )select radio "([^"]*)"$/ do |button|
    choose(button)
end

When /^(?:|I )go to (.+)$/ do |page_name|
  visit path_to(page_name)
end

When /^(?:|I )literally go to (.+)$/ do |page_name|
  visit page_name
end

Then /^(?:|I )should be on (.+)$/ do |page_name|
  current_path = URI.parse(current_url).path
  if current_path.respond_to? :should
    current_path.should == path_to(page_name)
  else
    assert_equal path_to(page_name), current_path
  end
end

Then /^show me the page$/ do
  print page.html
end

Then /^show me the page source$/ do
  print page.source
end

Then /^I should not see an error$/ do
  (200 .. 399).should include(page.status_code)
end

Then /^I should see an error$/ do
  (400 .. 599).should include(page.status_code)
end

Then(/^I sleep (\d+) seconds$/) do |wait_seconds|
  sleep wait_seconds.to_i 
end

When /^I accept popup$/ do
  page.evaluate_script('window.confirm = function() { return true; }')
  #page.driver.browser.switch_to.alert.accept    
end

When /^I dismiss popup$/ do
  page.evaluate_script('window.confirm = function() { return false; }')
  page.dismiss_confirm { click_link "Delete" }
  #page.driver.browser.switch_to.alert.dismiss
end

When /^(?:|I )cancel popup "([^"]*)"$/ do |link|
  page.dismiss_confirm { click_link link }
end

When /^(?:|I )confirm popup "([^"]*)"$/ do |link|
  page.accept_confirm { click_link link }
end

