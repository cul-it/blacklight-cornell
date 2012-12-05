# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "blacklight"
  s.version = "4.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jonathan Rochkind", "Matt Mitchell", "Chris Beer", "Jessie Keck", "Jason Ronallo", "Vernon Chapman", "Mark A. Matienzo", "Dan Funk", "Naomi Dushay"]
  s.date = "2012-11-30"
  s.description = "Blacklight is an open source Solr user interface discovery platform. You can use Blacklight to enable searching and browsing of your collections. Blacklight uses the Apache Solr search engine to search full text and/or metadata."
  s.email = ["blacklight-development@googlegroups.com"]
  s.homepage = "http://projectblacklight.org/"
  s.require_paths = ["lib"]
  s.rubyforge_project = "blacklight"
  s.rubygems_version = "1.8.24"
  s.summary = "Blacklight provides a discovery interface for any Solr (http://lucene.apache.org/solr) index."

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rails>, ["~> 3.2"])
      s.add_runtime_dependency(%q<nokogiri>, ["~> 1.5"])
      s.add_runtime_dependency(%q<marc>, ["< 1.1", ">= 0.4.3"])
      s.add_runtime_dependency(%q<rsolr>, ["~> 1.0.6"])
      s.add_runtime_dependency(%q<kaminari>, ["~> 0.13"])
      s.add_runtime_dependency(%q<sass-rails>, [">= 0"])
      s.add_runtime_dependency(%q<bootstrap-sass>, ["~> 2.1.0"])
      s.add_development_dependency(%q<jettywrapper>, [">= 1.2.0"])
    else
      s.add_dependency(%q<rails>, ["~> 3.2"])
      s.add_dependency(%q<nokogiri>, ["~> 1.5"])
      s.add_dependency(%q<marc>, ["< 1.1", ">= 0.4.3"])
      s.add_dependency(%q<rsolr>, ["~> 1.0.6"])
      s.add_dependency(%q<kaminari>, ["~> 0.13"])
      s.add_dependency(%q<sass-rails>, [">= 0"])
      s.add_dependency(%q<bootstrap-sass>, ["~> 2.1.0"])
      s.add_dependency(%q<jettywrapper>, [">= 1.2.0"])
    end
  else
    s.add_dependency(%q<rails>, ["~> 3.2"])
    s.add_dependency(%q<nokogiri>, ["~> 1.5"])
    s.add_dependency(%q<marc>, ["< 1.1", ">= 0.4.3"])
    s.add_dependency(%q<rsolr>, ["~> 1.0.6"])
    s.add_dependency(%q<kaminari>, ["~> 0.13"])
    s.add_dependency(%q<sass-rails>, [">= 0"])
    s.add_dependency(%q<bootstrap-sass>, ["~> 2.1.0"])
    s.add_dependency(%q<jettywrapper>, [">= 1.2.0"])
  end
end
