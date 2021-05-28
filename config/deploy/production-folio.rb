server 'newcatalog1.library.cornell.edu', :app, :web, :db, primary: true, user: 'jenkins' 
server 'newcatalog2.library.cornell.edu', :app, :web, :db, primary: true, user: 'jenkins' 
server 'newcatalog3.library.cornell.edu', :app, :web, :db, primary: true, user: 'jenkins' 

set :deploy_to, "/cul/web/newcatalog-folio.library.cornell.edu/rails-app"
set :branch, ENV['GIT_BRANCH'].gsub("origin/","")
task :install_env, :roles => [ :app, :db, :web ] do
  run "cp #{deploy_to}/../conf/production.env  #{shared_path}/.env"
end
