# -*- encoding: utf-8 -*-
# stub: blacklight_unapi 0.0.3 ruby lib

Gem::Specification.new do |s|
  s.name = "blacklight_unapi"
  s.version = "0.0.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Chris Beer"]
  s.date = "2015-05-27"
  s.email = ["chris_beer@wgbh.org"]
  s.files = ["MIT-LICENSE", "README.rdoc", "Rakefile", "VERSION", "app/helpers/blacklight_unapi_helper.rb", "app/views/unapi/_microformat.html.erb", "app/views/unapi/formats.xml.builder", "blacklight_unapi.gemspec", "config/routes.rb", "lib/blacklight_unapi.rb", "lib/blacklight_unapi/controller_extension.rb", "lib/blacklight_unapi/engine.rb", "lib/blacklight_unapi/route_sets.rb", "lib/blacklight_unapi/version.rb", "lib/blacklight_unapi/view_helper_extension.rb", "lib/generators/blacklight_unapi/blacklight_unapi_generator.rb"]
  s.homepage = "http://projectblacklight.org/"
  s.rubyforge_project = "blacklight"
  s.rubygems_version = "2.4.3"
  s.summary = "Blacklight unapi plugin"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rails>, ["~> 4.0"])
      s.add_runtime_dependency(%q<blacklight>, ["> 3.2"])
    else
      s.add_dependency(%q<rails>, ["~> 4.0"])
      s.add_dependency(%q<blacklight>, ["> 3.2"])
    end
  else
    s.add_dependency(%q<rails>, ["~> 4.0"])
    s.add_dependency(%q<blacklight>, ["> 3.2"])
  end
end
