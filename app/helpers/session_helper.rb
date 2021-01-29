module SessionHelper
    # Returns true if the user is logged in, false otherwise.
    def logged_in?
      user_session_user = session[:cu_authenticated_user].nil? ? "Empty" : session[:cu_authenticated_user]
      user_current_user = current_user.nil? ? "Empty" : current_user
      bookbag_enabled = BookBag.enabled? ? "Yes" : "No"

#******************
save_level = Rails.logger.level; Rails.logger.level = Logger::WARN
Rails.logger.warn "jgr25_log\n#{__method__} #{__LINE__} #{__FILE__}:"
msg = [" #{__method__} ".center(60,'Z')]
msg << "user_session_user: " + user_session_user.inspect
msg << "user_current_user: " + user_current_user.inspect
msg << "bookbag_enabled: " + bookbag_enabled.inspect
msg << 'Z' * 60
msg.each { |x| puts 'ZZZ ' + x.to_yaml }
Rails.logger.level = save_level
#*******************
         user_session_user
      end

    # Confirms a logged-in user.
    def require_user_logged_in
       unless logged_in?
          flash[:danger] = "Please log in."
          redirect_to user_saml_omniauth_authorize_path
       end
    end

 end
