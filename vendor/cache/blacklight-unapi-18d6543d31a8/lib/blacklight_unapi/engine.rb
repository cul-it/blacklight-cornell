require 'blacklight'
require 'blacklight_unapi'
require 'rails'

module BlacklightUnapi
  class Engine < Rails::Engine
    config.to_prepare do
      unless BlacklightUnapi.omit_inject[:routes]
        Blacklight::Routes.send(:include, BlacklightUnapi::RouteSets)
      end
    end
  end
end
