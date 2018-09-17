# frozen_string_literal: true
class BookmarksController < CatalogController  
  include Blacklight::Bookmarks

  def email_login_required
    Rails.logger.level = 0
    Rails.logger.info("jgr25_debug #{__FILE__} #{__LINE__}  = " + "bookmarks email_login_required")
    Rails.logger.level = :warn

    flash[:notice] = I18n.t('blacklight.bookmarks.need_login') and raise Blacklight::Exceptions::AccessDenied
  end

end 
