set :stage, :integration

server 'aws-108-077.internal.library.cornell.edu', roles: %w{app web db}, user: "jenkins"

set :deploy_to, "/cul/web/catalog-int.library.cornell.edu/rails-app"

set :branch, ENV['BRANCH'].gsub("origin/","") if ENV['BRANCH']

set :rails_env, 'integration'

# ==============================================================================
# Force Nokogiri to build from source instead of using precompiled binaries
# ------------------------------------------------------------------------------
before 'bundler:install', 'deploy:set_force_ruby_platform'

namespace :deploy do
  task :set_force_ruby_platform do
    on roles(:app) do
      info "👉 Setting Bundler to force Ruby platform on #{host.hostname}..."
      execute :bundle, "config set force_ruby_platform true"
      info "✅ Bundler config force_ruby_platform set successfully."
    end
  end
end
