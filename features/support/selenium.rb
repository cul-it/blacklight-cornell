# frozen_string_literal: true

selenium_app_host = 'webapp'
selenium_app_port = 4000

Capybara.configure do |config|
  config.server = :puma, { Silent: false, Threads: '1:1', queue_requests: true }
  config.server_host = selenium_app_host
  config.server_port = selenium_app_port
end

Capybara.app_host = "http://#{selenium_app_host}:#{selenium_app_port}"
Capybara.server_host = selenium_app_host
Capybara.server_port = selenium_app_port

require 'selenium/webdriver'

Capybara.register_driver :remote_selenium do |app|
  # Pass our arguments to run headless
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--window-size=1400,1400')

  # and point capybara at our chromium docker container
  # Does the option need to be set differently?
  Capybara::Selenium::Driver.new(
    app,
    browser: :remote,
    url: 'http://chrome:4444/wd/hub',
    options: Selenium::WebDriver::Chrome::Options.new
  )
end

Capybara.javascript_driver = :remote_selenium
Capybara.default_driver = :remote_selenium

Capybara.always_include_port = true

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :remote_selenium
  end
end
