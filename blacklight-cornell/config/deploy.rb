# config valid for current version and patch releases of Capistrano
lock "~> 3.19.1"

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), "deploy")
#require "dotenv/deployment/capistrano"
set :application, "blacklight-cornell"
set :repo_url, "git@github.com:cul-it/blacklight-cornell"

#deploy subdirectory
set :repo_tree, "blacklight-cornell"

set :use_sudo, false
#set :scm, :git
#set :scm_verbose, true
# todo: set user to jenkins
set :user, "jenkins"
set :default_env, {
  "PATH" => "/usr/local/rvm/gems/ruby-3.2.2/bin:/usr/local/rvm/gems/ruby-3.2.2@global/bin:/usr/local/rvm/rubies/ruby-3.2.2/bin:/usr/local/rvm/bin:/opt/rh/devtoolset-10/root/usr/bin:$PATH",
  "RUBY_VERSION" => "ruby-3.2.2",
  "GEM_HOME" => "/usr/local/rvm/gems/ruby-3.2.2",
  "GEM_PATH" => "/usr/local/rvm/gems/ruby-3.2.2:/usr/local/rvm/gems/ruby-3.2.2@global",
#  'BUNDLE_PATH'  => "/usr/local/rvm/gems/ruby-3.2.2/gems/bundler-2.3.9/exe/bundle"  # If you are using bundler.
#  'BUNDLE_PATH'  => "/usr/local/rvm/bin/bundle"  # If you are using bundler.
}

set :rvm_ruby_version, "3.2.2"

# Defaults to :db role
# While migrations looks like a concern of the database layer, Rails migrations are strictly related to the framework.
# Therefore, it's recommended to set the role to :app instead of :db
set :migration_role, :app

# Defaults to the primary :db server
set :migration_servers, -> { primary(fetch(:migration_role)) }

# Defaults to `db:migrate`
set :migration_command, "db:migrate"

# Defaults to false
# Skip migration if files in db/migrate were not modified
set :conditionally_migrate, true

# Defaults to [:web]
set :assets_roles, [:web, :app]

# This should match config.assets.manifest in your rails config/application.rb
set :assets_manifests, ["app/assets/config/manifest.js"]

# RAILS_GROUPS env value for the assets:precompile task. Default to nil.
# set :rails_assets_groups, :assets

# If you need to touch public/images, public/javascripts, and public/stylesheets on each deploy
# set :normalize_asset_timestamps, %w{public/images public/javascripts public/stylesheets}

# Defaults to nil (no asset cleanup is performed)
# If you use Rails 4+ and you'd like to clean up old assets after each deploy,
# set this to the number of versions to keep
# set :keep_assets, 2

append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "vendor/bundle", ".bundle", "public/system", "public/uploads"
append :linked_files, ".env"

before "deploy:updated", :install_env
after "deploy:started", "rvm:check"
#after 'deploy:started', :block_precompile
after "deploy:publishing", "apache:restart_httpd"

Rake::Task["deploy:assets:restore_manifest"].clear_actions
