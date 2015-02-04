require 'rails/generators'
require 'rails/generators/base'
require 'rails/generators/migration'

class BlacklightUnapiGenerator < Rails::Generators::Base
  include Rails::Generators::Migration
  source_root File.expand_path('../templates', __FILE__)
  

  argument :controller_name, :type => :string, :default => "CatalogController"

  def inject_catalog_controller_extension
    file_path = "app/controllers/#{controller_name.underscore}.rb"
    if File.exists? file_path
      inject_into_file file_path, :after => "include Blacklight::Catalog" do
        "\n  include BlacklightUnapi::ControllerExtension\n"
      end
    end
  end

  def inject_unapi_configuration
    insert_into_file 'config/initializers/blacklight_config.rb', :after => "config[:spell_max] = 5\n" do <<EOF

  # Add documents to the list of object formats that are supported for all objects.
  # This parameter is a hash, identical to the Blacklight::Solr::Document#export_formats 
  # output; keys are format short-names that can be exported. Hash includes:
  #    :content-type => mime-content-type
    
  config[:unapi] = {
    'oai_dc_xml' => { :content_type => 'text/xml' } 
  }
EOF
    end
  end
end
