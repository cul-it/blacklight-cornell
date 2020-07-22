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

  # copy_blacklight_config_from(CatalogController)
  #
  before_action :save_bookmarks_for_book_bags
  before_action :authenticate

  before_action :heading
  append_before_action :set_book_bag_name

  def action_success_redirect_path
    book_bags_index
  end

  def authenticate

    if ENV['DEBUG_USER'].present? && (Rails.env.development? || Rails.env.test?)

      if user_signed_in?
          #******************
          save_level = Rails.logger.level; Rails.logger.level = Logger::WARN
          Rails.logger.warn "jgr25_log\n#{__method__} #{__LINE__} #{__FILE__}:\n"
          msg = ["****************** #{__method__}"]
          msg << "user already signed in"
          msg << '******************'
          puts msg.to_yaml
          Rails.logger.level = save_level
          #*******************
      end


      mock_auth
      :authenticate_user!

    else
      :authenticate_user!
      user = current_user
    end
    if current_user
      set_book_bag_name
      msg = []
      msg << "Found Current User in book_bags_controller authenticate"
      msg << "bagname: " + @bb.bagname + " count: " + @bb.count.to_s
      msg << "session: " + user_session.present?.to_s
      user = current_user
      save_level = Rails.logger.level; Rails.logger.level = Logger::WARN
      Rails.logger.warn "jgr25_log #{__FILE__} #{__LINE__} #{__method__}: in authenticate"
      puts msg.to_yaml
      Rails.logger.level = save_level
    else
      msg = []
      msg << "No user found"
      user = current_or_guest_user
      save_level = Rails.logger.level; Rails.logger.level = Logger::WARN
      Rails.logger.warn "jgr25_log #{__FILE__} #{__LINE__} #{__method__}: in authenticate"
      puts msg.to_yaml
      Rails.logger.level = save_level
    end
    #******************
    save_level = Rails.logger.level; Rails.logger.level = Logger::WARN
    Rails.logger.warn "jgr25_log\n#{__method__} #{__LINE__} #{__FILE__}:\n"
    msg = ["****************** #{__method__}"]
    msg << "user email: " + user.email.to_s unless user.nil?
    msg << '******************'
    puts msg.to_yaml
    Rails.logger.level = save_level
    #*******************

  end

  def mock_auth
    if ENV['DEBUG_USER'].present? && Rails.env.development?
      OmniAuth.config.test_mode = true
      #OmniAuth.config.mock_auth[:saml] = nil
      #OmniAuth.add_mock(:saml, {:uid => '12356', {:info => {:email => 'jgr25@cornell.edu'}}})
      OmniAuth.config.mock_auth[:saml] = OmniAuth::AuthHash.new({
        provider: "saml",
        "saml_resp" => 'hello' ,
        uid: "12345678910",
        extra: {raw_info: {} } ,
        info: {
          email: [ENV['DEBUG_USER']],
          name: ["Diligent Tester"],
          netid: "jgr25",
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

  def set_book_bag_name
    if current_user
      @id = current_user.email
      @bb.set_bagname("#{@id}-bookbag-default")
      user_session[:bookbag_count] = @bb.count
      # session[:cuwebauth_return_path]

#******************
save_level = Rails.logger.level; Rails.logger.level = Logger::WARN
Rails.logger.warn "jgr25_log\n#{__method__} #{__LINE__} #{__FILE__}:"
msg = ["****************** #{__method__}"]
msg << "user: "
msg << current_user.email.to_yaml
msg << "id: " + @id.to_s
msg << "@bb.bagname " + @bb.bagname.to_s
msg << "@bb.count " + @bb.count.to_s
msg << "session[:cuwebauth_return_path] " + session[:cuwebauth_return_path].inspect
msg << '******************'
puts msg.to_yaml
Rails.logger.level = save_level
#*******************

     else
      save_level = Rails.logger.level; Rails.logger.level = Logger::WARN
      Rails.logger.warn "jgr25_log #{__FILE__} #{__LINE__} #{__method__}: in authenticate"
      msg = "called set_book_bag_name with no current_user"
      puts msg.to_yaml
      Rails.logger.level = save_level
    end
  end

  def heading
   @heading='BookBag'
  end

  def initialize
    @@jgr25_debug = 1
    super
    #******************
    save_level = Rails.logger.level; Rails.logger.level = Logger::WARN
    Rails.logger.warn "jgr25_log\n#{__method__} #{__LINE__} #{__FILE__}:"
    msg = ["****************** #{__method__}"]
    msg << "init @bb"
    msg << "@bb.present? " + @bb.present?.inspect
    msg << '******************'
    puts msg.to_yaml
    Rails.logger.level = save_level
    #*******************
    @bb = BookBag.new unless @bb.present?
    if @response.nil?
      @response = Blacklight::Solr::Response.new({ response: { numFound: 0 } }, start: 0, rows: 10)
    end
  end

  def can_add
    return current_or_guest_user.bookmarks.count < MAX_BOOKBAGS_COUNT
  end

  def add
    @bibid = params[:id]
    value = @bibid
    Rails.logger.info("es287_debug #{__FILE__} #{__LINE__} #{__method__} @bb = #{@bb.inspect}")
    Rails.logger.info("es287_debug #{__FILE__} #{__LINE__} #{__method__} value = #{value.inspect}")
    if @bb.count < MAX_BOOKBAGS_COUNT
      success = @bb.cache(value)
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
    bookmarks = get_saved_bookmarks
#******************
save_level = Rails.logger.level; Rails.logger.level = Logger::WARN
Rails.logger.warn "jgr25_log\n#{__method__} #{__LINE__} #{__FILE__}:"
msg = ["****************** #{__method__}"]
msg << 'bookmarks: ' + bookmarks.inspect
msg << '******************'
puts msg.to_yaml
Rails.logger.level = save_level
#*******************
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
    Rails.logger.info("es287_debug #{__FILE__} #{__LINE__} #{__method__} @bb = #{@bb.inspect}")
    Rails.logger.info("es287_debug #{__FILE__} #{__LINE__} #{__method__} value = #{value.inspect}")
    success = @bb.uncache(value)
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
    # if !user_signed_in?
    #   flash[:notice] = I18n.t('blacklight.bookmarks.use_bookmarks')
    #   redirect_to
    params.permit(:move_bookmarks)

    @bms =@bb.index
    if @bb.is_a? BookBag
      docs = @bms.each {|v| v.to_s }
    else
      docs = @bms.map {|b| b.sub!("bibid-",'')}
    end

    addbookmarks unless params[:move_bookmarks].nil?


#******************
save_level = Rails.logger.level; Rails.logger.level = Logger::WARN
Rails.logger.warn "jgr25_log\n#{__method__} #{__LINE__} #{__FILE__}:"
msg = ["****************** #{__method__}"]
msg << "@bb"
msg << "Old style" unless @bb.is_a? BookBag
# msg << "Bagname: " + @bb.bagname unless @bb.nil?
msg << @bms.inspect
msg << "docs: " + (docs.present? ? docs.inspect : "not present")
msg << '******************'
msg << 'params: ' + params.inspect
puts msg.to_yaml
Rails.logger.level = save_level
#*******************
    if docs.present?
      @bookmarks = docs.map {|b| Bookmarklite.new(b)}
      @response,@documents = search_service.fetch docs
      @document_list =  @documents
    end
    respond_to do |format|
      format.html {}
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
#******************
save_level = Rails.logger.level; Rails.logger.level = Logger::WARN
Rails.logger.warn "jgr25_log\n#{__method__} #{__LINE__} #{__FILE__}:"
msg = ["****************** #{__method__}"]
msg << @bb.inspect
msg << '******************'
puts msg.to_yaml
Rails.logger.level = save_level
#*******************
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
    docs = @bb.index
#******************
save_level = Rails.logger.level; Rails.logger.level = Logger::WARN
Rails.logger.warn "jgr25_log\n#{__method__} #{__LINE__} #{__FILE__}:"
msg = ["****************** #{__method__}"]
msg << '@bms: ' + @bms.inspect
msg << 'docs ' + docs.inspect
msg << '******************'
puts msg.to_yaml
Rails.logger.level = save_level
#*******************
    search_service.fetch(docs, options)
  end

  def citation
    @response, @documents = action_documents
    respond_to do |format|
      format.html { render :layout => false }
    end
  end

  # Email Action (this will render the appropriate view on GET requests and process the form and send the email on POST requests)
#   def email_action documents
# #******************
# save_level = Rails.logger.level; Rails.logger.level = Logger::WARN
# Rails.logger.warn "jgr25_log\n#{__method__} #{__LINE__} #{__FILE__}:"
# msg = ["****************** #{__method__}"]
# msg << documents.inspect
# msg << '******************'
# puts msg.to_yaml
# Rails.logger.level = save_level
# #*******************
#     mail = RecordMailer.email_record(documents, { to: params[:to], message: params[:message], :callnumber => params[:callnumber], :status => params[:itemStatus] }, url_options, params)
#     if mail.respond_to? :deliver_now
#       mail.deliver_now
#     else
#       mail.deliver
#     end
#   end

  # grabs a bunch of documents to export to endnote or ris.
  def endnote
    Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__}  params = #{params.inspect}")
    if params[:id].nil?
      docs = @bb.index
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

  def export
    save_level = Rails.logger.level; Rails.logger.level = Logger::WARN
    Rails.logger.warn "jgr25_log #{__FILE__} #{__LINE__} #{__method__}: in authenticate"
    msg= "book_bags_controler.rb export"
    puts msg.to_yaml
    @bb.debug
    Rails.logger.level = save_level
    redirect_to :action => "index"
  end

  def track
  #******************
  save_level = Rails.logger.level; Rails.logger.level = Logger::WARN
  Rails.logger.warn "jgr25_log\n#{__method__} #{__LINE__} #{__FILE__}:"
  msg = ["****************** #{__method__}"]
  msg << params.inspect
  msg << '******************'
  puts msg.to_yaml
  Rails.logger.level = save_level
  #*******************
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