#!/bin/bash
echo "**************** environment ****************"
echo "Branch:"
git rev-parse --abbrev-ref HEAD
echo "JENKINS_HOME: $JENKINS_HOME"
echo "Solr: $SOLR_URL"
PATH=$PWD/bin:$PATH
PATH=$GEM_HOME/bin:$PWD/bin:/usr/local/bin:$PATH
source /etc/profile.d/rvm.sh
export RUBYVERSION=ruby-3.1.2
echo "Ruby: $RUBYVERSION"
GEM_HOME="/usr/local/rvm/gems/$RUBYVERSION"
rvm use "$RUBYVERSION"
echo "PATH is:$PATH"
which bundle
chromedriver --version
echo "Xvfb DISPLAY value is $DISPLAY"
cp /cul/data/jenkins/environments/blacklight-cornell.env .env
