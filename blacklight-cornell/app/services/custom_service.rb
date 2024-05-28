class CustomService < StatusPage::Services::Base
    def check!
        raise 'Oh oh!'
    end
end