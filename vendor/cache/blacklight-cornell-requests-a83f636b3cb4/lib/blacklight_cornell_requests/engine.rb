require 'rails'

module BlacklightCornellRequests

  class Engine < ::Rails::Engine
    isolate_namespace BlacklightCornellRequests

    # Add the path for the engine's migrations to the main app's migration paths
    initializer :append_migrations do |app|
    	unless app.root.to_s.match root.to_s
          app.config.paths['db/migrate'] << config.paths['db/migrate'].expanded[0]
      end
    end
    
  end
  
  def self.config(&block)
    yield Engine.config if block
    Engine.config
  end
end
