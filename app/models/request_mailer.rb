# -*- encoding : utf-8 -*-
class RequestMailer < ActionMailer::Base
  default :from => "culsearch@cornell.edu"
  default :subject => "Purchase Request"
  default :to => "mjc12@cornell.edu"
  def email_request(user, params)
        
    #subject = I18n.t('blacklight.email.text.subject', :count => documents.length, :title => (documents.first.to_semantic_values[:title] rescue 'N/A') )

    # @documents      = documents
    # @message        = details[:message]
    # @callnumber     = details[:callnumber]
    # @location       = details[:location]
    # @url_gen_params = url_gen_params
    @params = params
    @user = user
    
    mail().deliver
    logger.debug "Sent purchase request on behalf of #{user}."
  end
  
end
