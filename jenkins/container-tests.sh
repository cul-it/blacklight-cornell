#!/bin/bash
set -e
echo ""
echo "*********************************************************************************"
echo "Running tests in container"
echo "*********************************************************************************"
source jenkins/environment.sh

sudo systemctl start docker
cp /cul/data/jenkins/environments/blacklight-cornell.env container_env_test.env

export COVERAGE=on
export RAILS_ENV_FILE=./container_env_test.env
export COVERAGE_PATH=${JENKINS_WORKSPACE}/blacklight-cornell/coverage
project_name="container-discovery-test-$(openssl rand -hex 8)"
./build_test.sh
docker compose -p $project_name -f docker-compose-test.yaml up
EXIT_CODE=$?
echo $EXIT_CODE
export USE_RSPEC=1
unset FEATURE
docker compose -p $project_name -f docker-compose-test.yaml up
R_EXIT_CODE=$?
echo $R_EXIT_CODE

if [ $EXIT_CODE != 0 ] || [ $R_EXIT_CODE != 0 ]
  then
    exit 1
fi
