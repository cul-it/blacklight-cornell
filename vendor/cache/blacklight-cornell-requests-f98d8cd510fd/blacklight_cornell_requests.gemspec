# -*- encoding: utf-8 -*-
# stub: blacklight_cornell_requests 1.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "blacklight_cornell_requests"
  s.version = "1.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Shinwoo Kim", "Matt Connolly"]
  s.date = "2015-03-24"
  s.description = "Given a bibid, provide user with the best delivery option and all other available options."
  s.email = ["cul-da-developers-l@list.cornell.edu"]
  s.files = ["MIT-LICENSE", "README.rdoc", "Rakefile", "app/assets", "app/assets/images", "app/assets/images/blacklight_cornell_requests", "app/assets/javascripts", "app/assets/javascripts/blacklight_cornell_requests", "app/assets/javascripts/blacklight_cornell_requests.js", "app/assets/javascripts/blacklight_cornell_requests/requests.js.coffee", "app/assets/stylesheets", "app/assets/stylesheets/blacklight_cornell_requests", "app/assets/stylesheets/blacklight_cornell_requests/application.css", "app/assets/stylesheets/blacklight_cornell_requests/request.css", "app/controllers", "app/controllers/blacklight_cornell_requests", "app/controllers/blacklight_cornell_requests/application_controller.rb", "app/controllers/blacklight_cornell_requests/request_controller.rb", "app/helpers", "app/helpers/blacklight_cornell_requests", "app/helpers/blacklight_cornell_requests/application_helper.rb", "app/helpers/blacklight_cornell_requests/request_helper.rb", "app/models", "app/models/blacklight_cornell_requests", "app/models/blacklight_cornell_requests/circ_policy_locs.rb", "app/models/blacklight_cornell_requests/request.rb", "app/models/blacklight_cornell_requests/request_mailer.rb", "app/views", "app/views/blacklight_cornell_requests", "app/views/blacklight_cornell_requests/request", "app/views/blacklight_cornell_requests/request/ask.html.haml", "app/views/blacklight_cornell_requests/request/bd.html.haml", "app/views/blacklight_cornell_requests/request/circ.html.haml", "app/views/blacklight_cornell_requests/request/document_delivery.html.haml", "app/views/blacklight_cornell_requests/request/hold.html.haml", "app/views/blacklight_cornell_requests/request/ill.html.haml", "app/views/blacklight_cornell_requests/request/l2l.html.haml", "app/views/blacklight_cornell_requests/request/pda.html.haml", "app/views/blacklight_cornell_requests/request/purchase.html.haml", "app/views/blacklight_cornell_requests/request/recall.html.haml", "app/views/blacklight_cornell_requests/request_mailer", "app/views/blacklight_cornell_requests/request_mailer/email_request.html.erb", "app/views/shared", "app/views/shared/_back_to_item.html.haml", "app/views/shared/_hold_options.html.haml", "app/views/shared/_l2lac.html.haml", "app/views/shared/_recall_options.html.haml", "app/views/shared/_reqac.html.haml", "app/views/shared/_reqpu.html.haml", "app/views/shared/_request_date.html.haml", "app/views/shared/_request_options.html.haml", "app/views/shared/_volume_select.html.haml", "config/environment.rb", "config/locales", "config/locales/requests.en.yml", "config/routes.rb", "db/migrate", "db/migrate/20140430193241_cond_create_blacklight_cornell_requests_requests.rb", "db/migrate/20141205183449_cond_create_blacklight_cornell_requests_circ_policy_locs.rb", "db/migrate/20141205183450_add_new_delivery_location.rb", "lib/blacklight_cornell_requests", "lib/blacklight_cornell_requests.rb", "lib/blacklight_cornell_requests/borrow_direct.rb", "lib/blacklight_cornell_requests/cornell.rb", "lib/blacklight_cornell_requests/engine.rb", "lib/blacklight_cornell_requests/version.rb", "lib/blacklight_cornell_requests/voyager_request.rb", "lib/james_monkeys.rb", "lib/tasks", "lib/tasks/blacklight_cornell_requests_tasks.rake"]
  s.homepage = "http://search.library.cornell.edu"
  s.rubygems_version = "2.2.2"
  s.summary = "Given a bibid, provide user with the best delivery option and all other available options."

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rails>, ["~> 4.0"])
      s.add_runtime_dependency(%q<protected_attributes>, [">= 0"])
      s.add_runtime_dependency(%q<haml>, [">= 3.0.0"])
      s.add_runtime_dependency(%q<haml-rails>, [">= 0"])
      s.add_runtime_dependency(%q<httpclient>, [">= 0"])
      s.add_runtime_dependency(%q<net-ldap>, [">= 0"])
      s.add_runtime_dependency(%q<blacklight>, ["~> 4.3"])
      s.add_runtime_dependency(%q<i18n>, [">= 0"])
      s.add_runtime_dependency(%q<nokogiri>, [">= 0"])
      s.add_runtime_dependency(%q<zoom>, [">= 0"])
      s.add_runtime_dependency(%q<dotenv>, [">= 0"])
      s.add_runtime_dependency(%q<dotenv-rails>, [">= 0"])
      s.add_runtime_dependency(%q<dotenv-deployment>, [">= 0"])
      s.add_runtime_dependency(%q<borrow_direct>, [">= 0"])
      s.add_development_dependency(%q<sqlite3>, [">= 0"])
      s.add_development_dependency(%q<rspec-rails>, ["~> 2.5"])
      s.add_development_dependency(%q<capybara>, ["= 2.4.1"])
      s.add_development_dependency(%q<guard-spork>, [">= 0"])
      s.add_development_dependency(%q<guard-rspec>, [">= 0"])
      s.add_development_dependency(%q<spork>, [">= 0"])
      s.add_development_dependency(%q<webmock>, [">= 0"])
      s.add_development_dependency(%q<vcr>, [">= 0"])
      s.add_development_dependency(%q<factory_girl_rails>, [">= 0"])
    else
      s.add_dependency(%q<rails>, ["~> 4.0"])
      s.add_dependency(%q<protected_attributes>, [">= 0"])
      s.add_dependency(%q<haml>, [">= 3.0.0"])
      s.add_dependency(%q<haml-rails>, [">= 0"])
      s.add_dependency(%q<httpclient>, [">= 0"])
      s.add_dependency(%q<net-ldap>, [">= 0"])
      s.add_dependency(%q<blacklight>, ["~> 4.3"])
      s.add_dependency(%q<i18n>, [">= 0"])
      s.add_dependency(%q<nokogiri>, [">= 0"])
      s.add_dependency(%q<zoom>, [">= 0"])
      s.add_dependency(%q<dotenv>, [">= 0"])
      s.add_dependency(%q<dotenv-rails>, [">= 0"])
      s.add_dependency(%q<dotenv-deployment>, [">= 0"])
      s.add_dependency(%q<borrow_direct>, [">= 0"])
      s.add_dependency(%q<sqlite3>, [">= 0"])
      s.add_dependency(%q<rspec-rails>, ["~> 2.5"])
      s.add_dependency(%q<capybara>, ["= 2.4.1"])
      s.add_dependency(%q<guard-spork>, [">= 0"])
      s.add_dependency(%q<guard-rspec>, [">= 0"])
      s.add_dependency(%q<spork>, [">= 0"])
      s.add_dependency(%q<webmock>, [">= 0"])
      s.add_dependency(%q<vcr>, [">= 0"])
      s.add_dependency(%q<factory_girl_rails>, [">= 0"])
    end
  else
    s.add_dependency(%q<rails>, ["~> 4.0"])
    s.add_dependency(%q<protected_attributes>, [">= 0"])
    s.add_dependency(%q<haml>, [">= 3.0.0"])
    s.add_dependency(%q<haml-rails>, [">= 0"])
    s.add_dependency(%q<httpclient>, [">= 0"])
    s.add_dependency(%q<net-ldap>, [">= 0"])
    s.add_dependency(%q<blacklight>, ["~> 4.3"])
    s.add_dependency(%q<i18n>, [">= 0"])
    s.add_dependency(%q<nokogiri>, [">= 0"])
    s.add_dependency(%q<zoom>, [">= 0"])
    s.add_dependency(%q<dotenv>, [">= 0"])
    s.add_dependency(%q<dotenv-rails>, [">= 0"])
    s.add_dependency(%q<dotenv-deployment>, [">= 0"])
    s.add_dependency(%q<borrow_direct>, [">= 0"])
    s.add_dependency(%q<sqlite3>, [">= 0"])
    s.add_dependency(%q<rspec-rails>, ["~> 2.5"])
    s.add_dependency(%q<capybara>, ["= 2.4.1"])
    s.add_dependency(%q<guard-spork>, [">= 0"])
    s.add_dependency(%q<guard-rspec>, [">= 0"])
    s.add_dependency(%q<spork>, [">= 0"])
    s.add_dependency(%q<webmock>, [">= 0"])
    s.add_dependency(%q<vcr>, [">= 0"])
    s.add_dependency(%q<factory_girl_rails>, [">= 0"])
  end
end
