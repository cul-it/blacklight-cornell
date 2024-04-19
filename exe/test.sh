#!/usr/bin/env bash

WORKDIR="/blacklight-cornell"
cd $WORKDIR

if [ -z "${APP_VERSION}" ]
  then
    echo "APP_VERSION is not specified, exiting."
    exit 1
fi

./set_env.sh

export RAILS_ENV="test"
export RAILS_LOG_TO_STDOUT="1"
export RAILS_SERVE_STATIC_FILES="true"
export BUNDLE_WITHOUT="development"

bundle exec rake db:create
bundle exec rake db:migrate
# bundle exec rake assets:precompile

feature=${FEATURE:-}
while getopts "f:" options; do
  case "${options}" in
    f) feature="${OPTARG}" ;;
  esac
done

# echo "USE_TEST_CONTAINER: ${USE_TEST_CONTAINER}"

if [ "${USE_RSPEC}" ]
  then
    echo "bundle exec rspec ${feature}"
    bundle exec rspec $feature
  else
    echo "/blacklight-cornell/jenkins-opts.sh ${feature}"
    /blacklight-cornell/jenkins-opts.sh $feature
fi

# /blacklight-cornell/jenkins-opts.sh features/catalog_search/advanced_search.feature
