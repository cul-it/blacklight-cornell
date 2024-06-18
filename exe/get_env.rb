#!/usr/bin/env ruby

# frozen_string_literal: true

require 'aws-sdk-s3'

version = ARGV[0]
target = ARGV[1]
BUCKET = 'container-discovery'
ENV_KEY = "container_env_#{version}".freeze

client = Aws::S3::Client.new
puts ENV_KEY
client.get_object({ bucket: BUCKET, key: ENV_KEY }, target:)
