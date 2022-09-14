begin
    ITEM_STATUS_CODES = YAML.load_file(Rails.root.join("config","item_status_codes.yml"), aliases: true)
rescue ArgumentError
    ITEM_STATUS_CODES = YAML.load_file(Rails.root.join("config","item_status_codes.yml"))
end