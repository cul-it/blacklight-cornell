#!/usr/bin/env bash

WORKDIR="/blacklight-cornell"
cd $WORKDIR

# export RAILS_ENV="production"
if [ -z "${RAILS_ENV}" ]
  then
    echo "RAILS_ENV not set, will use production"
    export RAILS_ENV="production"
fi
export RAILS_LOG_TO_STDOUT="1"
export RAILS_SERVE_STATIC_FILES="true"

if [ -z "${APP_VERSION}" ]
  then
    echo "APP_VERSION is not specified, exiting."
    exit 1
fi

./set_env.sh

bundle exec rake db:migrate

if [ "${RUN_CRON}" != "false" ]
  then
    bundle exec whenever --update-crontab
    service cron start
fi

bundle exec puma -C config/puma.rb
