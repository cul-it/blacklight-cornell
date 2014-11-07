#server "#{user}-dev.library.cornell.edu", :app, :web, :db, :primary => true
role :app, ENV['DEPLOY_TARGET'] 
role :web,  ENV['DEPLOY_TARGET']
role :db,   ENV['DEPLOY_TARGET'], :primary => true

set :deploy_to, "/cul/web/#{ENV['DEPLOY_TARGET']}/htdocs/rails//blacklight-cornell"
# this is set by jenkins, otherwise you can set it.
set :branch, ENV['GIT_BRANCH']
set :bundle_flags,    "--local "
