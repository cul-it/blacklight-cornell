#!/bin/bash
set -e
echo ""
echo "*********************************************************************************"
echo ""
source jenkins/environment.sh
echo "PATH is:$PATH"
echo "Solr: $SOLR_URL"
which bundle
if [ $# -eq 0 ]
    then
        echo "Running all feature tests."
        COVERAGE=true ../jenkins-opts.sh
    else
        echo "Running feature: $1"
        ls ../../
        COVERAGE=true ../../jenkins-opts.sh "$1"
fi