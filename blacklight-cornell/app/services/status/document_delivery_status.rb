###################################################################
##  DACCESS-513                                                  ##
##  This is a placeholder for the DocumentDelivery status check  ##
##  This will be nested under 'Requests' for the status page     ##
###################################################################
module Status
  class DocumentDeliveryStatus < StatusPage::Services::Base
    def check!
      # TODO; Add DocumentDelivery status check
    end

  end
end