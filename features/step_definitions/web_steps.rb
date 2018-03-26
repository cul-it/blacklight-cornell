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

Then("I should see a link {string}") do |string|
  page.find("a", :text => "#{string}")
end

Then("I should see the CUWebLogin page") do
  page.find("h1", :text => "CUWebLogin")
  page.find("input.input-submit")
  page.find("a", :text => "IT Service Desk")
  page.find("a", :text => "I don't have a NetID, now what?")
end

Then("I select the first {int} catalog results") do |int|
  @all_checkboxes = page.all(:css, "input.toggle_bookmark")
  i = 0
  while i < int
    page.find(:xpath, @all_checkboxes[i].path).set(true)
    i += 1
  end
end

Then /^there should be ([0-9+]) items selected$/ do |int|
  page.find(:xpath, '//span[@data-role="bookmark-counter"]').text.should match(int)
end

Then("Sign in should link to the SAML login system") do
  page.find(:xpath, "//a[@href='/users/auth/saml']", :text => "Sign in")
end

Then("Sign in should link to Book Bags") do
  page.find(:xpath, "//a[@href='/book_bags/index']", :text => "Sign in")
end

When("I view my selected items") do
  visit '/bookmarks'
end

When("I view my citations") do
  what_is()
  page.find(:xpath, '//a[@id="citeLink"]').click
end

def what_is(element)
  puts "\n********************* what is V\n"
  puts page.current_url.inspect
  puts element.inspect
  puts element['innerHTML']
  puts "\n********************* what is ^\n"
end

Then /^show me id "(.*)"$/ do |string|
  @path = "\/\/*[@id=\"#{string}\"]"
  @chunk = page.find(:xpath, @path)
  what_is(@chunk)
end
