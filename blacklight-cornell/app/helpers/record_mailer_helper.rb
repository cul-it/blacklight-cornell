module RecordMailerHelper

  # Truncate title for SMS text to conform to 140-character (8-bit character) limit
  # Assumes @location, @callnumber, @tiny are supplied to the view
  def truncate_title(doc)
    other_length = 0
    from = 'FRM:' + ENV["SMTP_FROM"]
    other_length += from.length
    other_length += @location.length if @location
    other_length += @callnumber.length if @callnumber
    other_length += @tiny.length if @tiny
    other_length += 8 # padding

    if (doc.length + other_length > 140)
      doc[0..140-other_length] + '...'
    else
      doc
    end

  end

  # Return html for a given field in email body
  def render_email_field(semantics, field)
    label = "blacklight.email.text.#{field}"
    value = semantics[field.to_sym]
    return "" unless value.present?

    text = I18n.t(label, :value => value.join("; "))
    "<p>#{text}</p>".html_safe
  end

end