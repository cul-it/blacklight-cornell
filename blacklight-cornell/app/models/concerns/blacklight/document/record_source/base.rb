# frozen_string_literal: true

module Blacklight::Document::RecordSource::Base
  # Extend including modules with record-source class helpers.
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    # Wrap export_ methods so the matching record source handles them.
    def apply_export_guard(record_source)
      guard_key = record_source.to_s.gsub(/\W/, "_")
      export_methods = instance_methods(false)
      if included_modules.include?(Blacklight::Document::RecordSource::Base)
        export_methods += Blacklight::Document::RecordSource::Base.instance_methods(false)
      end
      export_methods.uniq.grep(/\Aexport_/).each do |name|
        guarded = "__#{guard_key}_#{name}"
        next if method_defined?(guarded)
        alias_method guarded, name
        define_method(name) do |*args, **kwargs, &block|
          return super(*args, **kwargs, &block) unless public_send(record_source)
          send(guarded, *args, **kwargs, &block)
        end
      end
    end
  end

  # Return the first format value for exports.
  def export_format
    value = self["format"]
    value.is_a?(Array) ? value.first : value
  end

  # Check if the record is labeled as online.
  def export_online?
    online = self["online"]
    online.is_a?(Array) ? online.first == "Online" : online == "Online"
  end

  # Expose the first access URL suitable for exports.
  def export_access_url
    access_url_first_filtered(self)
  end

  # Build a catalog URL when an id is present.
  def export_catalog_url
    return unless self["id"].present?

    "http://catalog.library.cornell.edu/catalog/#{self['id']}"
  end

  # Load and cache holdings data shared across export formats.
  def export_holdings
    @export_holdings ||= setup_holdings_info(self)
  end

  # Join holdings lines into a single string when present.
  def export_holdings_string(separator:)
    holdings = export_holdings
    return if holdings.blank? || holdings.join("").blank?

    holdings.join(separator)
  end

  # Pull language values from the shared language facet.
  def export_languages
    field_values(%w[language_facet])
  end

  private

  # Collect values from Solr fields, flattening arrays.
  def field_values(keys)
    keys.flat_map do |key|
      value = self[key]
      value.is_a?(Array) ? value : [value]
    end.flatten.compact
  end

  # Return the first non-blank value across the given fields.
  def first_present_value(keys)
    field_values(keys).find { |value| value.present? }
  end

  # Strip trailing punctuation from text values.
  def clean_end_punctuation(text)
    text = "" if text.nil?
    if [".", ",", ":", ";", "/"].include?(text[-1, 1])
      return text[0, text.length - 1]
    end
    text
  end
end
