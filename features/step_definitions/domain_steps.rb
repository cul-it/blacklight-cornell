
Before do |scenario|
    if ENV.key?("CUCUMBER_TEST_SITE")
        # end with a single slash, whether it's there or not
        @url = File.join(ENV["CUCUMBER_TEST_SITE"], "")
        Capybara.app_host = @url
    else
        @url = nil
    end
end

def do_visit(path)
    visit "#{@url}#{path}"
end
