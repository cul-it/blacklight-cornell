# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "blankslate"
  s.version = "2.1.2.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jim Weirich", "David Masover", "Jack Danger Canty"]
  s.date = "2011-03-16"
  s.email = "rubygems@6brand.com"
  s.homepage = "http://github.com/masover/blankslate"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.24"
  s.summary = "BlankSlate extracted from Builder."

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>, [">= 0"])
      s.add_development_dependency(%q<bundler>, [">= 0"])
    else
      s.add_dependency(%q<rspec>, [">= 0"])
      s.add_dependency(%q<bundler>, [">= 0"])
    end
  else
    s.add_dependency(%q<rspec>, [">= 0"])
    s.add_dependency(%q<bundler>, [">= 0"])
  end
end
