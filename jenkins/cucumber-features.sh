#!/bin/bash
set -e
echo ""
echo "*********************************************************************************"
echo "Running Cucumber tests in parallel"
echo "*********************************************************************************"
source jenkins/environment.sh
cd blacklight-cornell

echo "PATH is: $PATH"
echo "Solr: $SOLR_URL"
which bundle

# Define test options
OPT1="-t ~@oclc_request  -t ~@search_with_view_all_webs_match_box_with_percent "
OPT3="-t ~@boundwith  -p jenkins_lax --format junit --out results/ "
OPT2="-t ~@search_availability_title_mission_etrangeres_missing "
OPT4=" -t ~@saml_off "
OPT5="-t ~@solr_query_display "

export COVERAGE=on
export RAILS_ENV=test

# Run tests in parallel
#NUM_PROCESSES=4 # Adjust this based hardcoded processors you want to use
NUM_PROCESSES=$(nproc --all) # Use all available jenkins processors

if [ -z ${CUCUMBER_FEATURE_TESTS+x} ]; then
    echo "Running all feature tests."
    bundle exec parallel_cucumber features/ -n $NUM_PROCESSES --test-options "$OPT1 $OPT2 $OPT3 $OPT4 $OPT5"
else
    echo "Running feature: ${CUCUMBER_FEATURE_TESTS}"
    bundle exec parallel_cucumber "${CUCUMBER_FEATURE_TESTS}" -n $NUM_PROCESSES --test-options "$OPT1 $OPT2 $OPT3 $OPT4 $OPT5"
fi