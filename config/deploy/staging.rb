#server "#{user}-dev.library.cornell.edu", :app, :web, :db, :primary => true
#server "da-prod-web1.library.cornell.edu", "da-prod-web2.library.cornell.edu", :app, :web, :db, :primary => true
role :app, "da-prod-web2.library.cornell.edu","da-prod-web1.library.cornell.edu"
role :web,"da-prod-web2.library.cornell.edu","da-prod-web1.library.cornell.edu" 
role :db, "da-prod-web1.library.cornell.edu", :primary => true

role :db, "da-prod-web2.library.cornell.edu"

set :deploy_to, "/users/#{user}/blacklight-cornell-staging"
set :branch, "cap-deploy"
