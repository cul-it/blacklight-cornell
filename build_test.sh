#!/usr/bin/env bash

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

# Use bogus file as railsenv - test build phase does not use it
rails_env_file=$(resolve_relative_path "$0")
export RAILS_ENV_FILE="${rails_env_file}"
echo $RAILS_ENV_FILE

export COVERAGE_PATH=$(resolve_relative_path "blacklight-cornell/coverage")

echo "docker compose -f docker-compose-test.yaml build"
docker compose -f docker-compose-test.yaml build

unset COVERAGE_PATH
unset RAILS_ENV_FILE
unset SELENIUM_IMAGE
