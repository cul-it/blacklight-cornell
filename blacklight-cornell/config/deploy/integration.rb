set :stage, :integration

server 'aws-108-077.internal.library.cornell.edu', roles: %w{app web db}, user: "jenkins"

set :deploy_to, "/cul/web/catalog-int.library.cornell.edu/rails-app"

set :branch, ENV['BRANCH'].gsub("origin/", "") if ENV['BRANCH']

set :rails_env, 'integration'

# ==============================================================================
# Uninstall any precompiled nokogiri binary and reinstall from source manually
# ------------------------------------------------------------------------------
namespace :deploy do
  task :uninstall_and_reinstall_nokogiri do
    on roles(:app) do
      within release_path do
        # Uninstall all versions and ignore failure if none is present
        execute 'gem uninstall nokogiri -a -x -I || true'

        # Reinstall Nokogiri from source, pinned to specific version
        execute 'gem install nokogiri -v 1.16.8 --platform=ruby -- --use-system-libraries'
      end
    end
  end

  # Run this right before asset precompilation
  before 'deploy:assets:precompile', 'deploy:uninstall_and_reinstall_nokogiri'
end
