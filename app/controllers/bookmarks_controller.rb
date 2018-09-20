# frozen_string_literal: true
class BookmarksController < CatalogController  
  include Blacklight::Bookmarks

  # displays the email_login_required form partial... used by an AJAX request
  def show_email_login_required_bookmarks
    render :partial=>"bookmarks/email_login_required"
  end
 
  # same as show_email_login_required_bookmarks but for the catalog item view
  def show_email_login_required_item
    login = ENV['GOOGLE_CLIENT_ID'] ?  catalog_logins_path :  user_saml_omniauth_authorize_path
    render :partial=>"bookmarks/email_login_required_item_view", locals: { login_path: login, document_id: params[:id] }
  end

end 
