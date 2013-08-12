#server "da-prod-web1.library.cornell.edu", "da-prod-web2.library.cornell.edu", :app, :web, :db, :primary => true
role :app, "search1.library.cornell.edu"
role :web, "search1.library.cornell.edu"
role :db, "search1.library.cornell.edu", :primary => true

role :app, "search2.library.cornell.edu"
role :web, "search2.library.cornell.edu"
role :db, "search2.library.cornell.edu", :primary => true

set :deploy_to, "/libweb/#{user}/blacklight-cornell"
#this avoids an error message from git, but i don't think it's really necessary.
#as i don't think the message actually affects what gets installed.
set :branch, ENV['GIT_BRANCH'].gsub("origin/","")
