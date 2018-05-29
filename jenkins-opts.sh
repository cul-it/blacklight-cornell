#!/bin/sh
# use this script to run cucumber with the same options as jenkins.
echo 'Use this script to run cucumber with the same options as jenkins.'
echo 'But you also need to make sure that your .env file matches.'
OPT1="-t ~@oclc_request  -t ~@search_with_view_all_webs_match_box_with_percent "
# this saves results in the xml format of junit
OPT3="-t ~@boundwith  -p jenkins_lax --format junit --out results/ "
# this displays test results in human readable format. 
OPT3="-t ~@boundwith  -p jenkins_lax "
OPT2="-t ~@search_availability_title_mission_etrangeres_missing "
OPT4=" -t ~@saml_off "
bundle exec cucumber $OPT1 $OPT2 $OPT3 $OPT4 
