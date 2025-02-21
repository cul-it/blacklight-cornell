################################################################
##  DACCESS-513                                               ##
##  This is a placeholder for the PDA status check            ##
##  This will be nested under 'Requests' for the status page  ##
################################################################
module Status
  class PDAStatus < StatusPage::Services::Base
    def check!
      # TODO; Add PDA status check
    end

  end
end