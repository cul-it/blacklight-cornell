require 'pp'
# :nocov:
  module LoggingHelper
    # ==========================================================================
    # temporarily set log level to debug, log message, then reset the log level
    # --------------------------------------------------------------------------
    # Useage: (in a controller) "include LoggingHelper"
    #
    #   log_debug_info(
    #     "#{__FILE__}:#{__LINE__}",
    #     ["ok:", ok],
    #     ["shash:", shash],
    #     "skey: #{skey}",
    #     "sdef: #{sdef}"
    #   )
    # --------------------------------------------------------------------------
    def log_debug_info(context, *info)
      original_level = Rails.logger.level
      Rails.logger.level = Logger::INFO
      log_message = PP.pp(["ZZZ #{context}", info], "")
      Rails.logger.info(log_message)
    ensure
      Rails.logger.level = original_level
    end
  end
# :nocov: