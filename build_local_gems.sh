#!/usr/bin/env bash

usage() {
  echo "Usage: $0 [-r RAILS_ENV_FILE] [-p (NO ARG, SET PLATFORM TO AMD64)]" 1>&2
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

platform=""
image="container-discovery-local-gems"
rails_env_file=""
commit_hash=""
while getopts "hpr:c:m:" options; do
  case "${options}" in
    c) commit_hash="${OPTARG}" ;;
    m) image="${OPTARG}" ;;
    p) platform="--platform=linux/amd64"
       image="container-discovery-amd64" ;;
    r) rails_env_file=$(resolve_relative_path "${OPTARG}") ;;
    h) usage
      exit 0 ;;
    *) exit_abnormal ;;
  esac
done

# Building prod image requires rails env for asset precompile step
if [ "${rails_env_file}" == "" ]
  then
    echo "-r flag is required with valid path to rails env file."
    exit_abnormal
fi

export RAILS_ENV_FILE=${rails_env_file}

# Dockerfile expects .env file to be on the root directory.
# Unless the provided rails env file is PROJECT_ROOT/.env,
#  create a temporary copy and delete it afterwards.
# env_path will be empty unless provided rails env file is PROJECT_ROOT/.env
env_path=$(resolve_relative_path "$(dirname "$0")/.env")
if [ "$env_path" == "" ]
  then
    cp "${rails_env_file}" "$(dirname "$0")/.env"
fi

if [ "${commit_hash}" == "" ]
  then
    commit_hash=$(git rev-parse head)
fi
export GIT_COMMIT=${commit_hash}
export IMAGE_NAME=${image}
echo "Building ${image}:${commit_hash}"

# echo "docker build -f docker/blacklight/Dockerfile -t ${image}:${img_id} ${platform} --build-arg GIT_COMMIT=${img_id} ${p} ."
# docker build -f docker/blacklight/Dockerfile -t ${image}:${img_id} -t ${image}:latest ${platform} --build-arg GIT_COMMIT=${img_id} ${p} .

echo "docker compose -f docker-compose-local-gems.yaml build --build-arg GIT_COMMIT=${commit_hash}"
docker compose -f docker-compose-local-gems.yaml build --build-arg GIT_COMMIT=${commit_hash}
echo "tag ${image}:latest ${image}:${commit_hash}"
docker tag ${image}:latest ${image}:${commit_hash}

unset RAILS_ENV_FILE
unset GIT_COMMIT
unset IMAGE_NAME
if [ "$env_path" == "" ]
  then
    rm "$(dirname "$0")/.env"
fi
