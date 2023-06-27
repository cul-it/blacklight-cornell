# frozen_string_literal: true

if ENV['USE_TEST_CONTAINER']
  webapp_host = 'webapp'
  webapp_port = 4000
  selenium_host = 'chrome'

  Capybara.configure do |config|
    config.server = :puma, { Silent: true, Threads: '1:1', queue_requests: true }
    config.server_host = webapp_host
    config.server_port = webapp_port
    config.app_host = "http://#{webapp_host}:#{webapp_port}"
  end
  # Capybara.app_host = "http://#{webapp_host}:#{webapp_port}"

  require 'selenium/webdriver'

  Capybara.register_driver :remote_selenium do |app|
    # Pass our arguments to run headless
    # Does it need any other options?
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument('--headless')
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    options.add_argument('--window-size=1400,1400')

    # and point capybara at our chromium docker container
    Capybara::Selenium::Driver.new(
      app,
      browser: :remote,
      url: "http://#{selenium_host}:4444/wd/hub",
      options: options
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
else
  Capybara.javascript_driver = :selenium_chrome_headless
  Capybara.server = :webrick
end
