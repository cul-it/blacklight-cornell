role :app, "newcatalog-dev.library.cornell.edu"
role :web, "newcatalog-dev.library.cornell.edu" 
role :db,  "newcatalog-dev.library.cornell.edu", :primary => true

set :deploy_to, "/culsearch/#{user}/blacklight-cornell"
set :branch,"dev"
set :bundle_flags,    "--local "
