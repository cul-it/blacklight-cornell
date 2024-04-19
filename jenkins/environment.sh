#!/bin/bash
echo "**************** environment ****************"

# Define variables
RUBYVERSION="ruby-3.2.2"
export RUBYVERSION
uuid=$(uuidgen)
DEBUG_USER="ditester${uuid}@example.edu"
export OPENSSL_CONF=/dev/null
export GEM_HOME="/usr/local/rvm/gems/$RUBYVERSION"
export GEM_PATH="/usr/local/rvm/gems/$RUBYVERSION:/usr/local/rvm/gems/$RUBYVERSION@global"
export RAILS_ENV=test

# Update PATH
PATH="/opt/rh/devtoolset-10/root/usr/bin:$PATH"
PATH="/usr/local/bin:$PWD/bin:$PATH"
PATH=$PWD/bin:$PATH
PATH=$GEM_HOME/bin:$PWD/bin:/usr/local/bin:$PATH

# Source RVM
source /etc/profile.d/rvm.sh

# Use specific Ruby version
rvm use "$RUBYVERSION"

# Copy environment file
cp /cul/data/jenkins/environments/blacklight-cornell.env .env

# Add DEBUG_USER to environment file
echo "DEBUG_USER=${DEBUG_USER}" >>.env

# Move environment file
mv .env blacklight-cornell/.env

# Print debug information
git rev-parse --abbrev-ref HEAD
echo "JENKINS_HOME: $JENKINS_HOME"
echo "Ruby: $RUBYVERSION"
echo "PATH is:$PATH"
which bundle
chromedriver --version
echo "Xvfb DISPLAY value is $DISPLAY"
echo "Diligent Tester: $DEBUG_USER"
grep ^SOLR_URL .env