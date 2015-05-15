class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  # Please be sure to impelement current_user and user_session. Blacklight depends on
  # these methods in order to perform user specific actions.

  # Inject GA tracking js into head here instead of CatalogController so every
  # page in the app is tracked
  include BlacklightGoogleAnalytics::ControllerExtraHead

  layout 'blacklight'

  protect_from_forgery

# An array of strings to be added to HTML HEAD section of view.
# See ApplicationHelper#render_head_content for details.
   def extra_head_content
       #Deprecation.warn Blacklight::LegacyControllerMethods, "#extra_head_content is NOT deprecated"
        @extra_head_content ||= []
   end


end
