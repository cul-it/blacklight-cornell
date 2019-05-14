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

  #copy_blacklight_config_from(CatalogController)
  #
  before_action :authenticate_user!

  before_filter :heading
  append_before_filter :set_bag_name
  
  def set_bag_name
    @id = current_user.email
    @bb.bagname = "#{@id}-bookbag-default"
    user_session[:bookbag_count] = @bb.count
  end

  def heading
   @heading='BookBag'
  end

  def initialize
    super
    @bb = Bookbag.new(nil)
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
      success = @bb.create(value)
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
        bookmark_ids = bookmark_ids.split(0, bookmarks_max)
      end
      if not bookmark_ids.to_s.empty?
        bookmark_ids.each do | v |
          if /[0-9]+/.match(v)
            v.prepend('bibid-')
            success = @bb.create(v)
          end
        end
        user_session[:bookbag_count] = @bb.count
      end
    end
    Rails.logger.level = @savedll
    redirect_to :action => "index"
  end

  def delete
    @bibid = params[:id]
    value = "bibid-#{@bibid}"
    Rails.logger.info("es287_debug #{__FILE__} #{__LINE__} #{__method__} @bb = #{@bb.inspect}")
    Rails.logger.info("es287_debug #{__FILE__} #{__LINE__} #{__method__} value = #{value.inspect}")
    success = @bb.delete(value)
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
    @response,@documents = fetch docs
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
    fetch docs, options
  end

  def email
    # file = File.open("jgr25_debug.log", File::WRONLY | File::APPEND | File::CREAT)
    # logger = Logger.new(file)
    # logger.level = :info
    # logger.info("jgr25_debug #{__FILE__}:#{__LINE__}  request.xhr?  = #{request.xhr?.inspect}")
    # logger.info("jgr25_debug #{__FILE__}:#{__LINE__}  request.post?  = #{request.post?.inspect}")
    @bms =@bb.index
    all_docs = @bms.map {|b| b.sub!("bibid-",'')}
    if request.post?
      url_gen_params = {:host => request.host_with_port, :protocol => request.protocol, :params => params}
      if params[:to] && params[:to].match(/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
        all_docs.each_slice(20) do |docs|
          @response, @documents = fetch docs
          # logger.info("jgr25_debug #{__FILE__}:#{__LINE__}  docs  = #{docs.inspect}")
          url_gen_params = {:host => request.host_with_port, :protocol => request.protocol, :params => params}
          email ||= RecordMailer.email_record(@documents, {:to => params[:to], :message => params[:message], :callnumber => params[:callnumber], :status => params[:itemStatus],}, url_gen_params, params)
          email.deliver_now
        end
        flash[:success] = "Email sent"
        redirect_to solr_document_path(params[:id]) unless request.xhr?
      else
        flash[:error] = I18n.t('blacklight.email.errors.to.invalid', :to => params[:to])
      end
    end

    # logger.info("jgr25_debug #{__FILE__}:#{__LINE__}  finished emails  = #{flash.inspect}")

    @bms =@bb.index
    docs = @bms.map {|b| b.sub!("bibid-",'')}
    @response, @documents = fetch docs
    Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__}  request.xhr?  = #{request.xhr?.inspect}")
    Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__}  flash  = #{flash.inspect}")
    if   ENV['SAML_IDP_TARGET_URL']
      if request.xhr? && flash[:success]
        if docs.size < 2

          if !params[:id][0].nil?
            bibid = params[:id][0] 
            render :js => "window.location = '/catalog/#{bibid}'"
          else
            render :js => "window.location = '/catalog"
          end

        else
          render :js => "window.location = '/book_bags/index'"
        end
        return
      end
    end
    unless !request.xhr? && flash[:success]
      respond_to do |format|
        format.js { render :layout => false }
        format.html
      end
    end
  end

    # grabs a bunch of documents to export to endnote or ris.
    def endnote
      Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__}  params = #{params.inspect}")
      if params[:id].nil?
        @bms =@bb.index
        docs = @bms.map {|b| b.sub!("bibid-",'')}
        @response, @documents = fetch(docs, :per_page => 1000,:rows => 1000)
        Rails.logger.debug("es287_debug #{__FILE__}:#{__LINE__}  @documents = #{@documents.size.inspect}")
      else
        @response, @documents = fetch(params[:id])
      end
      respond_to do |format|
        format.endnote  { render :layout => false } #wrapped render :layout => false in {} to allow for multiple items jac244
        format.ris      { render 'ris', :layout => false }
      end
    end





end
