# frozen_string_literal: true
class BookmarksController < CatalogController  
  include Blacklight::Bookmarks

  def can_add
    return current_or_guest_user.bookmarks.count < book_bags::MAX_BOOKBAGS_COUNT
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

end 
