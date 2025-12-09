class Users::SessionsController < Devise::SessionsController
# before_action :configure_sign_in_params, only: [:create]

  # GET /resource/sign_in
   def new
     super
   end

  # POST /resource/sign_in
  def create
    self.resource = warden.authenticate!(auth_options)
    set_flash_message!(:notice, :signed_in)
    sign_in(resource_name, resource)
    session[:cu_authenticated_user] = params[:user][:email]
    yield resource if block_given?
    respond_with resource, location: after_sign_in_path_for(resource)
  end

  # GET /resource/sign_out
  def destroy
    session[:cu_authenticated_user]  = nil  unless session.nil?
    super
  end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end
end
