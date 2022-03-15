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


  # show citations on a page
  def show_citation_page
    @bookmarks = token_or_current_or_guest_user.bookmarks
    bookmark_ids = @bookmarks.collect { |b| b.document_id.to_s }
    per_page = bookmark_ids.count
    @response, @documents = search_service.fetch(bookmark_ids, :per_page => per_page,:rows => per_page)
    render :partial=>"bookmarks/citation_page"
  end

  # save bookmarks and log in to book bags
  def bookmarks_book_bags_login
    #binding.pry
    # hack to return to book_bags page after login
    session[:cuwebauth_return_path] = book_bags_index_path
    # redirect_to user_saml_omniauth_authorize_path
    redirect_to signin_path
  end

end
