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

  def add
    @bibid = params[:id]
    value = "bibid-#{@bibid}"
    Rails.logger.info("es287_debug #{__FILE__} #{__LINE__} #{__method__} @bb = #{@bb.inspect}")
    Rails.logger.info("es287_debug #{__FILE__} #{__LINE__} #{__method__} value = #{value.inspect}")
    user_session[:bookbag_count] = @bb.count
    @bb.create(value)
    respond_to do |format|
      format.html { }
      format.rss  { render :layout => false }
      format.atom { render :layout => false }
      format.json { render json:   { }      } 
    end
  end

  def delete
    @bibid = params[:id]
    value = "bibid-#{@bibid}"
    @bb.delete(value)
    user_session[:bookbag_count] = @bb.count
    respond_to do |format|
      format.html { }
      format.rss  { render :layout => false }
      format.atom { render :layout => false }
      format.json do
        render json:   { }
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


   
  def action_documents
    options =   {:per_page => 1000,:rows => 1000}
    @bms =@bb.index
    docs = @bms.map {|b| b.sub!("bibid-",'')}
    Rails.logger.info("es287_debug #{__FILE__} #{__LINE__} #{__method__} docs = #{docs.inspect}")
    fetch docs, options
  end

  def email
    @bms =@bb.index
    docs = @bms.map {|b| b.sub!("bibid-",'')}
    @response, @documents = fetch docs
    if request.post?
      url_gen_params = {:host => request.host_with_port, :protocol => request.protocol, :params => params}
      if params[:to] && params[:to].match(/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
        url_gen_params = {:host => request.host_with_port, :protocol => request.protocol, :params => params}
        email ||= RecordMailer.email_record(@documents, {:to => params[:to], :message => params[:message], :callnumber => params[:callnumber], :status => params[:itemStatus],}, url_gen_params, params)
        email.deliver_now
        flash[:success] = "Email sent"
        redirect_to solr_document_path(params[:id]) unless request.xhr?
      else
          flash[:error] = I18n.t('blacklight.email.errors.to.invalid', :to => params[:to])
      end
    end

    Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__}  request.xhr?  = #{request.xhr?.inspect}")
    Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__}  flash  = #{flash.inspect}")
    if   ENV['SAML_IDP_TARGET_URL']
      if request.xhr? && flash[:success]
        if docs.size < 2
          render :js => "window.location = '/catalog/#{params[:id]}'"
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




end
