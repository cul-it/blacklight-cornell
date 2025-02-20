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
# export FEATURE=features/assumption/assume.feature
project_name="container-discovery-test-$(openssl rand -hex 8)"
# export NUM_PROCESSES=2
docker compose -p $project_name -f docker-compose-test.yaml up
EXIT_CODE=$?
echo $EXIT_CODE
export USE_RSPEC=1
docker compose -p container-discovery-test -f docker-compose-test.yaml up
R_EXIT_CODE=$?
echo $R_EXIT_CODE

if [ $EXIT_CODE != 0 ] || [ $R_EXIT_CODE != 0 ]
  then
    exit 1
fi
