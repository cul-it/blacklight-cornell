#!/bin/sh

# use this script to run cucumber with the same options as jenkins.
echo 'Use this script to run cucumber with the same options as jenkins.'
echo 'But you also need to make sure that your .env file matches.'
echo 'To run a specific suite, add file argument like features/catalog_search/results_list.feature'
echo 'To run a specific test, add line argument like features/catalog_search/results_list.feature:317'

# Old set of options, looks like contains some duplicates
## OPT1="-t ~@oclc_request  -t ~@search_with_view_all_webs_match_box_with_percent "
# this saves results in the xml format of junit
## OPT5="-t ~@boundwith  -p jenkins_lax --format junit --out results/ "
# this displays test results in human readable format.
## OPT3="-t ~@boundwith  -p jenkins_lax "
## OPT2="-t ~@search_availability_title_mission_etrangeres_missing "
## OPT4=" -t ~@saml_off "

# not doesn't work, use ~@ although it gives us warning
# OPT1="--tags 'not @oclc_request'"
# OPT2="--tags 'not @search_with_view_all_webs_match_box_with_percent'"
# # this saves results in the xml format of junit
# OPT3="--tags 'not @boundwith'"
# # this displays test results in human readable format.
# OPT4="--tags 'not @boundwith'"
# OPT5="--tags 'not @search_availability_title_mission_etrangeres_missing'"
# OPT6="--tags 'not @saml_off'"

OPT1="-t ~@oclc_request -t ~@search_with_view_all_webs_match_box_with_percent"
OPT3="-t ~@boundwith"
OPT2="-t ~@search_availability_title_mission_etrangeres_missing"
OPT4="-t ~@saml_off"

ARGS="-p jenkins_lax --format junit --out results"

echo "Options:"
echo $OPT1 $OPT2 $OPT3 $OPT4
echo "Arguments:"
echo $ARGS

COVERAGE=${COVERAGE:-on}
NUM_PROCESSES=${NUM_PROCESSES:-1}
echo "Number of processes: $NUM_PROCESSES"

feature=""
if [ $# -gt 0 ]; then
    feature=$1
fi

if [ $NUM_PROCESSES -eq 1 ]; then
    echo "Running in single process mode."
    echo "COVERAGE=$COVERAGE bundle exec cucumber $ARGS $OPT1 $OPT2 $OPT3 $OPT4 $feature"
    COVERAGE=$COVERAGE bundle exec cucumber $ARGS $OPT1 $OPT2 $OPT3 $OPT4 $feature
else
    echo "Running in parallel mode."
    echo "COVERAGE=$COVERAGE bundle exec parallel_cucumber -n $NUM_PROCESSES -o \"$ARGS $OPT1 $OPT2 $OPT3 $OPT4\" $feature"
    COVERAGE=$COVERAGE bundle exec parallel_cucumber -n $NUM_PROCESSES -o "$ARGS $OPT1 $OPT2 $OPT3 $OPT4" $feature
fi
