module RecordMailerHelper

  # Return html for a given field in email body
  def render_email_field(semantics, field)
    label = "blacklight.email.text.#{field}"
    value = semantics[field.to_sym]
    return "" unless value.present?

    text = I18n.t(label, :value => value.join("; "))
    "<p>#{text}</p>".html_safe
  end

end