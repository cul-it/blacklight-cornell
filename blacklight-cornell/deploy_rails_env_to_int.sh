#!/usr/bin/env bash


BUCKET='container-discovery'
img_id=$(git rev-parse head)


env_key="container_env_${img_id}"

# this will only work on the integration server

aws s3 cp s3://${BUCKET}/${env_key} /cul/web/catalog-int.library.cornell.edu/rails-app/shared/.env