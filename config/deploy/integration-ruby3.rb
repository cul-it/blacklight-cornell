set :stage, :integration

server 'jenkins@aws-108-239.internal.library.cornell.edu', roles: %w{app web db}, primary: true, user: 'jenkins' 

set :deploy_to, "/cul/web/newcatalog-int.library.cornell.edu/rails-app"

set :branch, ENV['BRANCH'].gsub("origin/","") if ENV['BRANCH']

set :rails_env, 'integration'

#task :install_env, :roles => [ :app, :db, :web ] do
#  run "cp #{deploy_to}/../conf/latest-integration.env  #{shared_path}/.env"
#  run "cat #{shared_path}/.env"
#end
