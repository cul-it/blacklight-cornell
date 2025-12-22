################################################################################
##  ⚠️ Server requires restart after code changes to this helper         #######
## TODO: Jira Ticket: https://culibrary.atlassian.net/browse/DACCESS-791 #######
################################################################################

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

  # ============================================================================
  # Returns true in DEBUG_USER is set and in development ot test environments
  # ----------------------------------------------------------------------------
  def developer_bookbag_enabled?
    ENV["DEBUG_USER"].present? && (Rails.env.development? || Rails.env.test?)
  end
end