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
  helper_path = Rails.root.join("app/helpers/cornell_search_history_constraints_helper.rb")
  # Don't require or prepend unless the file is actually present and intended to override
  if File.exist?(helper_path)
    require helper_path
    if CornellSearchHistoryConstraintsHelper.instance_methods(false).any?
      unless Blacklight::SearchHistoryConstraintsHelperBehavior < CornellSearchHistoryConstraintsHelper
        Blacklight::SearchHistoryConstraintsHelperBehavior.prepend(CornellSearchHistoryConstraintsHelper)
      end
    end
  end
end