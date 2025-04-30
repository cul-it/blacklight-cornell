#!/bin/bash
set -e
echo ""
echo "*********************************************************************************"
echo "Running RSpec tests in container"
echo "*********************************************************************************"
source jenkins/environment.sh

cp /cul/data/jenkins/environments/blacklight-cornell.env container_env_test.env

export COVERAGE=on
export RAILS_ENV_FILE=./container_env_test.env
export COVERAGE_PATH=${JENKINS_WORKSPACE}/blacklight-cornell/coverage
project_name="container-discovery-test-${TEST_ID}"
echo "RSpec tests for ${project_name}"
export USE_RSPEC=1
docker compose -p $project_name -f docker-compose-test.yaml up --exit-code-from webapp
docker compose -p $project_name -f docker-compose-test.yaml down
