# -*- encoding : utf-8 -*-

Then /^I absolutely should see the text '(.*?)'$/i do |text|
  page.should have_content(text)
end

Then(/^I should see the text "([^"]*)"$/) do |arg1|
  expect(page).to have_content(arg1)
end

Then("I should see any text {string}") do |string|
  # // case insensitive
  page.should have_content(/#{string}/i)
end

Then("I should see {string} in the flash message") do |string|
  within ("#main-flashes") do
    expect(page.find("div.alert")).to have_content(string)
  end
end

When /^I follow "([^\"]*)"$/ do |link|
  click_link(link)
end

def where_am_i
  puts "\nYou are here: " + URI.parse(current_url).to_s
end

def show_environment
  puts "\n******************************"
  puts "Capybara.app_host " + Capybara.app_host.to_s
  puts "ENV['RAILS_ENV'] " + ENV["RAILS_ENV"]
  puts "******************************\n"
end

Then("show environment") do
  show_environment
end
