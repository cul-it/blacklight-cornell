$LOAD_PATH.unshift File.join(File.dirname(__FILE__), 'deploy')
require "dotenv/deployment/capistrano"
set :application, "blacklight-cornell"
set :repository,  "git@github.com:/cul-it/blacklight-cornell"
set :use_sudo, false
set :scm, :git
set :scm_verbose, true
# todo: set user to jenkins
set :user, "jenkins"
set :default_environment, {
  'PATH' => "/usr/local/rvm/gems/ruby-2.6.4/bin:/usr/local/rvm/gems/ruby-2.6.4@global/bin:/usr/local/rvm/rubies/ruby-2.6.4/bin:/usr/local/rvm/bin:/opt/rh/devtoolset-10/root/usr/bin:$PATH",
  'RUBY_VERSION' => "ruby-2.6.4",
  'GEM_HOME'     => "/usr/local/rvm/gems/ruby-2.6.4",
  'GEM_PATH'     => "/usr/local/rvm/gems/ruby-2.6.4:/usr/local/rvm/gems/ruby-2.6.4@global",
  'BUNDLE_PATH'  => "/usr/local/rvm/gems/ruby-2.6.4/gems/bundler-2.3.9/exe/bundle"  # If you are using bundler.
#  'BUNDLE_PATH'  => "/usr/local/rvm/bin/bundle"  # If you are using bundler.
}

set :deploy_via, :copy
set :bundle_flags,    "--deployment "

require 'bundler/capistrano'
require 'capistrano/ext/multistage'

set :stages, ["integration","development","integration-aws","integration-ld4p3","staging", "production","production-new","production-aws"]
set :default_stage, "staging"
default_run_options[:pty] = true

task :cold do
  transaction do
    update
    setup_db  #replacing migrate in original
    start
  end
end

# This could be useful in provisioning future deployments
task :setup_db, :roles => :app do
  raise RuntimeError.new('db:setup aborted!') unless Capistrano::CLI.ui.ask("About to `rake db:setup`. Are you sure to wipe the entire database (anything other than 'yes' aborts):") == 'yes'
  run "cd #{current_path}; bundle exec rake db:setup RAILS_ENV=#{rails_env}"
end

task :reqmigrate, :roles => :db  do
    rake = fetch(:rake, "rake")
    rails_env = fetch(:rails_env, "production")
    migrate_env = fetch(:migrate_env, "")
    migrate_target = fetch(:migrate_target, :latest)

    directory = case migrate_target.to_sym
      when :current then current_path
      when :latest  then latest_release
      else raise ArgumentError, "unknown migration target #{migrate_target.inspect}"
      end

    run "cd #{directory} && #{rake} RAILS_ENV=#{rails_env} #{migrate_env} blacklight_cornell_requests:install:migrations"
end

task :allmigrate, :roles => :db  do
    rake = fetch(:rake, "rake")
    rails_env = fetch(:rails_env, "production")
    migrate_env = fetch(:migrate_env, "")
    migrate_target = fetch(:migrate_target, :latest)

    directory = case migrate_target.to_sym
      when :current then current_path
      when :latest  then latest_release
      else raise ArgumentError, "unknown migration target #{migrate_target.inspect}"
      end

    run "cd #{directory} && #{rake} RAILS_ENV=#{rails_env} #{migrate_env} db:migrate"
end

namespace :deploy do
    namespace :db do
    # this no longer seems to be happening
       desc <<-DESC
        [internal] Updates the symlink for database.yml file to the just deployed release.
       DESC
       task :symlink, :except => { :no_release => true } do
        run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
       end
    end
end

# this also no longer seems to be happening
#after "deploy:finalize_update", "deploy:db:symlink"
desc "Tailor solr config to local machine"
task :tailor_solr_yml, :roles => [ :web ] do
	run "sed -e s/da-prod-solr1.library.cornell.edu/$CAPISTRANO:HOST$/ #{deploy_to}/current/config/solr.yml >/tmp/slr.rb && sed -e s,//newcatalog,//da-prod-solr, /tmp/slr.rb  >#{deploy_to}/current/config/solr.yml"
        run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
end

desc "Guarantee app signal environment -- too sensitive for git"
task :export_app_yml, :roles => [ :app, :db, :web ] do
         rails_env = fetch(:rails_env, "production")
         #run "cd  #{deploy_to}/current/ ; pwd ; export `grep APPSIGNAL_PUSH_API_KEY  .env`  ; echo $APPSIGNAL_PUSH_API_KEY ; bundle exec bin/appsignal notify_of_deploy --user=jenkins  --revision=#{ENV['GIT_COMMIT']} --environment=#{stage} --name=BlacklightCornell "
	run "cd  #{current_path} ; pwd ; export `grep APPSIGNAL_PUSH_API_KEY  .env`  ; erb config/appsignal.yml > a ; mv a config/appsignal.yml;  cat config/appsignal.yml ;  echo $APPSIGNAL_PUSH_API_KEY ; bundle exec appsignal notify_of_deploy --user=jenkins  --revision=#{ENV['GIT_COMMIT']} --environment=#{stage} --name=BlacklightCornell "
end

after :deploy, "tailor_solr_yml"
before 'appsignal:deploy', "export_app_yml"
desc "Install  env -- too sensitive for git - production"
task :install_env, :roles => [ :app, :db, :web ] do
        run "cp #{deploy_to}/config/.env  #{shared_path}/.env"
        run "cat #{shared_path}/.env"
end

after "deploy:setup", "install_env"
# If you are using Passenger mod_rails uncomment this:
# namespace :deploy do
#   task :start do ; end
#   task :stop do ; end
#   task :restart, :roles => :app, :except => { :no_release => true } do
#     run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
#   end
# end

require 'appsignal/capistrano'
