server 'aws-108-114.internal.library.cornell.edu',  :app, :web, :db, :primary => true, user: 'jenkins' 
# Seems like this server is no longer in play?
#server 'aws-108-199.internal.library.cornell.edu',  :app, :web, :db, :primary => true, user: 'jenkins' 
# deploy second server in cluster

#server "da-prod-web1.library.cornell.edu", "da-prod-web2.library.cornell.edu", :app, :web, :db, :primary => true
#role :app, "aws-108-114.internal.library.cornell.edu"
#role :web, "aws-108-114.internal.library.cornell.edu"
#role :db, "aws-108-114.internal.library.cornell.edu", :primary => true

#role :app, "newcatalog8.library.cornell.edu"
#role :web, "newcatalog8.library.cornell.edu"
#role :db, "newcatalog8.library.cornell.edu", :primary => true

#role :app, "newcatalog9.library.cornell.edu"
#role :web, "newcatalog9.library.cornell.edu"
#role :db, "newcatalog9.library.cornell.edu", :primary => true

set :deploy_to, "/cul/web/ld4p3-web.library.cornell.edu/rails-app"
set :rails_env, 'development'
set :repository,  "git@github.com:LD4P/blacklight-cornell"
set :branch, ENV['GIT_BRANCH'].gsub("origin/","")
task :install_env, :roles => [ :app, :db, :web ] do
  run "cp #{deploy_to}/../conf/latest-integration.env  #{shared_path}/.env"
  run "cat #{shared_path}/.env"
end
