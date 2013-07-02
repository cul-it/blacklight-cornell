#server "#{user}-dev.library.cornell.edu", :app, :web, :db, :primary => true
server "da-prod-web1.library.cornell.edu", "da-prod-web2.library.cornell.edu", :app, :web, :db, :primary => true
set :deploy_to, "/users/#{user}/blacklight-cornell-staging"
set :branch, "cap-deploy"
