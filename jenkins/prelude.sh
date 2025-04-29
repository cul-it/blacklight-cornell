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

# Force native gem compilation (avoid incompatible precompiled binaries with GLIBC)
#bundle config set force_ruby_platform true

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
echo "Rails environment: $RAILS_ENV"
rm -fr results/*
mkdir -p results
rm -f features/cassettes/cucumber_tags/*
echo ""
echo "*********************************************************************************"
echo "Starting tests..."
echo ""
