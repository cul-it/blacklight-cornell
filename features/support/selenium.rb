# frozen_string_literal: true

Capybara.default_normalize_ws = true

if ENV['USE_TEST_CONTAINER']
# if false
  webapp_host = 'webapp'
  webapp_port = 4000
  selenium_host = 'chrome'

  Capybara.configure do |config|
    config.server = :webrick # :puma, { Silent: true }
    config.server_host = webapp_host
    config.server_port = webapp_port
    # config.default_max_wait_time = 10
    config.default_max_wait_time = 5
  end

  require 'selenium/webdriver'

  Capybara.register_driver :remote_selenium do |app|
    # Pass our arguments to run headless
    # Does it need any other options?
    chrome_options = Selenium::WebDriver::Chrome::Options.new
    chrome_options.add_argument('--headless')
    chrome_options.add_argument('--no-sandbox')
    chrome_options.add_argument('--disable-dev-shm-usage')
    chrome_options.add_argument('--window-size=1400,1400')
    chrome_options.add_argument('--disable-gpu')

    long_client = Selenium::WebDriver::Remote::Http::Default.new
    long_client.read_timeout = 120
    long_client.open_timeout = 120
    # and point capybara at our chromium docker container
    Capybara::Selenium::Driver.new(
      app,
      browser: :remote,
      url: "http://#{selenium_host}:4444/wd/hub",
#      http_client: long_client,
      # url: "http://#{selenium_host}:4444/webdriver",
      options: chrome_options
    )
  end

  Capybara.javascript_driver = :remote_selenium
  Capybara.default_driver = :remote_selenium

  RSpec.configure do |config|
    config.before(:each, type: :system) do
#      driven_by :remote_selenium, options: { timeout: 120 }
      driven_by :remote_selenium
    end
  end
else
  Capybara.javascript_driver = :selenium_chrome_headless
  Capybara.server = :webrick
end
