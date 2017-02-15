#server "#{user}-dev.library.cornell.edu", :app, :web, :db, :primary => true
#server "da-prod-web1.library.cornell.edu", "da-prod-web2.library.cornell.edu", :app, :web, :db, :primary => true
role :app, "newcatalog-stg.library.cornell.edu"
role :web, "newcatalog-stg.library.cornell.edu" 
role :db,  "newcatalog-stg.library.cornell.edu", :primary => true

set :deploy_to, "/cul/web/newcatalog-stg.library.cornell.edu/rails-app"	
#set :deploy_to, "/users/#{user}/blacklight-cornell"
# actually this is a tag
#set :branch, "staging-publicbeta-0.2"
# this is set by jenkins, otherwise you can set it.
# cap says you cannot deploy from remote branch.
set :branch, ENV['GIT_BRANCH'].gsub("origin/","")

desc "Tailor solr config to local machine"
task :tailor_solr_yml, :roles => [ :web ] do
        run "sed -e 's/stg/prod/g'   #{deploy_to}/current/config/solr.yml >/tmp/slr.rb && sed -e s,//newcatalog,//da-prod-solr, /tmp/slr.rb  >#{deploy_to}/current/config/solr.yml"
        run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
end

desc "Install  (redefine for staging) env -- too sensitive for git - production"
task :install_env, :roles => [ :app, :db, :web ] do
        run "cp #{deploy_to}/../conf/latest-staging.env  #{shared_path}/.env"
        run "cat #{shared_path}/.env"
end

