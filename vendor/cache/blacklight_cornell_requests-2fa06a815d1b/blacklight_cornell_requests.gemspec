# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "blacklight_cornell_requests"
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Shinwoo Kim", "Matt Connolly"]
  s.date = "2013-09-25"
  s.description = "Given a bibid, provide user with the best delivery option and all other available options."
  s.email = ["cul-da-developers-l@list.cornell.edu"]
  s.files = ["app/helpers", "app/helpers/blacklight_cornell_requests", "app/helpers/blacklight_cornell_requests/application_helper.rb", "app/helpers/blacklight_cornell_requests/request_helper.rb", "app/controllers", "app/controllers/blacklight_cornell_requests", "app/controllers/blacklight_cornell_requests/application_controller.rb", "app/controllers/blacklight_cornell_requests/request_controller.rb", "app/models", "app/models/blacklight_cornell_requests", "app/models/blacklight_cornell_requests/request_mailer.rb", "app/models/blacklight_cornell_requests/request.rb", "app/assets", "app/assets/stylesheets", "app/assets/stylesheets/blacklight_cornell_requests", "app/assets/stylesheets/blacklight_cornell_requests/request.css", "app/assets/stylesheets/blacklight_cornell_requests/application.css", "app/assets/images", "app/assets/images/blacklight_cornell_requests", "app/assets/javascripts", "app/assets/javascripts/blacklight_cornell_requests", "app/assets/javascripts/blacklight_cornell_requests/requests.js.coffee", "app/assets/javascripts/blacklight_cornell_requests.js", "app/views", "app/views/blacklight_cornell_requests", "app/views/blacklight_cornell_requests/request_mailer", "app/views/blacklight_cornell_requests/request_mailer/email_request.html.erb", "app/views/blacklight_cornell_requests/request", "app/views/blacklight_cornell_requests/request/l2l.html.haml", "app/views/blacklight_cornell_requests/request/pda.html.haml", "app/views/blacklight_cornell_requests/request/ask.html.haml", "app/views/blacklight_cornell_requests/request/circ.html.haml", "app/views/blacklight_cornell_requests/request/ill.html.haml", "app/views/blacklight_cornell_requests/request/document_delivery.html.haml", "app/views/blacklight_cornell_requests/request/purchase.html.haml", "app/views/blacklight_cornell_requests/request/recall.html.haml", "app/views/blacklight_cornell_requests/request/hold.html.haml", "app/views/blacklight_cornell_requests/request/bd.html.haml", "app/views/shared", "app/views/shared/_header_navbar.html.erb", "app/views/shared/_volume_select.html.haml", "app/views/shared/_reqoptions.html.haml", "app/views/shared/_reqpu.html.haml", "app/views/shared/_hold_options.html.haml", "app/views/shared/_request_options.html.haml", "app/views/shared/_reqco.html.haml", "app/views/shared/_recall_options.html.haml", "app/views/shared/_reqac.html.haml", "app/views/shared/_footer.html.erb", "app/views/shared/_request_date.html.haml", "config/locales", "config/locales/requests.en.yml", "config/environment.rb", "config/routes.rb", "db/migrate", "db/migrate/20130430193240_create_blacklight_cornell_requests_requests.rb", "lib/blacklight_cornell_requests", "lib/blacklight_cornell_requests/borrow_direct.rb", "lib/blacklight_cornell_requests/version.rb", "lib/blacklight_cornell_requests/voyager_request.rb", "lib/blacklight_cornell_requests/engine.rb", "lib/blacklight_cornell_requests/cornell.rb", "lib/blacklight_cornell_requests.rb", "lib/tasks", "lib/tasks/blacklight_cornell_requests_tasks.rake", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.homepage = "http://search.library.cornell.edu"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.24"
  s.summary = "Given a bibid, provide user with the best delivery option and all other available options."

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rails>, ["~> 3.2.13"])
      s.add_runtime_dependency(%q<haml>, [">= 3.0.0"])
      s.add_runtime_dependency(%q<haml-rails>, [">= 0"])
      s.add_runtime_dependency(%q<httpclient>, [">= 0"])
      s.add_runtime_dependency(%q<net-ldap>, [">= 0"])
      s.add_runtime_dependency(%q<blacklight>, [">= 0"])
      s.add_runtime_dependency(%q<i18n>, [">= 0"])
      s.add_development_dependency(%q<sqlite3>, [">= 0"])
      s.add_development_dependency(%q<rspec-rails>, ["~> 2.5"])
      s.add_development_dependency(%q<capybara>, ["~> 0.4"])
      s.add_development_dependency(%q<guard-spork>, [">= 0"])
      s.add_development_dependency(%q<guard-rspec>, [">= 0"])
      s.add_development_dependency(%q<spork>, [">= 0"])
      s.add_development_dependency(%q<webmock>, [">= 0"])
      s.add_development_dependency(%q<vcr>, [">= 0"])
      s.add_development_dependency(%q<factory_girl_rails>, [">= 0"])
    else
      s.add_dependency(%q<rails>, ["~> 3.2.13"])
      s.add_dependency(%q<haml>, [">= 3.0.0"])
      s.add_dependency(%q<haml-rails>, [">= 0"])
      s.add_dependency(%q<httpclient>, [">= 0"])
      s.add_dependency(%q<net-ldap>, [">= 0"])
      s.add_dependency(%q<blacklight>, [">= 0"])
      s.add_dependency(%q<i18n>, [">= 0"])
      s.add_dependency(%q<sqlite3>, [">= 0"])
      s.add_dependency(%q<rspec-rails>, ["~> 2.5"])
      s.add_dependency(%q<capybara>, ["~> 0.4"])
      s.add_dependency(%q<guard-spork>, [">= 0"])
      s.add_dependency(%q<guard-rspec>, [">= 0"])
      s.add_dependency(%q<spork>, [">= 0"])
      s.add_dependency(%q<webmock>, [">= 0"])
      s.add_dependency(%q<vcr>, [">= 0"])
      s.add_dependency(%q<factory_girl_rails>, [">= 0"])
    end
  else
    s.add_dependency(%q<rails>, ["~> 3.2.13"])
    s.add_dependency(%q<haml>, [">= 3.0.0"])
    s.add_dependency(%q<haml-rails>, [">= 0"])
    s.add_dependency(%q<httpclient>, [">= 0"])
    s.add_dependency(%q<net-ldap>, [">= 0"])
    s.add_dependency(%q<blacklight>, [">= 0"])
    s.add_dependency(%q<i18n>, [">= 0"])
    s.add_dependency(%q<sqlite3>, [">= 0"])
    s.add_dependency(%q<rspec-rails>, ["~> 2.5"])
    s.add_dependency(%q<capybara>, ["~> 0.4"])
    s.add_dependency(%q<guard-spork>, [">= 0"])
    s.add_dependency(%q<guard-rspec>, [">= 0"])
    s.add_dependency(%q<spork>, [">= 0"])
    s.add_dependency(%q<webmock>, [">= 0"])
    s.add_dependency(%q<vcr>, [">= 0"])
    s.add_dependency(%q<factory_girl_rails>, [">= 0"])
  end
end
