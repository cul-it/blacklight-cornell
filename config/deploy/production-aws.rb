
server 'newcatalog8.library.cornell.edu', :app, :web, :db, primary: true, user: 'jenkins' 
server 'newcatalog9.library.cornell.edu', :app, :web, :db, primary: true, user: 'jenkins' 
server 'newcatalog0.library.cornell.edu', :app, :web, :db, primary: true, user: 'jenkins' 

set :deploy_to, "/cul/web/newcatalog-aws.library.cornell.edu/rails-app"
#this avoids an error message from git, but i don't think it's really necessary.
#as i don't think the message actually affects what gets installed.
set :branch, ENV['GIT_BRANCH'].gsub("origin/","")
task :install_env, :roles => [ :app, :db, :web ] do
  run "cp #{deploy_to}/../conf/production.env  #{shared_path}/.env"
end
