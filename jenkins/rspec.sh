#!/bin/bash
set -e

echo ""
echo "##########################################################################"
echo "Running rspec tests..."
echo "##########################################################################"
echo ""

source jenkins/environment.sh
cd blacklight-cornell
echo "PATH is:$PATH"
echo "Solr: $SOLR_URL"
which bundle
export COVERAGE=on
export RAILS_ENV=test

echo ""
echo "##########################################################################"
echo "Google Chrome version..."
which google-chrome
echo "##########################################################################"
echo ""
echo ""
echo "##########################################################################"
echo "Chrome Driver..."
which chromedriver
echo "##########################################################################"
echo ""

if [ $# -eq 0 ]
    then
        echo "Running all rspec tests."
        bundle exec rspec
    else
        echo "Running spec: $1"
        bundle exec rspec "$1"
fi