class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController

  # POST from SAML IdP won't include CSRF token
  skip_before_action :verify_authenticity_token


 def facebook
    auth = request.env["omniauth.auth"] 
    semail = auth.info.email
    u = User.where(email: semail).first
    if u
      @user = u
    else 
      @user = User.new(email: semail) 
      @user.save!
    end
    provider = 'Facebook'
    if @user.persisted?
      flash[:notice] = I18n.t("devise.omniauth_callbacks.success", kind: provider)
      if session[:cuwebauth_return_path].present?  
        path = session[:cuwebauth_return_path]
        Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__} path =  #{path}")
        session[:cuwebauth_return_path] = nil
        sign_in :user, @user 
        redirect_to path, :notice => "You are logged in as #{request.env["omniauth.auth"].info.name}."
        return
      else  
        redirect_to root_path, :notice => "You are logged in as #{request.env["omniauth.auth"].info.name}."
      end
      sign_in :user, @user 
      #sign_in_and_redirect @user, event: :authentication
    else
      session["devise.facebook_data"] = oauth_response.except(:extra)
      params[:error] = :account_not_found
      #do_failure_things
      redirect_to root_path, :notice => "You are not logged in."
    end
  end

#https://www.interexchange.org/articles/engineering/lets-devise-google-oauth-login/
 def google_oauth2
    auth = request.env["omniauth.auth"] 
    semail = auth.info.email
    u = User.where(email: semail).first
    if u
      @user = u
    else 
      @user = User.new(email: semail) 
      @user.save!
    end
    provider = 'Google'
    if @user.persisted?
      flash[:notice] = I18n.t("devise.omniauth_callbacks.success", kind: provider)
      if session[:cuwebauth_return_path].present?  
        path = session[:cuwebauth_return_path]
        Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__} path =  #{path}")
        session[:cuwebauth_return_path] = nil
        sign_in :user, @user 
        redirect_to path, :notice => "You are logged in as #{request.env["omniauth.auth"].info.name}."
        return
      else  
        redirect_to root_path, :notice => "You are logged in as #{request.env["omniauth.auth"].info.name}."
      end
      sign_in :user, @user 
      #sign_in_and_redirect @user, event: :authentication
    else
      session["devise.google_data"] = oauth_response.except(:extra)
      params[:error] = :account_not_found
      #do_failure_things
      redirect_to root_path, :notice => "You are not logged in."
    end
  end

  def saml
    auth = request.env["omniauth.auth"] 
    semail = auth.info.email[0]
    u = User.where(email: semail).first
    if u
      @user = u
    else 
      @user = User.new(email: semail) 
      @user.save!
    end
    OneLogin::RubySaml::Attributes.single_value_compatibility = false 
    # I had some code that parsed the response -- but evidently this is not
    # necessary at all!
    #if OmniAuth.config.test_mode
    #  sam_response          = OneLogin::RubySaml::Response.new(params[:SAMLResponse])
    #else
    #   sam_response = auth.saml_resp
    #end
    Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__} omniauth.auth.extra.raw_info=  #{auth['extra']['raw_info'].inspect}" )
    Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__} omniauth.auth.attr =  #{auth.info} #{auth.info.name} #{auth.info.last_name}")
    Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__} @user =  #{@user.inspect}")
    #because of single_value_compatibility all values are returned in arrays, even singled valued.
    session[:cu_authenticated_netid] = auth.info.netid[0]
    # Using email does not translate to netid for 'vanity' email addresses, like frances.webb@cornell.edu
    #session[:cu_authenticated_user] = auth.info.email[0]
    session[:cu_authenticated_user] = auth.info.netid[0]
    session[:cu_authenticated_email] = auth.info.email[0]
    session[:cu_authenticated_groups] = auth.info.groups
    session[:cu_authenticated_primary] = (auth.info.primary.nil? || auth.info.primary[0].nil?)   ? ''  : auth.info.primary[0]  
    # we might already be 'signed in' ?
    if !user_signed_in? 
      sign_in :user, @user 
    end
    session[:cu_authenticated_user] = auth.info.email[0]
    if session[:cuwebauth_return_path].present?  
      path = session[:cuwebauth_return_path]
      Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__} path =  #{path}")
      session[:cuwebauth_return_path] = nil
      redirect_to path, :notice => "You are logged in as #{request.env["omniauth.auth"].info.name.first}."
      return
    else  
      redirect_to root_path, :notice => "You are logged in as #{request.env["omniauth.auth"].info.name.first}."
    end
  end

    #if @user.nil?
    #  redirect_to root_path, :notice => "Hi <strong>#{request.env["omniauth.auth"].info.name}</strong>. You do not currently have an account in the student workers site. Please email <a href='mailto:mann_supervisor@cornell.edu' title='Step right up'>mann_supervisor@cornell.edu</a> to request an account."
    #else
    #  sign_in_and_redirect @user
    #  set_flash_message(:notice, :success, :kind => "Cornell NetID") if is_navigational_format?
    #end

  # def failure
  #   redirect_to root_path
  # end

  # GET|POST /resource/auth/twitter
  # def passthru
  #   super
  # end

  # GET|POST /users/auth/twitter/callback
  # def failure
  #   super
  # end

  # protected

  # The path used when OmniAuth fails
  # def after_omniauth_failure_path_for(scope)
  #   super(scope)
  # end
end

# @attributes=
#  {"urn:oid:1.3.6.1.4.1.5923.1.1.1.7"=>
#    ["urn:mace:dir:entitlement:common-lib-terms",
#     "urn:mace:oclc.org:100-155-803",
#     "urn:mace:cornell.edu:lynda:user",
#     "urn:mace:incommon:entitlement:common:1",
#     "urn:mace:cornell.edu:labarchives:user"],
#   "urn:oid:2.5.4.3"=>["Enrico Silterra"],
#   "urn:oid:0.9.2342.19200300.100.1.3"=>["es287@cornell.edu"],
#   "urn:oid:1.3.6.1.4.1.5923.1.1.1.1"=>["member", "staff", "employee", "alum"],
#   "urn:oid:2.16.840.1.113730.3.1.241"=>["Enrico Silterra"],
#   "urn:oid:2.5.4.42"=>["Enrico"],
#   "urn:oid:1.3.6.1.4.1.5923.1.1.1.3"=>["o=Cornell University, c=US"],
#   "urn:oid:0.9.2342.19200300.100.1.1"=>["es287"],
#   "urn:oid:1.3.6.1.4.1.5923.1.1.1.9"=>
#    ["member@cornell.edu",
#     "staff@cornell.edu",
#     "alum@cornell.edu",
#     "employee@cornell.edu"],
#   "urn:oid:2.5.4.4"=>["Silterra"],
#   "urn:oid:1.3.6.1.4.1.5923.1.1.1.5"=>["staff"],
#   "urn:oid:1.3.6.1.4.1.5923.1.1.1.6"=>["es287@cornell.edu"],
#
## the friendly names can be used as symbol keys into the attributes.
#<Saml2:AttributeStatement>
#<saml2:Attribute FriendlyName="eduPersonEntitlement" Name="urn:oid:1.3.6.1.4.1.5923.1.1.1.7" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:uri"><saml2:AttributeValue>urn:mace:dir:entitlement:common-lib-terms</saml2:AttributeValue><saml2:AttributeValue>urn:mace:oclc.org:100-155-803</saml2:AttributeValue><saml2:AttributeValue>urn:mace:cornell.edu:lynda:user</saml2:AttributeValue><saml2:AttributeValue>urn:mace:incommon:entitlement:common:1</saml2:AttributeValue><saml2:AttributeValue>urn:mace:cornell.edu:labarchives:user</saml2:AttributeValue></saml2:Attribute>
#<saml2:Attribute FriendlyName="cn" Name="urn:oid:2.5.4.3" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:uri"><saml2:AttributeValue>Enrico Silterra</saml2:AttributeValue></saml2:Attribute>
#<saml2:Attribute FriendlyName="mail" Name="urn:oid:0.9.2342.19200300.100.1.3" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:uri"><saml2:AttributeValue>es287@cornell.edu</saml2:AttributeValue></saml2:Attribute>
#<saml2:Attribute FriendlyName="eduPersonAffiliation" Name="urn:oid:1.3.6.1.4.1.5923.1.1.1.1" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:uri"><saml2:AttributeValue>member</saml2:AttributeValue><saml2:AttributeValue>staff</saml2:AttributeValue><saml2:AttributeValue>employee</saml2:AttributeValue><saml2:AttributeValue>alum</saml2:AttributeValue></saml2:Attribute>
#<saml2:Attribute FriendlyName="displayName" Name="urn:oid:2.16.840.1.113730.3.1.241" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:uri"><saml2:AttributeValue>Enrico Silterra</saml2:AttributeValue></saml2:Attribute>
#<saml2:Attribute FriendlyName="givenName" Name="urn:oid:2.5.4.42" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:uri"><saml2:AttributeValue>Enrico</saml2:AttributeValue></saml2:Attribute>
#<saml2:Attribute FriendlyName="eduPersonOrgDN" Name="urn:oid:1.3.6.1.4.1.5923.1.1.1.3" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:uri"><saml2:AttributeValue>o=Cornell University, c=US</saml2:AttributeValue></saml2:Attribute>
#<saml2:Attribute FriendlyName="uid" Name="urn:oid:0.9.2342.19200300.100.1.1" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:uri"><saml2:AttributeValue>es287</saml2:AttributeValue></saml2:Attribute>
#<saml2:Attribute FriendlyName="eduPersonScopedAffiliation" Name="urn:oid:1.3.6.1.4.1.5923.1.1.1.9" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:uri"><saml2:AttributeValue>member@cornell.edu</saml2:AttributeValue><saml2:AttributeValue>staff@cornell.edu</saml2:AttributeValue><saml2:AttributeValue>alum@cornell.edu</saml2:AttributeValue><saml2:AttributeValue>employee@cornell.edu</saml2:AttributeValue></saml2:Attribute>
#<saml2:Attribute FriendlyName="sn" Name="urn:oid:2.5.4.4" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:uri"><saml2:AttributeValue>Silterra</saml2:AttributeValue></saml2:Attribute>
#<saml2:Attribute FriendlyName="edupersonprimaryaffiliation" Name="urn:oid:1.3.6.1.4.1.5923.1.1.1.5" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:uri"><saml2:AttributeValue>staff</saml2:AttributeValue></saml2:Attribute>
#<saml2:Attribute FriendlyName="eduPersonPrincipalName" Name="urn:oid:1.3.6.1.4.1.5923.1.1.1.6" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:uri"><saml2:AttributeValue>es287@cornell.edu</saml2:AttributeValue></saml2:Attribute></saml2:AttributeStatement>
