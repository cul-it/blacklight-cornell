set :application, "blacklight-cornell"
set :repository,  "git@git.library.cornell.edu:/blacklight-cornell"
set :scm, :git
set :user, "jac244"
set :default_environment, {
  'PATH' => "/users/#{user}/.rvm/gems/ruby-1.9.3-p194/bin:/users/#{user}/.rvm/gems/ruby-1.9.3-p194/bin/rake:/users/#{user}/.rvm/bin:/users/#{user}/.rvm/bin:$PATH",
  'RUBY_VERSION' => "ruby 1.9.3-p194",
  'GEM_HOME'     => "/users/#{user}/.rvm/gems/ruby-1.9.3-p194/gems",
  'GEM_PATH'     => "/users/#{user}/.rvm/gems/ruby-1.9.3-p194",
  'BUNDLE_PATH'  => "/users/#{user}/.rvm/gems/ruby-1.9.3-p194/bundler"  # If you are using bundler.
}
require 'bundler/capistrano'
require 'capistrano/ext/multistage'
set :stages, ["staging", "production"]
set :default_stage, "staging"
default_run_options[:pty] = true
# If you are using Passenger mod_rails uncomment this:
# namespace :deploy do
#   task :start do ; end
#   task :stop do ; end
#   task :restart, :roles => :app, :except => { :no_release => true } do
#     run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
#   end
# end
