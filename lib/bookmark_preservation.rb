module BookmarkPreservation

    def initialize(debug = nil)
        @@jgr25_debug = 1
    end

    def save_bookmarks_for_book_bags

        if guest_user.bookmarks.present? && guest_user.bookmarks.count > 0
          session[:bookmarks_for_book_bags] = guest_user.bookmarks.collect { |b| b.document_id.to_s }
        end

      #******************
      if @@jgr25_debug
        save_level = Rails.logger.level; Rails.logger.level = Logger::WARN
        Rails.logger.warn "jgr25_log\n#{__method__} #{__LINE__} #{__FILE__}:"
        msg = ["****************** #{__method__}"]
        msg << "guest_user.bookmarks.count " + guest_user.bookmarks.count.inspect unless guest_user.bookmarks.nil?
        msg << "session[:bookmarks_for_book_bags] " + session[:bookmarks_for_book_bags].inspect
        msg << '******************'
        puts msg.to_yaml
        Rails.logger.level = save_level
      end
      #*******************

    end

    def get_saved_bookmarks
        session[:bookmarks_for_book_bags]
    end

    def clear_saved_bookmarks
        session[:bookmarks_for_book_bags] = nil;
    end

end