#!/bin/bash
set -e
echo ""
echo "*********************************************************************************"
echo "Running cucumber tests in container"
echo "*********************************************************************************"
source jenkins/environment.sh

sudo systemctl start docker
cp /cul/data/jenkins/environments/blacklight-cornell.env container_env_test.env

export COVERAGE=on
export RAILS_ENV_FILE=./container_env_test.env
export COVERAGE_PATH=${JENKINS_WORKSPACE}/blacklight-cornell/coverage
project_name="container-discovery-test-${TEST_ID}"
echo "Cucumber tests for ${project_name}"
docker compose -f docker-compose-test.yaml build
docker compose -p $project_name -f docker-compose-test.yaml up --exit-code-from webapp
docker compose -p $project_name -f docker-compose-test.yaml down --volumes --remove-orphans
