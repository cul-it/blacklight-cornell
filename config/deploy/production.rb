#server "da-prod-web1.library.cornell.edu", "da-prod-web2.library.cornell.edu", :app, :web, :db, :primary => true
role :app, "newcatalog1.library.cornell.edu"
role :web, "newcatalog1.library.cornell.edu"
role :db, "newcatalog1.library.cornell.edu", :primary => true

role :app, "newcatalog2.library.cornell.edu"
role :web, "newcatalog2.library.cornell.edu"
role :db, "newcatalog2.library.cornell.edu", :primary => true

role :app, "newcatalog3.library.cornell.edu"
role :web, "newcatalog3.library.cornell.edu"
role :db, "newcatalog3.library.cornell.edu", :primary => true

set :deploy_to, "/libweb/#{user}/blacklight-cornell"
#this avoids an error message from git, but i don't think it's really necessary.
#as i don't think the message actually affects what gets installed.
set :branch, ENV['GIT_BRANCH'].gsub("origin/","")
