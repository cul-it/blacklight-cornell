#!/usr/bin/env bash

usage() {
  echo "Usage: $0 [ -r RAILS_ENV_FILE ] [ -b ROLLBACK_COMMIT_HASH ]" 1>&2 
  echo "Example: $0 -r PATH_TO/RAILS_ENV_FILE"
  echo "Example: $0 # deploy with no changes to rails env from previous deployment"
  echo "Example: $0 -b PREVIOUS_COMMIT_HASH"
}
exit_abnormal() {
  usage
  exit 1
}

BUCKET='container-discovery'
img_id=$(git rev-parse head)

rails_env=""
rollback_commit_hash=""
while getopts "hr:c:" options; do
  case "${options}" in
    r) rails_env=${OPTARG} ;;
    c) rollback_commit_hash=${OPTARG} 
      img_id=${rollback_commit_hash};;
    h) usage
      exit 0 ;;
    *) exit_abnormal ;;
  esac
done

if [ "${rollback_commit_hash}" != "" ]
  then
    echo "Commit hash is provided, this will roll back latest rails env to this hash"
fi

latest_key="container_env_latest"
env_key="container_env_${img_id}"
if [ "${rails_env}" != "" ]
  then
    echo "${rails_env} will be deployed"
    
    aws s3 cp ${rails_env} s3://${BUCKET}/${env_key}
    aws s3 cp s3://${BUCKET}/${env_key} s3://${BUCKET}/${latest_key}
else
  if [ "${rollback_commit_hash}" == "" ]
    then
      echo "Current latest rails env file will be used for this deployment"
      aws s3 cp s3://${BUCKET}/${latest_key} s3://${BUCKET}/${env_key}
  else
    echo "Latest will be rolled back to ${rollback_commit_hash}"
    aws s3 cp s3://${BUCKET}/${env_key} s3://${BUCKET}/${latest_key}
  fi
fi
