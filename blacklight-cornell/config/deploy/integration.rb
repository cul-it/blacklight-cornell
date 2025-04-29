set :stage, :integration

server 'aws-108-077.internal.library.cornell.edu', roles: %w{app web db}, user: "jenkins"

set :deploy_to, "/cul/web/catalog-int.library.cornell.edu/rails-app"

set :branch, ENV['BRANCH'].gsub("origin/","") if ENV['BRANCH']

set :rails_env, 'integration'

# ==============================================================================
# Force Nokogiri and other gems to build from source instead of using binaries
# and limit make parallelism to avoid "Argument list too long" errors
# ------------------------------------------------------------------------------
before 'bundler:install', 'deploy:set_force_ruby_platform'
before 'bundler:install', 'deploy:set_makeflags_serial'

namespace :deploy do
  task :set_force_ruby_platform do
    on roles(:app) do
      info "👉 Setting Bundler to force Ruby platform on #{host.hostname}..."
      execute :bundle, "config set force_ruby_platform true"
      info "✅ Bundler config force_ruby_platform set successfully."
    end
  end

  task :set_makeflags_serial do
    on roles(:app) do
      info "👉 Setting MAKEFLAGS=-j1 to prevent make overflow on #{host.hostname}..."
      execute "echo 'export MAKEFLAGS=-j1' >> ~/.bash_profile"
      execute "source ~/.bash_profile"
      info "✅ MAKEFLAGS environment variable set successfully."
    end
  end
end
