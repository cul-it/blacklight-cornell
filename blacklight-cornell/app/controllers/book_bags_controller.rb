class Bookmarklite
  attr_accessor :document_id

  def initialize(bid)
    @document_id = bid
  end
end

class BookBagsController < CatalogController
  include Blacklight::Catalog
  include BlacklightCornell::CornellCatalog

  MAX_BOOKBAGS_COUNT = 500

  before_action :save_bookmarks_for_book_bags
  before_action :authenticate

  before_action :heading
  append_before_action :set_book_bag_name

  blacklight_config.search_builder_class = Blacklight::BookmarksSearchBuilder

  def action_success_redirect_path
    book_bags_index
  end

  def authenticate
    #binding.pry
    if developer_bookbag?
      dev_sign_in
    else
      :authenticate_user!
      user = current_user
    end
    set_book_bag_name if current_user
  end

  def set_book_bag_name
    #binding.pry
    if current_user && session[:cu_authenticated_email].present?
      @id = session[:cu_authenticated_email]
      @bb.set_bagname("#{@id}-bookbag-default")
      session[:bookbag_count] = @bb.count
    end
  end

  def heading
    @heading = "BookBag"
  end

  def initialize
    super
    @bb = BookBag.new unless @bb.present?
    if @response.nil?
      @response = Blacklight::Solr::Response.new({ response: { numFound: 0 } }, start: 0, rows: 10)
    end
  end

  def can_add
    return current_or_guest_user.bookmarks.count < MAX_BOOKBAGS_COUNT
  end

  def add
    if current_user
      @bibid = params[:id]
      value = @bibid
      if @bb.count < MAX_BOOKBAGS_COUNT
        success = @bb.cache(value)
        session[:bookbag_count] = @bb.count
      end
      if request.xhr?
        success ? render(json: { bookmarks: { count: @bb.count } }) : render(plain: "", status: "500")
      else
        respond_to do |format|
          format.html { }
          format.rss { render :layout => false }
          format.atom { render :layout => false }
          format.json { render json: {} }
        end
      end
    end
  end

  def addbookmarks
    #binding.pry
    bookmarks = get_saved_bookmarks
    if bookmarks.present? && bookmarks.count > 0
      bookmark_max = MAX_BOOKBAGS_COUNT - @bb.count
      if bookmarks.count > bookmark_max
        # delete the extra bookmarks
        bookmarks = bookmarks.split(0, bookmark_max)
      end
      if not bookmarks.to_s.empty?
        @bb.create_all(bookmarks)
      end
      clear_saved_bookmarks
    end
    redirect_to :action => "index"
  end

  def delete
    @bibid = params[:id]
    value = @bibid
    success = @bb.uncache(value)
    session[:bookbag_count] = @bb.count
    if request.xhr?
      success ? render(json: { bookmarks: { count: @bb.count } }) : render(plain: "", status: "500")
    else
      respond_to do |format|
        format.html { }
        format.rss { render :layout => false }
        format.atom { render :layout => false }
        format.json do
          render json: {}
        end
      end
    end
  end

  # @return [Hash] a hash of context information to pass through to the search service
  def search_service_context
    @bms = @bb.index
    if @bb.is_a? BookBag
      docs = @bms.each { |v| v.to_s }
    else
      docs = @bms.map { |b| b.sub!("bibid-", "") }
    end
    @bookmarks = docs.map { |b| Bookmarklite.new(b) }

    { bookmarks: @bookmarks }
  end

  def index
    params.permit(:move_bookmarks)

    (@response, deprecated_document_list) = search_service.search_results
    @documents = ActiveSupport::Deprecation::DeprecatedObjectProxy.new(
      deprecated_document_list,
      "The @documents instance variable is now deprecated",
      ActiveSupport::Deprecation.new("8.0", "blacklight")
    )
    @document_list = ActiveSupport::Deprecation::DeprecatedObjectProxy.new(
      deprecated_document_list,
      "The @document_list instance variable is now deprecated",
      ActiveSupport::Deprecation.new("8.0", "blacklight")
    )

    respond_to do |format|
      format.html { }
      format.rss { render :layout => false }
      format.atom { render :layout => false }
      additional_response_formats(format)
      document_export_formats(format)
    end
  end

  def clear
    success = @bb.clear
    if success
      if current_or_guest_user.bookmarks.count > 0
        current_or_guest_user.bookmarks.clear
      end
      flash[:notice] = I18n.t("blacklight.bookmarks.clear.success")
    else
      flash[:error] = I18n.t("blacklight.bookmarks.clear.failure")
    end
    redirect_to :action => "index"
  end

  def action_documents
    docs = @bb.index
    per_page = docs.count
    options = { :per_page => per_page, :rows => per_page }
    search_service.fetch(docs, options)
  end

  # grabs a bunch of documents to export to endnote or ris.
  def endnote
    if params[:id].nil?
      # docs are set in search context
      deprecated_response, @documents = search_service.fetch([], :q => "*:*", :per_page => 1000, :rows => 1000)
    else
      deprecated_response, @documents = search_service.fetch(params[:id])
    end
    @response = ActiveSupport::Deprecation::DeprecatedObjectProxy.new(
      deprecated_response,
      "The @response instance variable is now deprecated",
      ActiveSupport::Deprecation.new("8.0", "blacklight")
    )
    respond_to do |format|
      format.endnote { render :layout => false } #wrapped render :layout => false in {} to allow for multiple items jac244
      format.endnote_xml { render "endnote_xml", :layout => false }
      format.ris { render "ris", :layout => false }
    end
  end

  def export
    # :nocov:
      save_level = Rails.logger.level
      Rails.logger.level = Logger::WARN
      Rails.logger.warn "jgr25_log #{__FILE__} #{__LINE__} #{__method__}: in export"
    # :nocov:

    msg = "book_bags_controler.rb export"
    puts msg.to_yaml
    # :nocov:
      @bb.debug
      Rails.logger.level = save_level
    # :nocov:
    redirect_to :action => "index"
  end

  def test
  end

  def track
  end

  def save_bookmarks_for_book_bags
    #binding.pry
    if guest_user.bookmarks.present?
      bookmarks = guest_user.bookmarks.collect { |b| b.document_id.to_s }
      session[:bookmarks_for_book_bags] = bookmarks unless bookmarks.count < 1
    end
  end

  def get_saved_bookmarks
    session[:bookmarks_for_book_bags]
  end

  def clear_saved_bookmarks
    session[:bookmarks_for_book_bags] = nil
  end

  private

  ######################################################################################################################
  ### Developer-Mode Helper Methods  ##
  #####################################
  def developer_bookbag?
    !ENV["LOGIN_REQUIRED"].present? && ENV["DEBUG_USER"].present? && Rails.env.development?
  end

  def dev_sign_in
    return if user_signed_in?

    BlacklightCornell::OmniauthMock.sign_in!
    redirect_post(user_saml_omniauth_authorize_path, options: { authenticity_token: :auto })
  end
end
