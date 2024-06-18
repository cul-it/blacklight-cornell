module CornellBlacklightHelper extend BlacklightHelper

  def placeholder_text(field_def)
    field_def.respond_to?(:placeholder_text) ? field_def.placeholder_text : t('blacklight.search.form.search.placeholder')
  end

  def search_bar_select
    blacklight_config.search_fields.collect do |_key, field_def|
      [field_def.dropdown_label || field_def.label, field_def.key, { 'data-placeholder' => placeholder_text(field_def) }] if should_render_field?(field_def)
    end.compact
  end

end