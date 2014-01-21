#server "#{user}-dev.library.cornell.edu", :app, :web, :db, :primary => true
#server "da-prod-web1.library.cornell.edu", "da-prod-web2.library.cornell.edu", :app, :web, :db, :primary => true
role :app, "newcatalog-stg.library.cornell.edu"
role :web, "newcatalog-stg.library.cornell.edu" 
role :db,  "newcatalog-stg.library.cornell.edu", :primary => true

set :deploy_to, "/libweb/#{user}/blacklight-cornell"
#set :deploy_to, "/users/#{user}/blacklight-cornell"
# actually this is a tag
#set :branch, "staging-publicbeta-0.2"
# this is set by jenkins, otherwise you can set it.
# cap says you cannot deploy from remote branch.
set :branch, ENV['GIT_BRANCH'].gsub("origin/","")
