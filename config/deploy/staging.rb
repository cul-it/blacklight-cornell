#server "#{user}-dev.library.cornell.edu", :app, :web, :db, :primary => true
#server "da-prod-web1.library.cornell.edu", "da-prod-web2.library.cornell.edu", :app, :web, :db, :primary => true
role :app, "da-stg-web.library.cornell.edu"
role :web, "da-stg-web.library.cornell.edu" 
role :db,  "da-stg-web.library.cornell.edu", :primary => true

set :deploy_to, "/libweb/#{user}/blacklight-cornell"
set :branch, "hotfix-publicbeta"
