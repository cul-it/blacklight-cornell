module TouHelper
  # Returns a display string for a TOU value field that could be a hash, a single value, or an array of hashes
  def tou_display_value(val)
    case val
    when Array
      # Join all 'label' fields if present, else 'value', separated by semicolons
      val.map { |v|
        if v.is_a?(Hash)
          v['label'] || v['value']
        else
          v.to_s
        end
      }.join('; ')
    when Hash
      val['label'] || val['value'] || val.to_s
    else
      val.to_s
    end
  end
end