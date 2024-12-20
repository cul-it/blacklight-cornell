#!/bin/sh

# use this script to run cucumber with the same options as jenkins.
echo 'Use this script to run cucumber with the same options as jenkins.'
echo 'But you also need to make sure that your .env file matches.'
echo 'To run a specific suite, add file argument like features/catalog_search/results_list.feature'
echo 'To run a specific test, add line argument like features/catalog_search/results_list.feature:317'
OPT1="-t ~@oclc_request  -t ~@search_with_view_all_webs_match_box_with_percent "
# this saves results in the xml format of junit
OPT5="-t ~@boundwith  -p jenkins_lax --format junit --out results/ "
# this displays test results in human readable format.
OPT3="-t ~@boundwith  -p jenkins_lax "
OPT2="-t ~@search_availability_title_mission_etrangeres_missing "
OPT4=" -t ~@saml_off "

# OPT1="--tags 'not @oclc_request'"
# OPT2="--tags 'not @search_with_view_all_webs_match_box_with_percent'"
# # this saves results in the xml format of junit
# OPT3="--tags 'not @boundwith'"
# # this displays test results in human readable format.
# OPT4="--tags 'not @boundwith'"
# OPT5="--tags 'not @search_availability_title_mission_etrangeres_missing'"
# OPT6="--tags 'not @saml_off'"
ARGS="-p jenkins_lax --format junit --out results"

echo "Options:"
echo $OPT1 $OPT2 $OPT3 $OPT4 $OPT5 $OPT6
echo "Arguments:"
echo $ARGS

if [ $# -eq 0 ]; then
    COVERAGE=on bundle exec cucumber $ARGS $OPT1 $OPT2 $OPT3 $OPT4 $OPT5
else
    COVERAGE=on bundle exec cucumber $ARGS $OPT1 $OPT2 $OPT3 $OPT4 $OPT5 "$1"
fi

