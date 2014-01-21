#server "#{user}-dev.library.cornell.edu", :app, :web, :db, :primary => true
#server "da-prod-web1.library.cornell.edu", "da-prod-web2.library.cornell.edu", :app, :web, :db, :primary => true
role :app, "newcatalog-dev.library.cornell.edu"
role :web, "newcatalog-dev.library.cornell.edu" 
role :db,  "newcatalog-dev.library.cornell.edu", :primary => true

set :deploy_to, "/culsearch/#{user}/blacklight-cornell"
#set :deploy_to, "/libweb/#{user}/blacklight-cornell"
#set :deploy_to, "/users/#{user}/blacklight-cornell-development"
# actually this is a tag
#set :branch, "staging-publicbeta-0.2"
# this is set by jenkins, otherwise you can set it.
#set :branch, ENV['GIT_BRANCH']
set :branch,"dev"
set :bundle_flags,    "--local "
