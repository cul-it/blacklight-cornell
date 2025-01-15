#########################################
## Override Blacklight Helper Methods  ##
#########################################
# ==============================================================================
# This prepends any custom helper methods you have defined with the associated
# Blacklight helper module. You can use 'super' to fallback on the blacklight
# logic if you want to extend the existing behavior.
#
# *** Only Overrides Blacklight Helper Methods You Add ***
# ------------------------------------------------------------------------------
Rails.application.config.to_prepare do
  Blacklight::SearchHistoryConstraintsHelperBehavior.prepend(CornellSearchHistoryConstraintsHelper)
end