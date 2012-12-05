set :default_environment, {
  'PATH' => "/users/jac244/.rvm/gems/ruby-1.9.3-p194/bin:/user/jac244/.rvm/bin:/users/jac244/.rvm/bin:$PATH",
#  'RUBY_VERSION' => 'ruby 1.9.3-p194',
# 'GEM_HOME'     => '/users/jac244/.rvm/gems/ruby-1.9.3-p194/gems',
#  'GEM_PATH'     => '/users/jac244/.rvm/gems/ruby-1.9.3-p194',
#  'BUNDLE_PATH'  => '/users/jac244/.rvm/gems/ruby-1.9.3-p194/bundler'  # If you are using bundler.
}
require 'bundler/capistrano'
require 'capistrano/ext/multistage'
set :stages, ["staging", "production"]
set :default_stage, "staging"
set :application, "blacklight-cornell"
set :scm, :git
set :repository,  "git@git.library.cornell.edu:/blacklight-cornell.git"
set :branch, fetch(:branch, "deploy")
set :scm_passphrase, ""
set :user, "jac244"
set :db_name, "dna-production"
set :db_user, "dnauser"
set :db_password, "Rails4you"
set :db_allow_hosts, "localhost"
#set :git_shallow_clone, 1
#set :scm_verbose, true

#role :db,  "localhost", :primary => true # This is where Rails migrations will run
#role :db,  "your slave db-server here"

# deploy config

# additional settings
#ssh_options[:keys] = %w(/users/jac244/.ssh/id_rsa)
#ssh_options[:forward_agent] = true

# if you want to clean up old releases on each deploy uncomment this:
# after "deploy:restart", "deploy:cleanup"
#after "deploy", "deploy:migrate"
# if youre still using the script/reaper helper you will need
# these http://github.com/rails/irs_process_scripts

# If you are using Passenger mod_rails uncomment this:
# namespace :deploy do
#   task :start do ; end
#   task :stop do ; end
#   task :restart, :roles => :app, :except => { :no_release => true } do
#     run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
#   end
# end
