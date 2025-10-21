#!/usr/bin/env bash

usage() {
  echo "Usage: $0 [ -r RAILS_ENV_FILE ] [-i (NO ARG, INTERACTIVE SESSION)] [-p (NO ARG, SET PLATFORM TO AMD64 FOR M1/M2 CHIPS)] [-d (NO ARG, DEVELOP MODE)]" 1>&2 
  echo "Example: $0 -r PATH_TO/RAILS_ENV_FILE"
}
exit_abnormal() {
  usage
  exit 1
}

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
compose="docker-compose.yaml"
development=""
feature=""
image_name="container-discovery"
integration=0
interactive=""
platform=""
port="9292:9292"
rails_env="production"
rails_env_file=""
run_cmd="up"
run_cron="false"
test_app_version=""
# while getopts "cdhipt:a:r:" options; do
while getopts "cdhitp:a:e:m:r:v:" options; do
  case "${options}" in
    a) aws_creds=$(resolve_relative_path "${OPTARG}") ;; # -a aws_creds
    c) run_cron="true" ;;
    d) rails_env="development"
       development="-f docker-compose-development.yaml" ;;
    e) rails_env="${OPTARG}" ;; # -e rails_env
    h) usage
       exit 0 ;;
    i) run_cmd="run --entrypoint=bash webapp" ;;
    m) image_name="${OPTARG}" ;; # -m image_name
    p) platform="--platform=linux/amd64" ;;
    r) rails_env_file=$(resolve_relative_path "${OPTARG}") ;;
    t) integration=1
       rails_env="integration" ;;
    v) test_app_version="${OPTARG}" ;;
    *) exit_abnormal ;;
  esac
done

if [ "${integration}" == 1 ] && [ "${image_name}" == "container-discovery" ]
  then
    image_name="container-discovery-int"
fi

# If there is a running container, bash into it.
# The output of this docker command is:
# CONTAINER_ID container-discovery:TAG
# We only need the first information to bash into.
running_test=$(docker inspect --format="{{.Id}} {{.Config.Image}}" $(docker ps -q) | grep ${image_name}:)
for term in $running_test
do
  docker exec -it "$term" bash
  exit
done

# if [ "${aws_creds}" == "" ] && [ "${rails_env}" == "" ]
if [ "${aws_creds}" == "" ] && [ "${rails_env_file}" == "" ]
  then
    echo "-r flag is required."
    exit_abnormal
fi

if [ "${aws_creds}" != "" ]
  then
    export AWS_CREDENTIALS=${aws_creds}
    compose="docker-compose-cred.yaml"
    if [ "${development}" != "" ]
      then
        # currently not supported
        development=""
    fi
fi

if [ "${test_app_version}" != "" ]
  then
    echo "APP VERSION for testing: ${test_app_version}"
    export TEST_APP_VERSION=${test_app_version}
fi

export IMAGE_NAME=${image_name}
export RAILS_ENV=${rails_env}
export RAILS_ENV_FILE=${rails_env_file}
if [ "${run_cron}" == "true" ]
  then
    export RUN_CRON="true"
fi

# img_id=$(git rev-parse head)
# echo "Running ${target}:${img_id} ${feature}"

echo "docker compose -f ${compose} down --remove-orphans"
docker compose -f ${compose} down --remove-orphans

# docker system prune -f
echo "docker compose -f ${compose} ${development} ${run_cmd}"
docker compose -f ${compose} ${development} ${run_cmd}

unset AWS_CREDENTIALS
unset IMAGE_NAME
unset RAILS_ENV
unset RAILS_ENV_FILE
unset RUN_CRON
unset TEST_APP_VERSION
