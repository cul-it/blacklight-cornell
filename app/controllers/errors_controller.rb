class ErrorsController < ApplicationController
  def not_found
    render(:status => 404)
  end

  def internal_server_error
    @time = Time.now
    @server = request.env['SERVER_NAME']
    render(:status => 500)
  end

  def index
    render("Errors Index")
  end

end
