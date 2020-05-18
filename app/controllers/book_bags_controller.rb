class Bookmarklite
  attr_accessor :document_id


  def initialize(bid)
    @document_id = bid
  end

end

class BookBagsController < CatalogController
#class BookBagsController < ApplicationController
   include Blacklight::Catalog
   include BlacklightCornell::CornellCatalog

  MAX_BOOKBAGS_COUNT = 500

  # copy_blacklight_config_from(CatalogController)
  #
  before_action :authenticate

  before_action :heading
  append_before_action :set_book_bag_name

  def sign_in
    save_level = Rails.logger.level; Rails.logger.level = Logger::WARN
    Rails.logger.warn "jgr25_log\n#{__method__} #{__LINE__} #{__FILE__}:\n"
    msg = ['******************']
    msg << "Before:"
    if user_signed_in?
      msg << "signed in as " + current_user.email
    elsif current_or_guest_user
      msg << "guest user " + current_or_guest_user.email
    else
      msg << "no user"
    end
    msg << "session: " + user_session.present?.to_s
    request.env["devise.mapping"] = Devise.mappings[:user] # If using Devise
    request.env["omniauth.auth"] = OmniAuth.config.mock_auth[:saml]
    OmniAuth.config.mock_auth[:saml] = nil
    mock_auth
    :authenticate_user!
    msg << "After:"
    if user_signed_in?
      msg << "signed in as " + current_user.email
    elsif current_or_guest_user
      msg << "guest user " + current_or_guest_user.email
    else
      msg << "no user"
    end
    msg << "session: " + user_session.present?.to_s
    msg << '******************'
    puts msg.to_yaml
    Rails.logger.level = save_level
    #*******************
    redirect_to :action => "index"
  end

  def authenticate
    if ENV['DEBUG_USER'].present? && Rails.env.development?
      mock_auth
      :authenticate_user!
      if current_user
        set_bag_name
        flash[:success] = "Found Current User"
        user = current_user
      else
        flash[:failure] = "No user found"
        user = current_or_guest_user
      end
    else
      :authenticate_user!
      user = current_user
    end
    save_level = Rails.logger.level; Rails.logger.level = Logger::WARN
    Rails.logger.warn "jgr25_log #{__FILE__} #{__LINE__} #{__method__}: in authenticate"
    puts user.email.to_yaml
    puts user.email.inspect
    Rails.logger.level = save_level
  end

  def mock_auth
    if ENV['DEBUG_USER'].present? && Rails.env.development?
      OmniAuth.config.test_mode = true
      #OmniAuth.add_mock(:saml, {:uid => '12356', {:info => {:email => 'jgr25@cornell.edu'}}})
      OmniAuth.config.mock_auth[:saml] = OmniAuth::AuthHash.new({
        provider: "saml",
        "saml_resp" => saml_resp ,
        uid: "12345678910",
        extra: {raw_info: {} } ,
        info: {
          email: "ditester@example.com",
          name: ["Diligent Tester"],
          netid: "mjc12",
          groups: ["staff","student"],
          primary: ["staff"],
          first_name: "Diligent",
          last_name: "Tester"
        },
        credentials: {
          token: "abcdefg12345",
          refresh_token: "12345abcdefg",
          expires_at: DateTime.now
        }
      })
    end
  end

  def saml_resp
    'hello'
  end

  def set_book_bag_name
    if current_user
      @id = current_user.email
      @bb.bagname = "#{@id}-bookbag-default"
      user_session[:bookbag_count] = @bb.count
    end
  end

  def heading
   @heading='BookBag'
  end

  def initialize
    super
    @bb = BookBag.new(nil)
  end

  def can_add
    return current_or_guest_user.bookmarks.count < MAX_BOOKBAGS_COUNT
  end

  def add
    @bibid = params[:id]
    value = "bibid-#{@bibid}"
    Rails.logger.info("es287_debug #{__FILE__} #{__LINE__} #{__method__} @bb = #{@bb.inspect}")
    Rails.logger.info("es287_debug #{__FILE__} #{__LINE__} #{__method__} value = #{value.inspect}")
    if @bb.count < MAX_BOOKBAGS_COUNT
      success = @bb.create_all([value])
      user_session[:bookbag_count] = @bb.count
    end
    if request.xhr?
      success ? render(json: { bookmarks: { count: @bb.count }}) : render(plain: "", status: "500")
    else
      respond_to do |format|
        format.html { }
        format.rss  { render :layout => false }
        format.atom { render :layout => false }
        format.json { render json:   { }      }
      end
     end
  end

  def addbookmarks
    @savedll = Rails.logger.level # at any time
    Rails.logger.level = Logger::INFO
    if current_or_guest_user.bookmarks.count > 0
      bm = current_or_guest_user.bookmarks
      Rails.logger.info("jgr25_debug #{__FILE__} #{__LINE__} #{__method__} bookmarks = #{bm.inspect}")
      bm.each do | b |
        Rails.logger.info("jgr25_debug #{__FILE__} #{__LINE__} #{__method__} bookmark = #{b.inspect}")
      end
      Rails.logger.info("jgr25_debug #{__FILE__} #{__LINE__} #{__method__} user = #{current_user.inspect}")
      bookmark_ids = current_or_guest_user.bookmarks.collect { |b| b.document_id.to_s }
      Rails.logger.info("jgr25_debug #{__FILE__} #{__LINE__} #{__method__} bibs = #{bookmark_ids.inspect}")
      bookmark_max = MAX_BOOKBAGS_COUNT - @bb.count
      if bookmark_ids.count > bookmark_max
        # delete the extra bookmarks
        bookmark_ids = bookmark_ids.split(0, bookmark_max)
      end
      if not bookmark_ids.to_s.empty?
        @bb.create_all(bookmark_ids)
        # bookmark_ids.each do | v |
        #   if /[0-9]+/.match(v)
        #     v.prepend('bibid-')
        #     success = @bb.create(v)
        #   end
        user_session[:bookbag_count] = @bb.count unless user_session.nil?
      end
    end
    Rails.logger.level = @savedll
    redirect_to :action => "index"
  end

  def delete
    @bibid = params[:id]
    value = [@bibid]
    Rails.logger.info("es287_debug #{__FILE__} #{__LINE__} #{__method__} @bb = #{@bb.inspect}")
    Rails.logger.info("es287_debug #{__FILE__} #{__LINE__} #{__method__} value = #{value.inspect}")
    success = @bb.delete_all(value)
    user_session[:bookbag_count] = @bb.count
    if request.xhr?
      success ? render(json: { bookmarks: { count: @bb.count }}) : render(plain: "", status: "500")
    else
      respond_to do |format|
        format.html { }
        format.rss  { render :layout => false }
        format.atom { render :layout => false }
        format.json do
          render json:   { }
        end
      end
    end
  end

  def index
    @bms =@bb.index
    docs = @bms.map {|b| b.sub!("bibid-",'')}
    @response,@documents = search_service.fetch docs
    @document_list =  @documents
    @bookmarks = docs.map {|b| Bookmarklite.new(b)}
    respond_to do |format|
      format.html { }
      format.rss  { render :layout => false }
      format.atom { render :layout => false }
      format.json do
        render json: render_search_results_as_json
      end
      additional_response_formats(format)
      document_export_formats(format)
    end
  end

  def clear
    success = @bb.clear
    Rails.logger.info("es289_debug #{__FILE__} #{__LINE__} #{__method__} @bb = #{@bb.inspect}")
    if success
      if current_or_guest_user.bookmarks.count > 0
        current_or_guest_user.bookmarks.clear
      end
      flash[:notice] = I18n.t('blacklight.bookmarks.clear.success')
    else
      flash[:error] = I18n.t('blacklight.bookmarks.clear.failure')
    end
    redirect_to :action => "index"
  end

  def action_documents
    options =   {:per_page => 1000,:rows => 1000}
    @bms =@bb.index
    docs = @bms.map {|b| b.sub!("bibid-",'')}
    Rails.logger.info("es287_debug #{__FILE__} #{__LINE__} #{__method__} docs = #{docs.inspect}")
    search_service.fetch docs, options
  end

  def citation
    @response, @documents = action_documents
    respond_to do |format|
      format.html { render :layout => false }
    end
  end

  # Email Action (this will render the appropriate view on GET requests and process the form and send the email on POST requests)
  def email_action documents
    mail = RecordMailer.email_record(documents, { to: params[:to], message: params[:message], :callnumber => params[:callnumber], :status => params[:itemStatus] }, url_options, params)
    if mail.respond_to? :deliver_now
      mail.deliver_now
    else
      mail.deliver
    end
  end

  # grabs a bunch of documents to export to endnote or ris.
  def endnote
    Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__}  params = #{params.inspect}")
    if params[:id].nil?
      @bms =@bb.index
      docs = @bms.map {|b| b.sub!("bibid-",'')}
      @response, @documents = search_service.fetch(docs, :per_page => 1000,:rows => 1000)
      Rails.logger.debug("es287_debug #{__FILE__}:#{__LINE__}  @documents = #{@documents.size.inspect}")
    else
      @response, @documents = search_service.fetch(params[:id])
    end
    respond_to do |format|
      format.endnote  { render :layout => false } #wrapped render :layout => false in {} to allow for multiple items jac244
      format.ris      { render 'ris', :layout => false }
    end
  end

end