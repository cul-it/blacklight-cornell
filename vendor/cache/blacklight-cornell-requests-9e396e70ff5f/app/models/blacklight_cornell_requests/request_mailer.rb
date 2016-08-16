# -*- encoding : utf-8 -*-
module BlacklightCornellRequests
  class RequestMailer < ActionMailer::Base
    
    default :from => "culsearch@cornell.edu"
    default :subject => "Purchase Request"
    default :to => "aa19@cornell.edu"
    
    def email_request(user, params)
      @params = params
      @user = user
      mail(:from => "#{@params['name']} <#{@params['email']}>", :subject => "Request for library materials for #{@params['name']}").deliver
      logger.debug "Sent purchase request on behalf of #{user}."
    end
  end
end
