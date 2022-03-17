#!/bin/sh

# use this script to run cucumber with the same options as jenkins.
echo 'Use this script to run cucumber with the same options as jenkins.'
echo 'But you also need to make sure that your .env file matches.'
echo 'To run a specific suite, add file argument like features/catalog_search/results_list.feature'
echo 'To run a specific test, add line argument like features/catalog_search/results_list.feature:317'
# OPT1="-t ~@oclc_request  -t ~@search_with_view_all_webs_match_box_with_percent "
# # this saves results in the xml format of junit
# OPT3="-t ~@boundwith  -p jenkins_lax --format junit --out results/ "
# # this displays test results in human readable format.
# OPT3="-t ~@boundwith  -p jenkins_lax "
# OPT2="-t ~@search_availability_title_mission_etrangeres_missing "
# OPT4=" -t not @saml_off "

OPT="not @oclc_request and not @search_with_view_all_webs_match_box_with_percent"
# this saves results in the xml format of junit
OPT="$OPT and not @boundwith"
# this displays test results in human readable format.
OPT="$OPT and not @boundwith"
OPT="$OPT and not @search_availability_title_mission_etrangeres_missing"
OPT="$OPT and not @saml_off"
ARGS="-p jenkins_lax --format junit --out results/"

echo "Options:"
echo $OPT
echo "Arguments:"
echo $ARGS

if [ $# -eq 0 ]; then
    bundle exec cucumber --tags '${OPT}' $ARGS
else
    bundle exec cucumber --tags '${OPT}' $ARGS "$1"
fi

