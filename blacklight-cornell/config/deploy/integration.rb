set :stage, :integration

server 'aws-108-077.internal.library.cornell.edu', roles: %w{app web db}, user: "jenkins"

set :deploy_to, "/cul/web/catalog-int.library.cornell.edu/rails-app"

set :branch, ENV['BRANCH'].gsub("origin/","") if ENV['BRANCH']

set :rails_env, 'integration'

namespace :deploy do
  task :uninstall_and_reinstall_nokogiri do
    on roles(:app) do
      within release_path do
        # Uninstall the existing Nokogiri gem
        execute :gem, 'uninstall nokogiri -a -x -I || true'

        # Install Nokogiri from source with the ruby platform
        execute :gem, 'install nokogiri -v 1.16.8 --platform=ruby'
      end
    end
  end

  # Hook this task into the deploy process (after bundling)
  after 'deploy:updated', 'deploy:uninstall_and_reinstall_nokogiri'
end
