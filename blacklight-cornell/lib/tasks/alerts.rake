# frozen_string_literal: true

require 'aws-sdk-s3'

namespace :alerts do
  desc 'Check for alerts from S3 for this environment and deploy if necessary'
  task :fetch do
    # Create an S3 client
    s3_client = Aws::S3::Client.new
    # Specify the bucket and object key
    bucket = 'container-discovery'
    key = "alerts/yaml_alerts_#{ENV.fetch('RAILS_ENV', 'production')}.yml"
    alerts_path = File.join(Rails.root, 'alerts.yml')

    begin
      # Check if the file exists in S3
      s3_client.head_object(bucket:, key:)
      # Download the file
      File.open(alerts_path, 'wb') do |file|
        s3_client.get_object(bucket:, key:) do |chunk|
          file.write(chunk)
        end
        puts "Downloaded yaml alerts to #{alerts_path}"
      end
    rescue Aws::S3::Errors::NotFound
      if File.exist?(alerts_path)
        FileUtils.rm(alerts_path)
        puts "Deleted yaml alerts at #{alerts_path}"
      end
    end
  end
end
