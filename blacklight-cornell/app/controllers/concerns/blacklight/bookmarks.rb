# frozen_string_literal: true
# note that while this is mostly restful routing, the #update and #destroy actions
# take the Solr document ID as the :id, NOT the id of the actual Bookmark action.
module Blacklight::Bookmarks
  extend ActiveSupport::Concern

  included do
    ##
    # Give Bookmarks access to the CatalogController configuration
    include Blacklight::Configurable
    include Blacklight::TokenBasedUser

    copy_blacklight_config_from(CatalogController)

    blacklight_config.http_method = Blacklight::Engine.config.bookmarks_http_method
    blacklight_config.add_results_collection_tool(:clear_bookmarks_widget)

    blacklight_config.show.document_actions[:bookmark].if = false if blacklight_config.show.document_actions[:bookmark]
    blacklight_config.show.document_actions[:sms].if = false if blacklight_config.show.document_actions[:sms]
  end

  def action_documents
    bookmarks = token_or_current_or_guest_user.bookmarks
    bookmark_ids = bookmarks.collect { |b| b.document_id.to_s }
    search_service.fetch(bookmark_ids)
  end

  def action_success_redirect_path
    bookmarks_path
  end

  # Blacklight uses #search_action_url to figure out the right URL for
  # the global search box
  def search_action_url(*args)
    search_catalog_url(*args)
  end

  def index
    # if block is custom code
    if current_user && BookBag.enabled?
      redirect_to '/book_bags/index', status: 303, alert: I18n.t('blacklight.bookmarks.use_book_bag') and return
    end
    @bookmarks = token_or_current_or_guest_user.bookmarks
    bookmark_ids = @bookmarks.collect { |b| b.document_id.to_s }

    # next line and if block are custom code
    max_bookmarks = BookBagsController::MAX_BOOKBAGS_COUNT
    if bookmark_ids.count > max_bookmarks
      bookmark_ids = bookmark_ids.slice(0, max_bookmarks)
    end

    @response, deprecated_document_list = search_service.fetch(bookmark_ids)
    @document_list = ActiveSupport::Deprecation::DeprecatedObjectProxy.new(deprecated_document_list, "The @document_list instance variable is now deprecated and will be removed in Blacklight 8.0")

    respond_to do |format|
      format.html { }
      format.rss { render layout: false }
      format.atom { render layout: false }
      additional_response_formats(format)
      document_export_formats(format)
    end
  end

  def update
    create
  end

  # For adding a single bookmark, suggest use PUT/#update to
  # /bookmarks/$docuemnt_id instead.
  # But this method, accessed via POST to /bookmarks, can be used for
  # creating multiple bookmarks at once, by posting with keys
  # such as bookmarks[n][document_id], bookmarks[n][title].
  # It can also be used for creating a single bookmark by including keys
  # bookmark[title] and bookmark[document_id], but in that case #update
  # is simpler.
  def create
    # begin and rescue block are custom code
    begin
      @bookmarks = if params[:bookmarks]
          permit_bookmarks[:bookmarks]
        else
          [{ document_id: params[:id], document_type: blacklight_config.document_model.to_s }]
        end

      current_or_guest_user.save! unless current_or_guest_user.persisted?

      # next 8 lines are custom code
      current_count = current_or_guest_user.bookmarks.count
      new_count = @bookmarks.count
      save_level = Rails.logger.level; Rails.logger.level = Logger::WARN
      if (current_count + new_count) > BookBagsController::MAX_BOOKBAGS_COUNT
        Rails.logger.warn "jgr25_log #{__FILE__} #{__LINE__}: too many bookmarks"
        raise RangeError, "Too many bookmarks"
      end
      Rails.logger.level = save_level
      success = @bookmarks.all? do |bookmark|
        current_or_guest_user.bookmarks.where(bookmark).exists? || current_or_guest_user.bookmarks.create(bookmark)
      end

      if request.xhr?
        success ? render(json: { bookmarks: { count: current_or_guest_user.bookmarks.count } }) : render(plain: "", status: "500")
      else
        if @bookmarks.any? && success
          flash[:notice] = I18n.t("blacklight.bookmarks.add.success", count: @bookmarks.length)
        elsif @bookmarks.any?
          flash[:error] = I18n.t("blacklight.bookmarks.add.failure", count: @bookmarks.length)
        end

        redirect_back fallback_location: bookmarks_path
      end
    rescue RangeError => msg
      render :partial => "/bookmarks/selected_item_limit"
      #redirect_to '/bookmarks/show_selected_item_limit_bookmarks'
      #render(plain: msg, status: "500")
      #redirect_to 'bookmarks/show_selected_item_limit_bookmarks'
    end
  end

  # Beware, :id is the Solr document_id, not the actual Bookmark id.
  # idempotent, as DELETE is supposed to be.
  def destroy
    @bookmarks = if params[:bookmarks]
        permit_bookmarks[:bookmarks]
      else
        [{ document_id: params[:id], document_type: blacklight_config.document_model.to_s }]
      end

    success = @bookmarks.all? do |bookmark|
      bookmark = current_or_guest_user.bookmarks.find_by(bookmark)
      bookmark && bookmark.delete && bookmark.destroyed?
    end

    if success
      if request.xhr?
        render(json: { bookmarks: { count: current_or_guest_user.bookmarks.count } })
      else
        redirect_back fallback_location: bookmarks_path, notice: I18n.t("blacklight.bookmarks.remove.success")
      end
    elsif request.xhr?
      head 500 # ajaxy request needs no redirect and should not have flash set
    else
      redirect_back fallback_location: bookmarks_path, flash: { error: I18n.t("blacklight.bookmarks.remove.failure") }
    end
  end

  def clear
    if current_or_guest_user.bookmarks.clear
      flash[:notice] = I18n.t("blacklight.bookmarks.clear.success")
    else
      flash[:error] = I18n.t("blacklight.bookmarks.clear.failure")
    end
    redirect_to action: "index"
  end

  def export
    save_level = Rails.logger.level; Rails.logger.level = Logger::WARN
    Rails.logger.warn "jgr25_log #{__FILE__} #{__LINE__} #{__method__}: in bookmaks#export"
    puts "export".to_yaml
    puts "export".inspect
    if current_user
      puts "Current user:\n" + current_user.email.to_yaml
    elsif current_or_guest_user
      puts "Guest user:\n" + current_or_guest_user.email.to_yaml
    else
      puts "No user\n"
    end
    if user_session
      puts "Session:\n" + user_session.to_yaml
    else
      puts "No session\n"
    end

    # email = 'jgr25@cornell.edu'
    # bb = BookBag.new(email)
    # bb.create_table
    # list = [123, 456, 890]
    # bb.create_all(list)
    # bb.debug
    # list = [123, 890]
    # bb.delete_all(list)
    # bb.debug
    # puts "Delete\n" + bb.to_yaml
    Rails.logger.level = save_level
    redirect_to action: "index"
  end

  private

  def start_new_search_session?
    action_name == "index"
  end

  def permit_bookmarks
    params.permit(bookmarks: [:document_id, :document_type])
  end
end
