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

Then("I should not see a link {string}") do |string|
  expect(page).not_to have_selector("a", :text => "#{string}")
end

Then("I should see the CUWebLogin page") do
  patiently do
    page.should have_content("CUWebLogin")
    page.find("input.input-submit")
    page.find("a", :text => "IT Service Desk")
    page.find("a", :text => "I don't have a NetID, now what?")
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
  page.find(:xpath, '//span[@data-role="bookmark-counter"]').text.should match(int)
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
  page.find('div.results-info p', text: 'You have no selected items.')
end

Then /^there should be ([0-9]+) items? in the BookBag$/ do |int|
  patiently do
    within page.find('div.results-info') do
      if int == "0"
        page.find('div.results-info p', text: 'You have no selected items.')
      elsif int == "1"
        expect(find('.page-entries > strong:nth-child(1)').text).to eq('1 result')
      else
        find('.page-entries > strong:nth-child(3)', text: "#{int.to_s}")
      end
    end
  end
end

Then /^navigation should show ([0-9]+) items? in the BookBag$/ do |int|
  patiently do
    within page.find('#book_bags_nav') do
      find('span > span', text: "#{int.to_s}")
     end
  end
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

def what_is(element)
  puts "\n********************* what is V\n"
  puts page.current_url.inspect
  puts "\n"
  puts element.inspect
  puts "\n"
  puts element['innerHTML']
  puts "\n"
  puts "\n********************* what is ^\n"
end

Then /^show me id "(.*)"$/ do |string|
  @path = "\/\/*[@id=\"#{string}\"]"
  @chunk = page.find(:xpath, @path)
  what_is(@chunk)
end

Then /^show me xpath "(.*)"$/ do |string|
  @chunk = page.find(:xpath, string)
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

When("I expect Javascript _paq to be defined") do
  expect(page.evaluate_script("typeof _paq !== 'undefined'")).to be true
end

When("I am certain Javascript _paq is defined") do
  expect(page.evaluate_script("typeof _paq !== 'undefined'")).to be false
  page.execute_script("var _paq = _paq || [];")
  expect(page.evaluate_script("typeof _paq !== 'undefined'")).to be true
end

def find_popup_window
  patiently do
     popup = page.find(:xpath, '//*[@id="blacklight-modal"]', :visible => :all)
     popup.visible?
     @content = popup.find('div.modal-content', :visible => :all)
     @content.visible?
  end
  @content
end

# this is for blacklight-modal style modal regions within the page
Then("the popup should include {string}") do |string|
  begin
    @popup = find_popup_window
    patiently do
      @popup.find(:xpath, "//*[text()=\"#{string}\"]", :visible => :all).visible?
    end
  rescue Exception => e
    puts "popup exception: #{e}"
    fail("now")
  end
end

Then("the modal opened by the {string} link should include {string}") do |string, string2|
  patiently do
    wait_cache = Capybara.default_max_wait_time
    Capybara.default_max_wait_time = 20
    modal = page.window_opened_by{page.click_link(string)}
    Capybara.default_max_wait_time = wait_cache
    within_window modal do
      page.should have_content(string2)
    end
  end
end

Then("I close the popup") do
  # @popup = find_popup_window
  # @popup.find('button.blacklight-modal-close', :visible => :all).trigger('click')
  visit current_path
end

Then("the url of link {string} should contain {string}") do |string, string2|
  urls = page.all(:xpath, "//a[text()=\"#{string}\"]", count: 1).map do |link|
    expect(link[:href]).to include("#{string2}")
  end
end

Then /^I should get a response with content-type "([^"]*)"$/ do |content_type|
  page.response_headers['Content-Type'].should == content_type
end

When("I select {int} items per page") do |int|
  page.find(:css, "div#per_page-dropdown button.dropdown-toggle", visible: false).click
  click_link("#{int} per page")
end

Then("I should see {int} selected items") do |int|
  patiently do
    page.find(:xpath, "//a[@id='bookmarks_nav']/span")
    page.find(:xpath, "//a[@id='bookmarks_nav']/span", :text => "#{int}")
  end
end

Then("load {int} selected items") do |int|
  docs = page.find(:xpath, "//div[@id='documents']")
  docs.find(:xpath, "div[#{int}]")
end

Then("I check Select all") do
  patiently do
    page.find(:css, "input#select_all_input").click
  end
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

Then("I sign in") do
  visit "/users/auth/saml"
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
