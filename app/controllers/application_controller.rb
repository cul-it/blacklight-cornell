class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  # Please be sure to impelement current_user and user_session. Blacklight depends on
  # these methods in order to perform user specific actions.
  #prepend_before_filter :set_return_path

  layout 'blacklight'

  #protect_from_forgery with:  :exception
  protect_from_forgery with:  :null_session

  set_callback :logging_in_user, :before, :show_login_action

# An array of strings to be added to HTML HEAD section of view.
# See ApplicationHelper#render_head_content for details.
   def extra_head_content
       #Deprecation.warn Blacklight::LegacyControllerMethods, "#extra_head_content is NOT deprecated"
        @extra_head_content ||= []
   end

   def show_login_action 
     Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__} logging in before hook")
   end


protected
  def authenticate_user!
    Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__} authenticate user")
    if user_signed_in?
      Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__} authenticate user call super")
      super
    else
      Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__} authenticate redirect to saml ")
      if ENV['SAML_IDP_TARGET_URL'] 
        #redirect_to 'http://es287-dev.library.cornell.edu:8988/saml.html'
        redirect_to request.base_url + '/saml.html'
      end 
      #redirect_to 'http://es287-dev.library.cornell.edu:8986/users/auth/saml'
      #redirect_to new_user_session_path, :notice => 'if you want to add a notice'
      ## if you want render 404 page
      #      ## render :file => File.join(Rails.root, 'public/404'), :formats => [:html], :status => 404, :layout => false
    end
  end

  if false 
  def set_return_path
    Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__}  params = #{params.inspect}")
    op = request.original_fullpath
    Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__}  original = #{op.inspect}")
    refp = request.referer
    Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__}  referer path = #{refp}")
    session[:cuwebauth_return_path] =
      if (params['id'].present? && params['id'].include?('|'))
        '/bookmarks'
      elsif (params['id'].present? && op.include?('email'))
        "/catalog/afemail/#{params[:id]}"
      elsif (params['id'].present? && op.include?('unapi'))
         refp
      else
        op
      end
    Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__}  return path = #{session[:cuwebauth_return_path]}")
    return true
  end
  end

end
