yaml_file = File.join(Rails.root, 'config', 'eds.yml')
if File.exists? yaml_file
  profiles = YAML.load_file(yaml_file)
  if profiles.present? and profiles.has_key? Rails.env
    Rails.application.config.eds_profiles = profiles[Rails.env]
  else
    Rails.logger.info "No configuration found for #{Rails.env} environment in config/eds.yml"
  end
else
  Rails.logger.info 'File not found: config/eds.yml'
end