# Based on the Module#prepend pattern in ruby.
Rails.application.config.to_prepare do
  Blacklight::SearchService.prepend(Blacklight::SearchServiceOverride)
end
