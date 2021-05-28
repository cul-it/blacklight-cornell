server 'newcatalog-int.library.cornell.edu', :app, :web, :db, primary: true, user: 'jenkins' 

set :deploy_to, "/cul/web/newcatalog-folio-int.library.cornell.edu/rails-app"
#this avoids an error message from git, but i don't think it's really necessary.
#as i don't think the message actually affects what gets installed.
#set :branch, ENV['GIT_BRANCH'].gsub("origin/","")
set :rails_env, 'integration'
task :install_env, :roles => [ :app, :db, :web ] do
  run "cp #{deploy_to}/../conf/latest-integration.env  #{shared_path}/.env"
  run "cat #{shared_path}/.env"
end
