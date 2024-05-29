# example service for blacklight-cornell/config/initializers/status_page.rb
class CustomService < StatusPage::Services::Base
    def check!
        raise 'Oh oh!'
    end
end