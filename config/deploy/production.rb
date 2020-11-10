role :app, "newcatalog4.library.cornell.edu"
role :web, "newcatalog4.library.cornell.edu"
role :db, "newcatalog4.library.cornell.edu", :primary => true

role :app, "newcatalog5.library.cornell.edu"
role :web, "newcatalog5.library.cornell.edu"
role :db, "newcatalog5.library.cornell.edu", :primary => true

role :app, "newcatalog6.library.cornell.edu"
role :web, "newcatalog6.library.cornell.edu"
role :db, "newcatalog6.library.cornell.edu", :primary => true

set :deploy_to, "/cul/web/newcatalog.library.cornell.edu/rails-app"
#this avoids an error message from git, but i don't think it's really necessary.
#as i don't think the message actually affects what gets installed.
set :branch, ENV['GIT_BRANCH'].gsub("origin/","")
task :install_env, :roles => [ :app, :db, :web ] do
  run "cp #{deploy_to}/../conf/production.env  #{shared_path}/.env"
end
