role :app, "newcatalog-int.library.cornell.edu"
role :web, "newcatalog-int.library.cornell.edu" 
role :db,  "newcatalog-int.library.cornell.edu", :primary => true

set :deploy_to, "/cul/web/newcatalog-int.library.cornell.edu/rails-app"
#set :deploy_to, "/libweb/#{user}/blacklight-cornell"
#set :deploy_to, "/users/#{user}/blacklight-cornell-development"
# actually this is a tag
#set :branch, "staging-publicbeta-0.2"
# this is set by jenkins, otherwise you can set it.
set :branch, ENV['GIT_BRANCH'].gsub("origin/","")
#set :bundle_flags,    ""

set :rails_env, 'integration'

desc "Install  (redefine for integration) env -- too sensitive for git - production"
task :install_env, :roles => [ :app, :db, :web ] do
         run "cp #{deploy_to}/../conf/latest-integration.env  #{shared_path}/.env"
         run "cat #{shared_path}/.env"
 end
