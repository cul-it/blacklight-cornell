module BlacklightCornell::Errors
  extend ActiveSupport::Concern

  included do
    # When RSolr::RequestError is raised, the handle_request_error method is executed.
    # Example, when the standard query parser is used, and a user submits a "bad" query.
    rescue_from RSolr::Error::Http, :with => :handle_request_error
    rescue_from Blacklight::Exceptions::InvalidRequest, :with => :handle_request_error
  end

  def handle_request_error(exception)
    # Rails own code will catch and give usual Rails error page with stack trace
    raise exception if Rails.env.development? || Rails.env.test?

    flash_notice = I18n.t('blacklight.search.errors.request_error')

    # If there are errors coming from the index page, we want to trap those sensibly

    if flash[:notice] == flash_notice
      logger&.error "Cowardly aborting rsolr_request_error exception handling, because we redirected to a page that raises another exception"
      raise exception
    end

    logger&.error exception

    flash[:notice] = flash_notice
    redirect_to search_action_url
  end
end
