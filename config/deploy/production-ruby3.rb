set :stage, :production

server 'aws-108-028.internal.library.cornell.edu', roles: %w{app web db}, primary: true, user: "jenkins"
server 'aws-108-075.internal.library.cornell.edu', roles: %w{app web db}, primary: true, user: "jenkins"
server 'aws-108-045.internal.library.cornell.edu', roles: %w{app web db}, primary: true, user: "jenkins"

set :migration_role, :db
set :migration_servers, -> { release_roles(fetch(:migration_role)) }

set :deploy_to, "/cul/web/newcatalog.library.cornell.edu/rails-app"

set :branch, ENV['BRANCH'].gsub("origin/","") if ENV['BRANCH']

set :rails_env, 'production'

#task :install_env, :roles => [ :app, :db, :web ] do
#  run "cp #{deploy_to}/../conf/latest-integration.env  #{shared_path}/.env"
#  run "cat #{shared_path}/.env"
#end
