# frozen_string_literal: true

Capybara.default_normalize_ws = true

CHROME_PATH = '/usr/bin/chromium'
ENV['WD_CHROME_PATH'] = CHROME_PATH
require 'selenium/webdriver'
Selenium::WebDriver::Chrome.path = CHROME_PATH
Capybara.register_driver :chromium do |app|
  chrome_options = Selenium::WebDriver::Chrome::Options.new
  chrome_options.add_argument('--headless')
  chrome_options.add_argument('--no-sandbox')
  chrome_options.add_argument('--disable-dev-shm-usage')
  chrome_options.add_argument('--window-size=1400,1400')
  chrome_options.add_argument('--disable-gpu')
  chrome_options.add_argument('--user-data-dir=/root/user-data')
  chrome_options.add_argument('--disable-background-timer-throttling')
  chrome_options.add_argument('--disable-backgrounding-occluded-windows')
  chrome_options.add_argument('--disable-renderer-backgrounding')
  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    options: chrome_options
  )
end

Capybara.javascript_driver = :chromium

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :chromium
  end
end

Capybara.server = :webrick
