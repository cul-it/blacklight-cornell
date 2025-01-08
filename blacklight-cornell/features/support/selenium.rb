# frozen_string_literal: true

Capybara.default_normalize_ws = true

if ENV["USE_TEST_CONTAINER"]
  begin
    webapp_host = "#{IPSocket.getaddress(Socket.gethostname)}"
  rescue
    webapp_host = "webapp"
  end

  webapp_port = 4000 + ENV['TEST_ENV_NUMBER'].to_i
  selenium_host = "chrome"

  Capybara.configure do |config|
    config.server = :webrick
    config.server_host = webapp_host
    config.server_port = webapp_port
    config.default_max_wait_time = 20
    config.app_host = "http://#{webapp_host}:#{webapp_port}"
  end

  require "selenium/webdriver"

  Capybara.register_driver :remote_selenium do |app|
    chrome_options = Selenium::WebDriver::Chrome::Options.new
    chrome_options.add_argument("--headless")
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.add_argument("--window-size=1400,1400")
    chrome_options.add_argument("--disable-gpu")

    chrome_options.add_argument("--disable-background-timer-throttling")
    chrome_options.add_argument("--disable-backgrounding-occluded-windows")
    chrome_options.add_argument("--disable-renderer-backgrounding")

    long_client = Selenium::WebDriver::Remote::Http::Default.new
    long_client.read_timeout = 120
    long_client.open_timeout = 120
    # and point capybara at our chromium docker container
    Capybara::Selenium::Driver.new(
      app,
      browser: :remote,
      url: "http://#{selenium_host}:4444/wd/hub",
      options: chrome_options,
      http_client: long_client
    )
  end

  Capybara.javascript_driver = :remote_selenium

  RSpec.configure do |config|
    config.before(:each, type: :system) do
      driven_by :remote_selenium
    end
  end
else
  ENV["WD_CHROME_PATH"] = "/usr/bin/google-chrome"
  Selenium::WebDriver::Chrome.path = ENV["WD_CHROME_PATH"]
  Capybara.javascript_driver = :selenium_chrome_headless
  Capybara.server = :webrick
end
