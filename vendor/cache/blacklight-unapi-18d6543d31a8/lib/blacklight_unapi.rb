# BlacklightUnapi

module BlacklightUnapi
  autoload :ControllerExtension, 'blacklight_unapi/controller_extension'
  autoload :ViewHelperExtension, 'blacklight_unapi/view_helper_extension'
  autoload :RouteSets, 'blacklight_unapi/route_sets'

  require 'blacklight_unapi/version'
  require 'blacklight_unapi/engine'

  @omit_inject = {}

  def self.omit_inject=(value)
    value = Hash.new(true) if value == true
    @omit_inject = value      
  end

  def self.omit_inject ; @omit_inject ; end
  
end
