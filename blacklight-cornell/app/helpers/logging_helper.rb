require 'pp'

module LoggingHelper
  # temporarily set the log level to debug,
  # log the message,
  # then reset the log level
  # Useage:
  #  (in a controller)
  #  include LoggingHelper
  #
  #   log_debug_info("#{__FILE__}:#{__LINE__}",
  #         ["ok:", ok],
  #         ["shash:", shash],
  #         "skey: #{skey}",
  #          "sdef: #{sdef}")
  def log_debug_info(context, *info)
    original_level = Rails.logger.level
    Rails.logger.level = Logger::INFO
    # log_message = build_log_message(context, info)
    log_message = PP.pp(["ZZZ #{context}", info], "")
    Rails.logger.info(log_message)
  ensure
    Rails.logger.level = original_level
  end

  private

  def build_log_message(context, info)
    msg = [" Debugging Info ".center(60, "Z")]
    msg << "ZZZ #{context}:"
    info.each { |i| msg << "ZZZ " + i.pretty_inspect }
    msg << "Z" * 60
    msg.join("\n")
  end
end
