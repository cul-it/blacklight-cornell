# frozen_string_literal: true
class BookmarksController < CatalogController
  include Blacklight::Bookmarks

  def can_add
    return current_or_guest_user.bookmarks.count < BookBagsController::MAX_BOOKBAGS_COUNT
  end

  # displays the email_login_required form partial... used by an AJAX request
  def show_email_login_required_bookmarks
    render :partial=>"bookmarks/email_login_required"
  end

  # same as show_email_login_required_bookmarks but for the catalog item view
  def show_email_login_required_item
    login = ENV['GOOGLE_CLIENT_ID'] ?  catalog_logins_path :  user_saml_omniauth_authorize_path
    render :partial=>"bookmarks/email_login_required_item_view", locals: { login_path: login, document_id: params[:id] }
  end

  # error - too many bookmarks
  def show_selected_item_limit_bookmarks
    render :partial=>"bookmarks/selected_item_limit"
  end

  # return an array of the top level location names from location facet
  def get_library_location_names
    results = Blacklight.solr.find( { :q => "id:*", })
  end

  # save bookmarks and log in to book bags
  def bookmarks_book_bags_login
    #binding.pry
    # hack to return to book_bags page after login
    session[:cuwebauth_return_path] = book_bags_index_path
#******************
save_level = Rails.logger.level; Rails.logger.level = Logger::WARN
Rails.logger.warn "jgr25_log\n#{__method__} #{__LINE__} #{__FILE__}:"
msg = [" #{__method__} ".center(60,'Z')]
msg << "user_saml_omniauth_authorize_path: " + user_saml_omniauth_authorize_path.inspect
msg << 'Z' * 60
msg.each { |x| puts 'ZZZ ' + x.to_yaml }
Rails.logger.level = save_level
#*******************
    redirect_to user_saml_omniauth_authorize_path
  end

end
