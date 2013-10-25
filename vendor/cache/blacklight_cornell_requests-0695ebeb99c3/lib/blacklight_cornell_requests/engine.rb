require 'rails'

module BlacklightCornellRequests
  class Engine < ::Rails::Engine
    isolate_namespace BlacklightCornellRequests
  end
  
  def self.config(&block)
    yield Engine.config if block
    Engine.config
  end
end
