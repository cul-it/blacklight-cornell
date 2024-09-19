#!/bin/bash
# bundler for automated tests
set -e
echo ""
echo "*********************************************************************************"
echo ""
cd blacklight-cornell

source ../jenkins/environment.sh

# Clean up existing Bundler installations
gem uninstall bundler -aIx

# Reinstall Bundler without documentation
gem install bundler -v 2.4.10 --no-document

# Ensure the PATH includes the directory where Bundler is installed
export PATH=$GEM_HOME/bin:$PATH

# Verify Bundler installation
which bundle
bundle --version

# Define an array of directories
safe_directories=(
  "/usr/local/rvm/gems/ruby-3.2.2/cache/bundler/git/csl-styles-413c6d0d4d7cc7a3fcde1c5ec9976b007257fc07"
  "/usr/local/rvm/gems/ruby-3.2.2/cache/bundler/git/cul-my-account-d2727df0453f58fea08b04f7c6a29bbc038ea24c"
  "/usr/local/rvm/gems/ruby-3.2.2/cache/bundler/git/cul-folio-edge-191b915bddb1d0cbdaa3ee2ff87d0cc86c642f11"
  "/usr/local/rvm/gems/ruby-3.2.2/cache/bundler/git/blacklight-unapi-c14686948391b4e2f8f6dce0ccfd1019728d8c9b"
  "/usr/local/rvm/gems/ruby-3.2.2/cache/bundler/git/spreewald-75182b89ad36be7783a3dd312bd8f9ab3019c195"
)

# Loop through the array and add each directory to the safe list
for dir in "${safe_directories[@]}"; do
  git config --global --add safe.directory "$dir"
done

bundle update blacklight_unapi blacklight_cornell_requests my_account sqlite3
bundle install
bundle info concurrent-ruby

# Set the environment for the test database
echo "Setting environment for the test database..."
bin/rails db:environment:set RAILS_ENV=${RAILS_ENV}

# Run database migrations
echo "Running database migrations..."
bundle exec rake db:migrate

brakeman --fast  -o brakeman-output.json
echo $RAILS_ENV
rm -fr results/*
mkdir -p results
rm -f features/cassettes/cucumber_tags/*
echo ""
echo "*********************************************************************************"
echo "Starting tests..."
echo ""
