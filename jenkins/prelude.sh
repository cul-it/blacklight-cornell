#!/bin/bash
# bundler for automated tests
set -e
echo ""
echo "*********************************************************************************"
echo ""
source jenkins/environment.sh
gem install simplecov
gem install bundler -v 2.3.14
bundle _2.3.14_ install
echo ""
echo "*********************************************************************************"
echo "Starting tests..."
echo ""
