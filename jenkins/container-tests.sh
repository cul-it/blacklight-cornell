#!/bin/bash
set -e
echo ""
echo "*********************************************************************************"
echo "Running tests in container"
echo "*********************************************************************************"
source jenkins/environment.sh

sudo systemctl start docker
cp /cul/data/jenkins/environments/blacklight-cornell.env container_env_test.env
img_id=$(git rev-parse HEAD)
img=092831676293.dkr.ecr.us-east-1.amazonaws.com/da/blacklight-cornell-prod:${img_id} 

./build_test.sh
export COVERAGE=on
export RAILS_ENV_FILE=./container_env_test.env
export SELENIUM_IMAGE=selenium/standalone-chrome
# export FEATURE=features/assumption/assume.feature
project_name="container-discovery-test-$(openssl rand -hex 8)"
export SELENIUM_PORT=4444
export NUM_PROCESSES=2
docker compose -f docker-compose-test-network.yaml up
if [ $(docker compose -f docker-compose-test-chrome.yaml ps -q | wc -l) -eq 0 ]; then
  docker compose -f docker-compose-test-chrome.yaml up -d
  sleep 5
fi
docker compose -p $project_name -f docker-compose-test-webapp.yaml --profile cucumber up
EXIT_CODE=$?
echo $EXIT_CODE
export FEATURE=spec/helpers/advanced_helper_spec.rb
export USE_RSPEC=1
docker compose -p container-discovery-test -f docker-compose-test.yaml run webapp
R_EXIT_CODE=$?
echo $R_EXIT_CODE

if [ $EXIT_CODE != 0 ] || [ $R_EXIT_CODE != 0 ]
  then
    exit 1
fi
