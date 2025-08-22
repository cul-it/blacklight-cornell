
Before do |scenario|
    if ENV.key?("CUCUMBER_TEST_SITE")
        # end with a single slash, whether it's there or not
        @url = File.join(ENV["CUCUMBER_TEST_SITE"], "")
        # default driver does not support remote javascript
        Capybara.current_driver = :selenium_headless
        Capybara.run_server = false
        Capybara.app_host = @url
    else
        @url = nil
    end
end
