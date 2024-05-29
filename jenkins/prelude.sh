#!/bin/bash
# bundler for automated tests
set -e
echo ""
echo "*********************************************************************************"
echo ""
source jenkins/environment.sh
gem install bundler -v 2.3.26
gem uninstall concurrent-ruby
cd blacklight-cornell
bundle update blacklight_unapi blacklight_cornell_requests my_account sqlite3
bundle install
bundle info concurrent-ruby
RAILS_ENV=test bin/rake db:migrate
brakeman --fast  -o brakeman-output.json
echo $RAILS_ENV
rm -fr results/*
mkdir -p results
rm -f features/cassettes/cucumber_tags/*
echo ""
echo "*********************************************************************************"
echo "Starting tests..."
echo ""
