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
end