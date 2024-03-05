#!/usr/bin/env bash

export GEM_HOME=/usr/local/bundle/ruby/3.1.0
export AWS_REGION=us-east-1

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
$SCRIPT_DIR/fetch_yaml_alerts.rb
