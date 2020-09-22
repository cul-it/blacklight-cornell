require 'omniauth'
require 'ruby-saml'
require 'pp'

puts 'Hello, world!'

idp_metadata_parser = OneLogin::RubySaml::IdpMetadataParser.new
   # Returns OneLogin::RubySaml::Settings prepopulated with idp metadata
settings = idp_metadata_parser.parse_remote("https://shibidp-test.cit.cornell.edu/idp/shibboleth")

pp settings