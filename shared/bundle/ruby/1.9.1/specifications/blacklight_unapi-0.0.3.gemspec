# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "blacklight_unapi"
  s.version = "0.0.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Chris Beer"]
  s.date = "2012-07-24"
  s.email = ["chris_beer@wgbh.org"]
  s.homepage = "http://projectblacklight.org/"
  s.require_paths = ["lib"]
  s.rubyforge_project = "blacklight"
  s.rubygems_version = "1.8.24"
  s.summary = "Blacklight unapi plugin"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rails>, ["~> 3.0"])
      s.add_runtime_dependency(%q<blacklight>, ["> 3.2"])
    else
      s.add_dependency(%q<rails>, ["~> 3.0"])
      s.add_dependency(%q<blacklight>, ["> 3.2"])
    end
  else
    s.add_dependency(%q<rails>, ["~> 3.0"])
    s.add_dependency(%q<blacklight>, ["> 3.2"])
  end
end
