server 'newcatalog8.library.cornell.edu', :app, :web, :db, primary: true, user: 'jenkins' 
server 'newcatalog9.library.cornell.edu', :app, :web, :db, primary: true, user: 'jenkins' 
server 'newcatalog0.library.cornell.edu', :app, :web, :db, primary: true, user: 'jenkins' 

# The above may not work. If that fails and migrations can't be run or cap won't let us
# set more than one server as primary, try setting the user separately like so:
# set :user, 'jenkins'
# role :app, "newcatalog8.library.cornell.edu"
# role :web, "newcatalog8.library.cornell.edu"
# role :db, "newcatalog8.library.cornell.edu", :primary => true
# role :app, "newcatalog9.library.cornell.edu"
# role :web, "newcatalog9.library.cornell.edu"
# role :db, "newcatalog9.library.cornell.edu", :primary => true
# role :app, "newcatalog0.library.cornell.edu"
# role :web, "newcatalog0.library.cornell.edu"
# role :db, "newcatalog0.library.cornell.edu", :primary => true
# this shouldn't break current prod because the default user is still rails, and when
# we're ready to abandon on-prem the default can be changed.

set :deploy_to, "/cul/web/newcatalog-aws.library.cornell.edu/rails-app"
set :branch, ENV['GIT_BRANCH'].gsub("origin/","")
task :install_env, :roles => [ :app, :db, :web ] do
  run "cp #{deploy_to}/../conf/production.env  #{shared_path}/.env"
end
