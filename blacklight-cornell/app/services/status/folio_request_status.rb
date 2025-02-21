#########################################################################
##  DACCESS-513                                                        ##
##  This is a placeholder for the FolioRequest status check            ##
##  Currently OKAPI is being used, but this wil change in the future.  ##
##  Kong will be used instead, starting around June/July 2025          ##
##  https://konghq.com/                                                ##
##  https://docs.konghq.com/gateway/api/admin-oss/latest/              ##
#########################################################################
module Status
  class FolioRequestStatus < StatusPage::Services::Base
    def check!
      # TODO; Add FolioRequest status check
    end

  end
end
