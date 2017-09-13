# -*- encoding : utf-8 -*-
class CatalogController < ApplicationController

  include BlacklightRangeLimit::ControllerOverride
  include Blacklight::Catalog
  include Blacklight::SearchHelper
  include BlacklightCornell::CornellCatalog
  include BlacklightUnapi::ControllerExtension

  if   ENV['SAML_IDP_TARGET_URL']
    before_filter :authenticate_user!, only: [  :email ]
    prepend_before_filter :set_return_path
  end

  # Ensure that the configuration file is present
  begin
    SEARCH_API_CONFIG = YAML.load_file("#{::Rails.root}/config/search_apis.yml")
  rescue Errno::ENOENT
    puts <<-eos

    ******************************************************************************
    Your search_apis.yml config file is missing.
    See config/search_apis.yml.example
    ******************************************************************************

    eos
  end

  def repository_class
    Blacklight::Solr::Repository
  end
  unless  ENV['SAML_IDP_TARGET_URL']
    before_action :authorize_email_use!, only: :email
  end

  # This is used to protect the email function by limiting it to only Cornell
  # users. If not signed in, the user is prompted to click a link that redirects
  # through a CUWebAuth-protected route. The partial that's rendered doesn't
  # seem to actually appear anywhere (not sure why), but rendering 'nothing'
  # instead doesn't let the email modal appear either.
  def authorize_email_use!
    if  !session[:cu_authenticated_user].present? 
        flash[:error] = "You must <a href='/backend/cuwebauth'>login with your Cornell NetID</a> to send email.".html_safe
      # This is a bit of an ugly hack to get us back to where we started after
      # the authentication
    session[:cuwebauth_return_path] = (params['id'].present? && params['id'].include?('|')) ? '/bookmarks' : "/catalog/afemail/#{params[:id]}"
    render :partial => 'catalog/email_cuwebauth'
    end
  end

  def set_return_path
     session[:cuwebauth_return_path] = 
       if (params['id'].present? && params['id'].include?('|')) 
         '/bookmarks' 
       elsif (params['id'].present? && !params['id'].include?('|')) 
         "/catalog/afemail/#{params[:id]}"
       else 
         '/'
       end
    Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__}  params  = #{params.inspect}")
    Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__}  params = #{params.inspect}")
  end

  # Note: This function overrides the email function in the Blacklight gem found in lib/blacklight/catalog.rb
  # (in order to add Mollom/CAPTCHA integration)
  # but now we removed mollom captcha.
  def email
    Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__}  params  = #{params.inspect}")
    docs = params[:id].split '|'
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
          render :js => "window.location = '/bookmarks'"
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
  
  # Note: This function overrides the email function in the Blacklight gem found in lib/blacklight/catalog.rb
  # (in order to add Mollom/CAPTCHA integration)
  def mollom_email

    Rails.logger.debug "mjc12test: entering email"
    Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__}  params  = #{params.inspect}")

    # If multiple documents are specified (i.e., these are a list of bookmarked items being emailed)
    # then they will be passed into params[:id] in the form "bibid1/bibid2/bibid3/etc"
    #docs = params[:id].split '/'
    docs = params[:id].split '|'

    #@response, @documents = get_solr_response_for_field_values(SolrDocument.unique_key,params[:id])
    @response, @documents = fetch docs

    #Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__}  response = #{@response.inspect}")
    #Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__}  documents = #{@documents.inspect}")
    captcha_ok = false

    if request.post?
      # First check to see whether we're here as the result of an attempt to solve a CAPTCHA
      if params[:captcha_response]
        begin
           @@mollom ||= Mollom.new({:public_key => ENV['MOLLOM_PUBLIC_KEY'], :private_key => ENV['MOLLOM_PRIVATE_KEY']})
           captcha_ok = @@mollom.valid_captcha?(:session_id => params[:mollom_session], :solution => params[:captcha_response])
        rescue
          captcha_ok = true
          url_gen_params = {:host => request.host_with_port, :protocol => request.protocol, :params => params}
          email ||= RecordMailer.email_record(@documents, {:to => params[:to], :message => params[:message], :callnumber => params[:callnumber], :status => params[:itemStatus],}, url_gen_params, params)
        end

      end

      #
      if params[:to]
        url_gen_params = {:host => request.host_with_port, :protocol => request.protocol, :params => params}
      #  result = nil
        # Check for valid email address
        if params[:to].match(/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
         # captcha_ok = false #test
          unless captcha_ok
            # Create a new Mollom instance if necessary, then test the message content for spam
            @@mollom ||= Mollom.new({:public_key => ENV['MOLLOM_PUBLIC_KEY'], :private_key => ENV['MOLLOM_PRIVATE_KEY']})
            # Mollom can sometimes fail ('can't get mollom server-list'), so we have to put this next part in a begin/rescue block
            begin
                result = @@mollom.check_content(:author_mail => params[:to], :post_body => params[:message])
                if result.ham?
                    # Content is okay, we can proceed with the email
                    email ||= RecordMailer.email_record(@documents, {:to => params[:to], :message => params[:message], :callnumber => params[:callnumber], :status => params[:itemStatus],}, url_gen_params, params)
                elsif result.unsure? || result.spam? #spam?
                    # This is definite spam (according to Mollom)
                  #  captcha_ok = false
                    flash[:error] = 'Spam!'
                  #  return
                end
            rescue
                # Mollom isn't working, so we'll have to just go ahead and mail the item
                captcha_ok = true
                email ||= RecordMailer.email_record(@documents, {:to => params[:to], :message => params[:message], :callnumber => params[:callnumber], :status => params[:itemStatus],}, url_gen_params, params)
            end
          end
        else
          flash[:error] = I18n.t('blacklight.email.errors.to.invalid', :to => params[:to])
        end
      else
        flash[:error] = I18n.t('blacklight.email.errors.to.blank')
      end

      if !captcha_ok and ((!result.nil? and (result.unsure? || result.spam?)) or params[:captcha_response])  # i.e., we have to use a CAPTCHA and the user hasn't yet (successfully) submitted a solution
        @captcha = @@mollom.image_captcha
        # Need to pass through the message form elements in order to retain them in the next POST (from CAPTCHA submission)
        @email_params = { :to => params[:to], :message => params[:message], :id => params['id'], :params => params }
         flash[:error] = 'Spam!'
        return render :partial => 'catalog/captcha'
      elsif !flash[:error]
        # Don't have to show a CAPTCHA and there are no errors, so we can send the email
        email ||= RecordMailer.email_record(@documents, {:to => params[:to], :message => params[:message], :location => params[:location], :callnumber => params[:callnumber],
                                                         :templocation => params[:templocation], :status => params[:itemStatus], :params => params}, url_gen_params, params)
        email.deliver_now
        flash[:success] = "Email sent"
        Rails.logger.info("es287_debug #{__FILE__} #{__LINE__} emailing   = #{flash.inspect}")
        redirect_to solr_document_path(params[:id]) unless request.xhr?
      end

    end  # request.post?
    if false
      unless !request.xhr? && flash[:success] 
        respond_to do |format|
          format.js { render :layout => false }
          format.html
        end
      end
    end
end

def tou
    clnt = HTTPClient.new
    #Rails.logger.info("es287_debug #{__FILE__} #{__LINE__}  = #{Blacklight.solr_config.inspect}")
    solr = Blacklight.connection_config[:url]
    p = {"id" =>params[:id] , "wt" => 'json',"indent"=>"true"}
    @dbString = clnt.get_content("#{solr}/termsOfUse?"+p.to_param)
    @dbResponse = JSON.parse(@dbString)
    @db = @dbResponse['response']['docs'][0]
    @dblinks = @dbResponse['response']['docs'][0]['url_access_json']
    #Rails.logger.info("DB = #{@dbResponse.inspect}")


    if @dbResponse['response']['numFound'] == 0
        @defaultRightsText = ''
        return @defaultRightsText
    else
        @dblinks.each do |link|
            l = JSON.parse(link)
            if l["providercode"] == params[:providercode] && l["dbcode"] == params[:dbcode]
                @defaultRightsText = ''
                @ermDBResult = ::Erm_data.where(SSID: l["ssid"], Provider_Code: l["providercode"], Database_Code: l["dbcode"], Prevailing: 'true')
                if @ermDBResult.size < 1
                   @ermDBResult = ::Erm_data.where(SSID: l["ssid"], Provider_Code: l["providercode"], Prevailing: 'true')
                   if @ermDBResult.size < 1
                      @ermDBResult = ::Erm_data.where(Database_Code: l["dbcode"], Provider_Code: l["providercode"], Prevailing: 'true')
                      if @ermDBResult.size < 1
                         @ermDBResult = ::Erm_data.where(Provider_Code: l["providercode"], Prevailing: 'true', Database_Code:  '' )
                         if @ermDBResult.size < 1
                                  #   @defaultRightsText = "DatabaseCode and ProviderCode returns nothing"
                                  @defaultRightsText = "Use default rights text"
                         else
                           @db = [l]
                           #return @ermDBResult
                           break
                         end
                      else
                        @db = [l]
                       break
                      end
                   else
                     @db = [l]
                     break
                   end
                else
                  @db = [l]
                  break
                end
            end
            @db = [l]
        end
    @column_names = ::Erm_data.column_names.collect(&:to_sym)
    end

  end
  #def oclc_request
  #  Rails.logger.info("es287_debug #{__FILE__} #{__LINE__}  = #{params[:id].inspect}")
  #end




end
