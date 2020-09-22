#!/bin/sh

# use this script to run cucumber with the same options as jenkins.
echo 'Use this script to run cucumber with the same options as jenkins.'
echo 'But you also need to make sure that your .env file matches.'
echo 'To run a specific suite, add file argument like features/catalog_search/results_list.feature'
echo 'To run a specific test, add line argument like features/catalog_search/results_list.feature:317'
OPT1="-t ~@oclc_request  -t ~@search_with_view_all_webs_match_box_with_percent "
# this saves results in the xml format of junit
OPT3="-t ~@boundwith  -p jenkins_lax --format junit --out results/ "
# this displays test results in human readable format.
OPT3="-t ~@boundwith  -p jenkins_lax "
OPT2="-t ~@search_availability_title_mission_etrangeres_missing "
OPT4=" -t ~@saml_off "

if [ $# -eq 0 ]; then
    bundle exec cucumber $OPT1 $OPT2 $OPT3 $OPT4
else
    bundle exec cucumber $OPT1 $OPT2 $OPT3 $OPT4 "$1"
fi

