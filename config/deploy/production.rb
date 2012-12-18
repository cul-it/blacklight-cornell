server "#{user}-dev.library.cornell.edu", :app, :web, :primary => true
set :deploy_to, "/users/#{user}/blacklight-cornell-production"
set :branch, "dev"
