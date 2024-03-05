#!/bin/bash
set -e
echo ""
echo "*********************************************************************************"
echo ""
source jenkins/environment.sh
echo "PATH is:$PATH"
echo "Solr: $SOLR_URL"
which bundle
export COVERAGE=on
export RAILS_ENV=test
if [ $# -eq 0 ]
    then
        echo "Running all rspec tests."
        bundle exec rspec
    else
        echo "Running spec: $1"
        bundle exec rspec "$1"
fi