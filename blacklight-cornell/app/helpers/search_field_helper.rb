module SearchFieldHelper

# Looks up a search field blacklight_config hash from search_field_list having
  # a certain supplied :key.
  def search_field_def_for_key(key)
      blacklight_config.search_fields[key] ?
      blacklight_config.search_fields[key] :
      blacklight_config.default_search_field
  end

  # Returns default search field, used for simpler display in history, etc.
  # if not set in blacklight_config, defaults to first field listed in #search_field_list
  def default_search_field
    blacklight_config.default_search_field || search_field_list.first
  end

  # Shortcut for commonly needed operation, look up display
  # label for the key specified. Returns "Keyword" if a label
  # can't be found.
  def label_for_search_field(key)
    field_def = search_field_def_for_key(key)
    if field_def && field_def.label
       field_def.label
    else
       I18n.t('blacklight.search.fields.default')
    end
  end
end
