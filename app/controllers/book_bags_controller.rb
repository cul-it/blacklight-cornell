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
  #before_action :authenticate_user!
  before_action :authenticate

  before_action :heading
  append_before_action :set_bag_name

  def authenticate
    if ENV['DEBUG_USER'].present? && Rails.env.development?
      mock_auth
      :authenticate_user!
      if current_user
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

  def set_bag_name
    if ENV['DEBUG_USER'].present?
      @id = current_or_guest_user.email
    else
      @id = current_user.email
    end
    @bb.bagname = "#{@id}-bookbag-default"
    user_session[:bookbag_count] = @bb.count unless user_session.nil?
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

#  def email
#    # file = File.open("jgr25_debug.log", File::WRONLY | File::APPEND | File::CREAT)
#    # logger = Logger.new(file)
#    # logger.level = :info
#    # logger.info("jgr25_debug #{__FILE__}:#{__LINE__}  request.xhr?  = #{request.xhr?.inspect}")
#    # logger.info("jgr25_debug #{__FILE__}:#{__LINE__}  request.post?  = #{request.post?.inspect}")
#    @bms =@bb.index
#    all_docs = @bms.map {|b| b.sub!("bibid-",'')}
#    if request.post?
#      url_gen_params = {:host => request.host_with_port, :protocol => request.protocol, :params => params}
#      if params[:to] && params[:to].match(/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
#        all_docs.each_slice(20) do |docs|
#          @response, @documents = search_service.fetch docs
#          # logger.info("jgr25_debug #{__FILE__}:#{__LINE__}  docs  = #{docs.inspect}")
#          url_gen_params = {:host => request.host_with_port, :protocol => request.protocol, :params => params}
#          email ||= RecordMailer.email_record(@documents, {:to => params[:to], :message => params[:message], :callnumber => params[:callnumber], :status => params[:itemStatus],}, url_gen_params, params)
#          email.deliver_now
#        end
#        flash[:success] = "Email sent"
#        redirect_to solr_document_path(params[:id]) unless request.xhr?
#      else
#        flash[:error] = I18n.t('blacklight.email.errors.to.invalid', :to => params[:to])
#      end
#    end

    # logger.info("jgr25_debug #{__FILE__}:#{__LINE__}  finished emails  = #{flash.inspect}")

#   @bms =@bb.index
#   docs = @bms.map {|b| b.sub!("bibid-",'')}
#   @response, @documents = search_service.fetch docs
#   Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__}  request.xhr?  = #{request.xhr?.inspect}")
#   Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__}  flash  = #{flash.inspect}")
#   if   ENV['SAML_IDP_TARGET_URL']
#     if request.xhr? && flash[:success]
#       if docs.size < 2
#
#         if !params[:id][0].nil?
#           bibid = params[:id][0]
#           render :js => "window.location = '/catalog/#{bibid}'"
#         else
#           render :js => "window.location = '/catalog"
#         end
#
#       else
#         render :js => "window.location = '/book_bags/index'"
#       end
#       return
#     end
#   end
#   unless !request.xhr? && flash[:success]
#     respond_to do |format|
#       format.js { render :layout => false }
#       format.html
#     end
#   end
# end

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