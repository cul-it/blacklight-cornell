require 'spreewald/web_steps'

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

Then /^debug with pry$/ do
  binding.pry
end

Then /^I should not see an error$/ do
  (200 .. 399).should include(page.status_code)
end

Then /^I should see an error$/ do
  (400 .. 599).should include(page.status_code)
end

Then(/^I sleep (\d+) seconds?$/) do |wait_seconds|
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

Then("I should see a button {string}") do |string|
  page.find("button", :text => "#{string}")
end

Then("I should not see a link {string}") do |string|
  expect(page).not_to have_selector("a", :text => "#{string}")
end

Then("I should not see a button {string}") do |string|
  expect(page).not_to have_selector("button", :text => "#{string}")
end

Then("I should see the CUWebLogin page") do
  begin
    expect(page).to have_title "Cornell University Web Login"
    page.should have_content("CUWebLogin")
    page.should have_content("Cornell University")
    form = page.find("form#login")
    form.should have_selector("input#username")
    form.should have_selector("input#password")
  rescue Capybara::ElementNotFound => e
    page.should have_content("An error occurred while processing your request.")
    page.should have_content("Error Message: Message Security Error")
    puts URI.parse(current_url).path
    puts "On login page, but CUWebLogin not available"
  end
end


Then("I select the first {int} catalog results") do |int|
  @all_checkboxes = page.all(:css, "input.toggle-bookmark")
  @confirm = page.all(:css, "label.toggle-bookmark")
  i = 0
  while i < int
    page.find(:xpath, @all_checkboxes[i].path).set(true)
    i += 1
  end
  # wait for the ajax processing until the item shows up checked
  while i < int
    page.find(:xpath, @confirm[i].path).should have_content("Selected")
    i += 1
  end
end

Then /^there should be ([0-9]+) items selected$/ do |int|
  expect(page.find(:xpath, '//span[@data-role="bookmark-counter"]')).to have_content(int)
end

Then("navigation should show Book Bag contains {int}") do |int|
  page.find('a#book_bags_nav > span > span', text: "#{int.to_s}")
end

Then /^navigation should( not)? show '([^']*)'$/ do |negation, string|
  patiently do
    negation ? page.first('ul.blacklight-nav').should_not(have_content(string)) : page.first('ul.blacklight-nav').should(have_content(string))
  end
end

Then("the BookBag should be empty") do
  expect(page.find('div.results-info')).to have_content('You have no selected items.')
end

Then /^there should be ([0-9]+) items? in the BookBag$/ do |int|
  if int == "0"
    expect(page.find('div.results-info')).to have_content('You have no selected items.')
  else
    within ('div.results-info') do
      if int == "1"
        expect(find('.page-entries')).to have_content('1 result')
      else
        expect(find('.page-entries')).to have_content("1 - #{int.to_s} of #{int.to_s}")
      end
    end
  end
end

Then /^navigation should show ([0-9]+) items? in the BookBag$/ do |int|
  expect(page.find('span[data-role="bookmark-counter"]')).to have_content("#{int.to_s}")
end

Then("navigation should show the BookBag with no item count") do
  patiently do
    within page.find('#book_bags_nav') do
      find('span', text: "Book Bag")
     end
  end
end

Given("I empty the BookBag") do
	visit 'book_bags/clear'
end

Then("Sign in should link to the SAML login system") do
  if ENV['GOOGLE_CLIENT_ID']
    page.find(:xpath, "//a[@href='/logins']", :text => "Sign in")
  else
    page.find(:xpath, "//a[@href='/users/auth/saml']", :text => "Sign in")
  end
end

Then("Sign in should link to the login systems") do
  page.find(:xpath, "//a[@href='/logins']", :text => "Sign in")
end

Then("I should see a link to Book Bags") do
  page.find(:xpath, "//a[@href='/book_bags/index']")
end

When("I view my selected items") do
	visit '/bookmarks'
end

When("I view my bookmarks") do
	visit '/bookmarks'
end

Then("I disable ajax activity completion") do
  # true/enable is the default - wait for javascript activity to finish after each step
  $wait_for_ajax_to_run = false
end

Then("I enable ajax activity completion") do
  # true/enable is the default - wait for javascript activity to finish after each step
  $wait_for_ajax_to_run = true
end

When("I view my citations") do
  page.find(:xpath, '//a[@id="citationLink"]').click
end

Then("I view my citations in form {string}") do |string|
  within page.find("ul#item-tools") do
    page.find(:css, "a#cite-menu", visible: false).click
    page.find(:xpath, "//*[text()=\"#{string}\"]").click
  end
end

Then("where am I") do
  puts "\n********************* where am I V\n"
  where_am_i
  puts "\n********************* where am I ^\n"
end

def what_is(element)
  puts "\n********************* what is V\n"
  puts URI.parse(current_url).path
  puts "\n"
  puts element.inspect
  puts "\n"
  puts element.native.inner_html
  puts "\n"
  puts "\n********************* what is ^\n"
end

Then /^show me id "(.*)"$/ do |string|
  @path = "\/\/*[@id=\"#{string}\"]"
  @chunk = page.find(:xpath, @path)
  what_is(@chunk)
end

Then /^show me xpath "(.*)"$/ do |string|
  @chunk = page.find(:xpath, "#{string}")
  what_is(@chunk)
end

Then /^show me hidden id "(.*)"$/ do |string|
  @path = "\/\/*[@id=\"#{string}\"]"
  @chunk = page.find(:xpath, @path, visible: false)
  what_is(@chunk)
end

Then /^show me hidden xpath "(.*)"$/ do |string|
  @chunk = page.find(:xpath, string, visible: false)
  what_is(@chunk)
end

Then("the url of link {string} should contain {string}") do |string, string2|
  urls = page.all(:xpath, "//a[text()=\"#{string}\"]", count: 1).map do |link|
    expect(link[:href]).to include("#{string2}")
  end
end

Then /^I should get a response with content-type "([^"]*)"$/ do |content_type|
  page.response_headers['Content-Type'].should == content_type
end

When("I view the search results list for {string}") do |string|
  visit search_catalog_path(q: string, search_field: 'all_fields')
end

When("I view the search results list for {string}={string}") do |search_field, query|
  visit search_catalog_path(q: query, search_field:)
end

When("I select {int} items per page") do |int|
  page.find(:css, "div#per_page-dropdown button.dropdown-toggle", visible: false).click
  click_link("#{int} per page")
end

Then("load {int} selected items") do |int|
  docs = page.find(:xpath, "//div[@id='documents']")
  docs.find(:xpath, "div[#{int}]")
end

Then("the link {string} should go to {string}") do |string, string2|
  expect(page).to have_link("#{string}", href: "#{string2}")
end

Then("I clear the SQLite transactions") do
  clear_sqlite
end

def clear_sqlite
  begin
    # https://stackoverflow.com/questions/7154664/ruby-sqlite3busyexception-database-is-locked
    ActiveRecord::Base.connection.execute("END;")
    # ActiveRecord::Base.connection.execute("BEGIN TRANSACTION; END;")
  rescue Exception => e
    fail ("clear_sqlite: #{e}") unless e.to_s.include? 'no transaction is active'
  end
end

Then("there should be a print bookmarks button") do
  within page.find("ul#item-tools") do
    expect(find(:xpath, "//a[@href='#print']").text).to include("Print")
  end
end

Then("I sign out") do
	visit "/users/sign_out"
end


Given("the test user is available") do
  if ENV['DEBUG_USER'].nil?
    raise 'The test user is not available'
  end
end

Then("I clear transactions") do
  clear_sqlite
end

Then("I did not catch any javascript errors") do
  expect(find('#js_error_report', visible: false, text: /^0$/ ))
end
