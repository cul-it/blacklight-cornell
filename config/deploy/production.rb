#server "da-prod-web1.library.cornell.edu", "da-prod-web2.library.cornell.edu", :app, :web, :db, :primary => true
role :app, "search1.library.cornell.edu"
role :web, "search1.library.cornell.edu"
role :db, "search1.library.cornell.edu", :primary => true

role :app, "search2.library.cornell.edu"
role :web, "search2.library.cornell.edu"
role :db, "search2.library.cornell.edu", :primary => true

set :deploy_to, "/libweb/#{user}/blacklight-cornell"
set :branch, "hotfix-publicbeta"
