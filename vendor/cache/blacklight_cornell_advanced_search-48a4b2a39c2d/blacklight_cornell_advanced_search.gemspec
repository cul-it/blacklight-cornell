# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "blacklight_cornell_advanced_search"
  s.version = "2.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jonathan Rochkind", "Chris Beer"]
  s.date = "2013-11-15"
  s.email = ["blacklight-development@googlegroups.com"]
  s.files = [".gitignore", "Gemfile", "Gemfile.lock", "LICENSE", "README.rdoc", "Rakefile", "VERSION", "app/assets/javascripts/blacklight_cornell_advanced_search.js", "app/assets/javascripts/blacklight_cornell_advanced_search/blacklight_cornell_advanced_search_javascript.js", "app/assets/stylesheets/blacklight_cornell_advanced_search.css", "app/assets/stylesheets/blacklight_cornell_advanced_search/advanced_results.css", "app/assets/stylesheets/blacklight_cornell_advanced_search/blacklight_cornell_advanced_search_styles.css.scss", "app/controllers/advanced_controller.rb", "app/controllers/blacklight_cornell_advanced_search/advanced_controller.rb", "app/helpers/advanced_helper.rb", "app/views/advanced/_advanced_search_facets.html.erb", "app/views/advanced/_advanced_search_fields.html.erb", "app/views/advanced/_advanced_search_form.html.erb", "app/views/advanced/_advanced_search_form_Orig.html.erb", "app/views/advanced/_advanced_search_help.html.erb", "app/views/advanced/_advanced_search_rows.html.erb", "app/views/advanced/_edit_advanced_search_form.html.erb", "app/views/advanced/_facet_layout.html.erb", "app/views/advanced/_facet_limit.html.erb", "app/views/advanced/edit.html.erb", "app/views/advanced/index.html.erb", "app/views/advanced/index.html_Orig.erb", "app/views/blacklight_cornell_advanced_search/_facet_limit.html.erb", "blacklight_cornell_advanced_search.gemspec", "config/routes.rb", "install.rb", "lib/blacklight_cornell_advanced_search.rb", "lib/blacklight_cornell_advanced_search/advanced_query_parser.rb", "lib/blacklight_cornell_advanced_search/catalog_helper_override.rb", "lib/blacklight_cornell_advanced_search/controller.rb", "lib/blacklight_cornell_advanced_search/engine.rb", "lib/blacklight_cornell_advanced_search/filter_parser.rb", "lib/blacklight_cornell_advanced_search/parse_basic_q.rb", "lib/blacklight_cornell_advanced_search/parsing_nesting_parser.rb", "lib/blacklight_cornell_advanced_search/render_constraints_override.rb", "lib/blacklight_cornell_advanced_search/version.rb", "lib/generators/blacklight_cornell_advanced_search/assets_generator.rb", "lib/generators/blacklight_cornell_advanced_search/blacklight_cornell_advanced_search_generator.rb", "lib/generators/blacklight_cornell_advanced_search/templates/_search_form.html.erb", "lib/generators/blacklight_cornell_advanced_search/templates/advanced_controller.rb", "lib/parsing_nesting/Readme.rdoc", "lib/parsing_nesting/grammar.rb", "lib/parsing_nesting/tree.rb", "spec/acceptance/blacklight_cornell_advanced_search_form_spec.rb", "spec/integration/blacklight_stub_spec.rb", "spec/internal/app/controllers/application_controller.rb", "spec/internal/app/models/solr_document.rb", "spec/internal/config/database.yml", "spec/internal/config/routes.rb", "spec/internal/config/solr.yml", "spec/internal/db/combustion_test.sqlite", "spec/internal/db/schema.rb", "spec/internal/log/.gitignore", "spec/internal/public/favicon.ico", "spec/lib/filter_parser_spec.rb", "spec/parsing_nesting/build_tree_spec.rb", "spec/parsing_nesting/consuming_spec.rb", "spec/parsing_nesting/to_solr_spec.rb", "spec/rcov.opts", "spec/spec.opts", "spec/spec_helper.rb", "uninstall.rb"]
  s.homepage = "http://projectblacklight.org/"
  s.require_paths = ["lib"]
  s.rubyforge_project = "blacklight"
  s.rubygems_version = "1.8.25"
  s.summary = "Blacklight Cornell Advanced Search plugin"
  s.test_files = ["spec/acceptance/blacklight_cornell_advanced_search_form_spec.rb", "spec/integration/blacklight_stub_spec.rb", "spec/internal/app/controllers/application_controller.rb", "spec/internal/app/models/solr_document.rb", "spec/internal/config/database.yml", "spec/internal/config/routes.rb", "spec/internal/config/solr.yml", "spec/internal/db/combustion_test.sqlite", "spec/internal/db/schema.rb", "spec/internal/log/.gitignore", "spec/internal/public/favicon.ico", "spec/lib/filter_parser_spec.rb", "spec/parsing_nesting/build_tree_spec.rb", "spec/parsing_nesting/consuming_spec.rb", "spec/parsing_nesting/to_solr_spec.rb", "spec/rcov.opts", "spec/spec.opts", "spec/spec_helper.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<blacklight>, [">= 0"])
      s.add_runtime_dependency(%q<parslet>, [">= 0"])
      s.add_development_dependency(%q<bootstrap>, [">= 0"])
      s.add_development_dependency(%q<rails>, [">= 0"])
      s.add_development_dependency(%q<combustion>, [">= 0"])
      s.add_development_dependency(%q<rspec-rails>, [">= 0"])
      s.add_development_dependency(%q<capybara>, [">= 0"])
      s.add_development_dependency(%q<sqlite3>, [">= 0"])
      s.add_development_dependency(%q<launchy>, [">= 0"])
      s.add_development_dependency(%q<jettywrapper>, [">= 0"])
    else
      s.add_dependency(%q<blacklight>, [">= 0"])
      s.add_dependency(%q<parslet>, [">= 0"])
      s.add_dependency(%q<bootstrap>, [">= 0"])
      s.add_dependency(%q<rails>, [">= 0"])
      s.add_dependency(%q<combustion>, [">= 0"])
      s.add_dependency(%q<rspec-rails>, [">= 0"])
      s.add_dependency(%q<capybara>, [">= 0"])
      s.add_dependency(%q<sqlite3>, [">= 0"])
      s.add_dependency(%q<launchy>, [">= 0"])
      s.add_dependency(%q<jettywrapper>, [">= 0"])
    end
  else
    s.add_dependency(%q<blacklight>, [">= 0"])
    s.add_dependency(%q<parslet>, [">= 0"])
    s.add_dependency(%q<bootstrap>, [">= 0"])
    s.add_dependency(%q<rails>, [">= 0"])
    s.add_dependency(%q<combustion>, [">= 0"])
    s.add_dependency(%q<rspec-rails>, [">= 0"])
    s.add_dependency(%q<capybara>, [">= 0"])
    s.add_dependency(%q<sqlite3>, [">= 0"])
    s.add_dependency(%q<launchy>, [">= 0"])
    s.add_dependency(%q<jettywrapper>, [">= 0"])
  end
end
