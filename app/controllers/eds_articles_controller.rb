class EdsArticlesController < BlacklightEds::ArticlesController

    def add_show_tools_partial (args)
        puts args.to_yaml
    end

    configure_eds_articles do |config|
        # config.add_show_tools_partial(:bookmark, partial: 'bookmark_control', if: :render_bookmarks_control?)
        # config.add_show_tools_partial(:email, callback: :email_action, validator: :validate_email_params)
        # config.add_show_tools_partial(:sms, if: :render_sms_action?, callback: :sms_action, validator: :validate_sms_params)
        # config.add_show_tools_partial(:citation)

    end
end