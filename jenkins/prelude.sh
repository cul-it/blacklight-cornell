#!/bin/bash
# bundler for automated tests
set -e
echo ""
echo "*********************************************************************************"
echo ""
source jenkins/environment.sh
gem install bundler -v 2.3.14
bundle _2.3.14_ update blacklight_unapi
bundle _2.3.14_ update blacklight_cornell_requests
bundle _2.3.14_ update my_account
bundle _2.3.14_ update sqlite3
bundle _2.3.14_ install
echo ""
echo "*********************************************************************************"
echo "Starting tests..."
echo ""
