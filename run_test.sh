#!/usr/bin/env bash

usage() {
  echo "Usage: $0 [ -r RAILS_ENV_FILE ] [-f FEATURE TO TEST] [-s, NO ARG, USE RSPEC]" 1>&2 
  echo "Example: $0 -r PATH_TO/RAILS_ENV_FILE"
}
exit_abnormal() {
  usage
  exit 1
}

# If there is a running test container, bash into it.
# The output of this docker command is:
# CONTAINER_ID container-discovery-test:latest
# We only need the first information to bash into.
running_test=$(docker inspect --format="{{.Id}} {{.Config.Image}}" $(docker ps -q) | grep container-discovery-test)
for term in $running_test
do
  docker exec -it "$term" bash
  exit
done

# https://www.baeldung.com/linux/bash-expand-relative-path
resolve_relative_path() (
    # If the path is a directory, we just need to 'cd' into it and print the new path.
    if [ -d "$1" ]; then
        cd "$1" || return 1
        pwd
    # If the path points to anything else, like a file or FIFO
    elif [ -e "$1" ]; then
        # Strip '/file' from '/dir/file'
        # We only change the directory if the name doesn't match for the cases where
        # we were passed something like 'file' without './'
        if [ ! "${1%/*}" = "$1" ]; then
            cd "${1%/*}" || return 1
        fi
        # Strip all leading slashes upto the filename
        echo "$(pwd)/${1##*/}"
    else
        return 1 # Failure, neither file nor directory exists.
    fi
)

aws_creds=""
compose_file="docker-compose-test.yaml"
rails_env_file=""
feature=""
run_cmd="up --abort-on-container-exit --exit-code-from webapp"
use_rspec=""
manual_compose_down=""
profiles="--profile cucumber"
while getopts "shia:r:f:" options; do
  case "${options}" in
    a) abs_path=$(resolve_relative_path "${OPTARG}")
       aws_creds="-v ${abs_path}:/custom_mnt/credentials:ro" ;;
    r) rails_env_file=$(resolve_relative_path "${OPTARG}") ;;
    f) feature=${OPTARG} ;;
    h) usage
      exit 0 ;;
    i) compose_file="docker-compose-test-interactive.yaml"
       run_cmd="run --entrypoint=bash webapp"
       manual_compose_down="1" ;;
    s) use_rspec="1"
       profiles="" ;;
    *) exit_abnormal ;;
  esac
done

if [ "${aws_creds}" == "" ] && [ "${rails_env_file}" == "" ]
  then
    echo "One of -r or -a flag is required."
    exit_abnormal
fi

if [ "${rails_env_file}" != "" ]
  then
    export RAILS_ENV_FILE=${rails_env_file}
fi
echo $RAILS_ENV_FILE

export USE_RSPEC=${use_rspec}

selenium_image="seleniarm/standalone-chromium"
SYSTEM_ARCH=$(arch | sed s/aarch64/arm64/)
if [ $SYSTEM_ARCH != 'arm64' ]
  then
    selenium_image="selenium/standalone-chrome"
fi
export SELENIUM_IMAGE=${selenium_image}
echo $SELENIUM_IMAGE

if [ "${feature}" != "" ]
  then
    echo "I got feature: ${feature}"
    export FEATURE=${feature}
fi

# Provide -p container-discovery-test flag to give this a different name than regular run.
# Without it, docker will use current directory name and will not allow running both test
#   and rails container at the same time.
echo "Running tests with ${feature}"
echo "docker compose -p container-discovery-test -f ${compose_file} ${profiles} ${run_cmd}"
docker compose -p container-discovery-test -f ${compose_file} down --remove-orphans
# docker system prune -f
docker compose -p container-discovery-test -f ${compose_file} ${profiles} ${run_cmd}
if [ "${manual_compose_down}" != "" ]
  then
    docker compose -p container-discovery-test -f ${compose_file} down --remove-orphans
fi

unset FEATURE
unset RAILS_ENV_FILE
unset SELENIUM_IMAGE
unset USE_RSPEC
