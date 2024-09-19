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

git config --global --add safe.directory /usr/local/rvm/gems/ruby-3.2.2/cache/bundler/git/csl-styles-413c6d0d4d7cc7a3fcde1c5ec9976b007257fc07


bundle update --redownload blacklight_unapi blacklight_cornell_requests my_account sqlite3
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
