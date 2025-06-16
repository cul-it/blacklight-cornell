module ApplicationHelper
  # ============================================================================
  # Allows calls to ConsoleColors.debug if CONSOLE_COLORS_ENABLED=true to output
  # a debug message with color coding.
  # ----------------------------------------------------------------------------
  if ENV["CONSOLE_COLORS_ENABLED"] == "true"
    include ConsoleColors
    def debug_console(var, description)
      debug(var, description)
    end
  end

  def tooltip(title, content)
    id = title.parameterize
    debug(id, "id")
    link_to '#', id: id, data: {
      toggle: 'popover',
      trigger: 'hover',
      placement: 'bottom',
      html: true,
      title: title,
      content: "<p>#{content}</p>"
    } do
      content_tag(:i, '', class: 'fa fa-info-circle')
    end
  end

end