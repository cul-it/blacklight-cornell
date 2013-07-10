#server "da-prod-web1.library.cornell.edu", "da-prod-web2.library.cornell.edu", :app, :web, :db, :primary => true
role :app, "da-prod-web1.library.cornell.edu"
role :web, "da-prod-web1.library.cornell.edu"
role :db, "da-prod-web1.library.cornell.edu", :primary => true

role :app, "da-prod-web2.library.cornell.edu"
role :web, "da-prod-web2.library.cornell.edu"
role :db, "da-prod-web2.library.cornell.edu", :primary => true

set :deploy_to, "/libweb/#{user}/blacklight-cornell"
set :branch, "hotfix-publicbeta"
