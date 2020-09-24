class ErrorsController < ApplicationController
  def not_found
    render(:status => 404)
  end

  def internal_server_error
    @time = Time.now.to_s
    @server = request.env['SERVER_NAME'].to_s
    @message = request.env["action_dispatch.exception"].class.name
    @request = request.env["REQUEST_URI"].to_s
    @test = "text"
    render(:status => 500)
  end

  def index
    render("Errors Index")
  end

end
