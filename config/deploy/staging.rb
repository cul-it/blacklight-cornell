#server "#{user}-dev.library.cornell.edu", :app, :web, :db, :primary => true
server "da-stg-web.library.cornell.edu", :app, :web, :db, :primary => true
set :deploy_to, "/users/#{user}/blacklight-cornell-staging"
set :branch, "cap-deploy"
