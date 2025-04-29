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
        # Remove broken nokogiri from shared bundle
        execute :rm, '-rf', "#{shared_path}/bundle/ruby/3.2.0/gems/nokogiri-*"

        # Uninstall all versions and ignore failure if none is present
        execute 'gem uninstall nokogiri -a -x -I || true'

        # Force bundler to build nokogiri from source using system libraries
        execute :bundle, 'config set --local force_ruby_platform true'
        execute :bundle, 'config set build.nokogiri --use-system-libraries'

        # Reinstall nokogiri respecting the configs above
        execute 'gem install nokogiri --platform=ruby -- --use-system-libraries'
      end
    end
  end

  # ==============================================================================
  # Re-run bundler without deployment mode to allow re-resolution of nokogiri
  # ------------------------------------------------------------------------------
  task :rebundle_with_fixed_nokogiri do
    on roles(:app) do
      within release_path do
        execute :bundle, 'install --path vendor/bundle --without development test'
      end
    end
  end

  # Hook both tasks before assets precompile
  before 'deploy:assets:precompile', 'deploy:uninstall_and_reinstall_nokogiri'
  before 'deploy:assets:precompile', 'deploy:rebundle_with_fixed_nokogiri'
end
