########################################################################################################################
##  Ensure code changes hot-reload in development when using Blacklight overrides  ##
##  ------------------------------------------------------------------------------ ##
##  Overrides "render_range_input" from "range_form_component_override.rb"         ##
#####################################################################################
Rails.application.config.to_prepare do
  require_dependency Rails.root.join("app/components/blacklight_range_limit/range_form_component_override").to_s
  # Overrides BlacklightRangeLimit::RangeFormComponent
  BlacklightRangeLimit::RangeFormComponent.prepend(BlacklightRangeLimit::RangeFormComponentOverride)
end