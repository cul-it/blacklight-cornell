#!/usr/bin/env ruby

# frozen_string_literal: true

require 'aws-sdk-s3'
require 'optparse'

# It is assumed that the AWS credentials are stored in the credentials file.

# Create an S3 client
s3 = Aws::S3::Client.new

# Specify the bucket name
bucket = 'container-discovery'
key = 'alerts/alerts.yml'

# Parse command line options
options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: manage_yaml_alerts.rb [options]'

  opts.on('-f', '--file YAML_FILE_PATH', 'Path to the yaml file to upload') do |file_path|
    options[:file_path] = file_path
  end

  opts.on('-d', '--delete', 'Delete the alerts file') do
    options[:delete] = true
  end
end.parse!

if options[:delete]
  # Delete the file from S3
  s3.delete_object(bucket:, key:)
elsif options[:file_path]
  # Upload the file to S3
  File.open(options[:file_path], 'rb') do |file|
    s3.put_object(bucket:, key:, body: file)
  end
else
  puts 'manage_yaml_alerts.rb [-d to delete yaml file] [-f YAML_FILE_PATH to upload yaml file]'
end
