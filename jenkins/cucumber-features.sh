#!/bin/bash
set -e
echo ""
echo "*********************************************************************************"
echo ""
source jenkins/environment.sh
echo "PATH is:$PATH"
echo "Solr: $SOLR_URL"
which bundle
OPT1="-t ~@oclc_request  -t ~@search_with_view_all_webs_match_box_with_percent "
OPT3="-t ~@boundwith  -p jenkins_lax --format junit --out results/ "
OPT2="-t ~@search_availability_title_mission_etrangeres_missing "
OPT4=" -t ~@saml_off "
if [ $# -eq 0 ]
    then
        echo "Running all feature tests."
        COVERAGE=true RAILS_ENV=test bundle exec cucumber $OPT1 $OPT2 $OPT3 $OPT4
    else
        echo "Running feature: $1"
        COVERAGE=true RAILS_ENV=test bundle exec cucumber $OPT1 $OPT2 $OPT3 $OPT4 "$1"
fi