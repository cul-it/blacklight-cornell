#!/bin/bash
set -e
echo ""
echo "*********************************************************************************"
echo ""
source jenkins/environment.sh
cd blacklight-cornell
echo "PATH is:$PATH"
echo "Solr: $SOLR_URL"
which bundle
OPT1="-t ~@oclc_request  -t ~@search_with_view_all_webs_match_box_with_percent "
OPT3="-t ~@boundwith  -p jenkins_lax --format junit --out results/ "
OPT2="-t ~@search_availability_title_mission_etrangeres_missing "
OPT4=" -t ~@saml_off "
export COVERAGE=on
export RAILS_ENV=test
if [ -z ${CUCUMBER_FEATURE_TESTS+x} ]
    then
        echo "Running all feature tests."
        bundle exec cucumber $OPT1 $OPT2 $OPT3 $OPT4
    else
        echo "Running feature: ${CUCUMBER_FEATURE_TESTS}"
        bundle exec cucumber $OPT1 $OPT2 $OPT3 $OPT4 "${CUCUMBER_FEATURE_TESTS}"
fi