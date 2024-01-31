#!/usr/bin/env ruby

# frozen_string_literal: true

require 'aws-sdk-s3'

# It is assumed that the AWS credentials are stored in the credentials file.
#
# For more information, see:
# https://docs.aws.amazon.com/sdk-for-ruby/v3/developer-guide/setup-config.html
#

# Create an S3 client
s3_client = Aws::S3::Client.new

# Specify the bucket and object key
bucket = 'container-discovery'
key = 'alerts/alerts.yml'
alerts_path = File.join(File.dirname(__FILE__), '..', 'alerts.yml')
puts alerts_path

def s3_exists?(s3_client:, bucket:, key:)
  s3_client.head_object(bucket:, key:)
  true
rescue Aws::S3::Errors::NotFound
  false
end

# Check if the file exists in S3
if s3_exists?(s3_client:, bucket:, key:)
  # Download the file
  File.open(alerts_path, 'wb') do |file|
    s3_client.get_object(bucket:, key:) do |chunk|
      file.write(chunk)
    end
  end
else
  puts 'No alerts found'
  FileUtils.rm_rf(alerts_path)
end
