#!/bin/bash
echo "**************** environment ****************"
echo "Branch:"
git rev-parse --abbrev-ref HEAD
echo "JENKINS_HOME: $JENKINS_HOME"
PATH=$PWD/bin:$PATH
PATH=$GEM_HOME/bin:$PWD/bin:/usr/local/bin:$PATH
source /etc/profile.d/rvm.sh
export RUBYVERSION=ruby-3.1.2
echo "Ruby: $RUBYVERSION"
export GEM_HOME="/usr/local/rvm/gems/$RUBYVERSION"
export GEM_PATH="/usr/local/rvm/gems/$RUBYVERSION:/usr/local/rvm/gems/$RUBYVERSION@global"
rvm use "$RUBYVERSION"
PATH="/opt/rh/devtoolset-10/root/usr/bin:$PATH"
PATH="/usr/local/bin:$PWD/bin:$PATH"
echo "PATH is:$PATH"
export OPENSSL_CONF=/dev/null
which bundle
chromedriver --version
echo "Xvfb DISPLAY value is $DISPLAY"
cp /cul/data/jenkins/environments/blacklight-cornell.env .env
uuid=$(uuidgen)
DEBUG_USER="ditester${uuid}@example.edu"
echo "Diligent Tester: $DEBUG_USER"
echo "DEBUG_USER=${DEBUG_USER}" >>.env
grep ^SOLR_URL .env
export RAILS_ENV=test
