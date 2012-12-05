# Copy BlacklightRangeLimit assets to public folder in current app. 
# If you want to do this on application startup, you can
# add this next line to your one of your environment files --
# generally you'd only want to do this in 'development', and can
# add it to environments/development.rb:
#       require File.join(BlacklightRangeLimit.root, "lib", "generators", "blacklight", "assets_generator.rb")
#       BlacklightRangeLimit::AssetsGenerator.start(["--force", "--quiet"])


# Need the requires here so we can call the generator from environment.rb
# as suggested above. 
require 'rails/generators'
require 'rails/generators/base'
module BlacklightRangeLimit
  class AssetsGenerator < Rails::Generators::Base
    source_root File.join(BlacklightRangeLimit::Engine.root, 'app', 'assets')

    def assets
      insert_into_file "app/assets/stylesheets/application.css", :before => "*/" do
%q{
 *
 * Used by blacklight_range_limit
 *= require  'blacklight_range_limit'
 *         
}
      end

      insert_into_file "app/assets/javascripts/application.js", :after => %r{//= +require +['"]?jquery['"]? *\n} do
%q{

// For blacklight_range_limit built-in JS, if you don't want it you don't need
// this:
//= require 'blacklight_range_limit'

}          
      end
    end
    


  end
end

