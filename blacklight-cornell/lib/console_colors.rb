# :nocov:
module ConsoleColors
  ##########################################
  ## DEFINED COLORS TO USE ON CONSOLE LOG ##
  ##########################################
  CLR = {
    stop: "\e[0m",
    bld: "\e[1m",
    txt: {
      black:  "\e[30m", red:   "\e[31m", green:   "\e[32m",
      yellow: "\e[33m", blue:  "\e[34m", magenta: "\e[35m",
      cyan:   "\e[36m", white: "\e[37m"
    },
    bg: {
      black:  "\e[40m", red:   "\e[41m", green:   "\e[42m",
      yellow: "\e[43m", blue:  "\e[44m", magenta: "\e[45m",
      cyan:   "\e[46m", white: "\e[47m"
    }
  }

  ##############################################################################
  ## COLOR CONSOLE LOG METHODS ##
  ###############################
  # =========================================================
  # Prints a colored line for console log. The color of the
  # line can be customized. If a background color is provided,
  # the line will have that background color.
  # ---------------------------------------------------------
  def print_colored_line(width: 80, color: :white, bg_color: nil, marked: false)
    mark = if marked
             (Rails.env.production? || Rails.env.test?) ? "# " : "#{CLR[:txt][color]}#{CLR[:bld]}# #{CLR[:stop]}"
           else
             ""
           end
    line_color = "#{CLR[:txt][color]}#{CLR[:bld]}"

    if Rails.env.production? || Rails.env.test?
      puts "#{mark}#{"-" * width}"
    else
      if bg_color
        puts "#{mark}#{line_color}#{CLR[:bg][bg_color]}#{"-" * width}#{CLR[:stop]}"
      else
        puts "#{mark}#{line_color}#{"-" * width}#{CLR[:stop]}"
      end
    end
  end

  # ==================================================================
  # Prints a centered colored msg for console log. The msg text,
  # text color, and background color can all be customized.
  # The msg is surrounded by lines for emphasis.
  # ------------------------------------------------------------------
  def print_header(msg:, color: :white, bg_color: :blue)
    num_hashes = (80 - msg.length - 2) / 2
    extra_hash = msg.length.even? ? 0 : 1

    if Rails.env.production? || Rails.env.test?
      puts "#{'#' * num_hashes} #{msg} #{'#' * (num_hashes + extra_hash)}"
    else
      puts "#{CLR[:txt][color]}#{CLR[:bld]}#{CLR[:bg][bg_color]}#{"-" * 80}#{CLR[:stop]}"
      puts "#{CLR[:txt][color]}#{CLR[:bld]}#{CLR[:bg][bg_color]}#{'#' * num_hashes} #{msg} #{'#' * (num_hashes + extra_hash)}#{CLR[:stop]}"
      puts "#{CLR[:txt][color]}#{CLR[:bld]}#{CLR[:bg][bg_color]}#{"-" * 80}#{CLR[:stop]}"
    end
  end

  def debug(var, description, color = :white, bg_color = :yellow, width = 80)
    num_hashes = (width - description.length - 2) / 2
    if description.length % 2 == 0
      extra_hash = 0
    else
      extra_hash = 1
    end
    puts "#{CLR[:txt][color]}#{CLR[:bld]}#{CLR[:bg][bg_color]}#{"-" * width}#{CLR[:stop]}"
    puts "#{CLR[:txt][color]}#{CLR[:bld]}#{CLR[:bg][bg_color]}#{'#' * num_hashes} #{description} #{'#' * (num_hashes + extra_hash)}#{CLR[:stop]}"
    puts "#{CLR[:txt][color]}#{CLR[:bld]}#{CLR[:bg][bg_color]}#{"-" * width}#{CLR[:stop]}"

    # =======================
    # Wraps text to set width
    # -----------------------
    wrapped_inspect = var.inspect.scan(/.{1,#{width}}/)
    wrapped_inspect.each do |line|
      bg_clr = :blue
      puts "#{CLR[:txt][:white]}#{CLR[:bld]}#{CLR[:bg][bg_clr]}#{line}#{CLR[:stop]}"
    end
    print_colored_line(width: width, color: :white, bg_color: :yellow)
  end

  # ============================================================
  # Prints a colored message for console log. The message text
  # and color can be customized. This is useful for highlighting
  # important information in the console log.
  # ------------------------------------------------------------
  def print_colored_message(msg:, color: :white, marked: true)
    mark = if marked
             (Rails.env.production? || Rails.env.test?) ? "#" : "#{CLR[:txt][color]}#{CLR[:bld]}# #{CLR[:stop]}"
           else
             ""
           end

    if Rails.env.production? || Rails.env.test?
      puts "#{mark} #{msg}"
    else
      puts "#{mark}#{CLR[:txt][color]}#{CLR[:bld]}#{msg}#{CLR[:stop]}"
    end
  end

  # ===============================
  # quick error and success methods
  # -------------------------------
  def error_msg(e)
    caller_info = caller_locations(1, 1).first
    file = caller_info.path
    line = caller_info.lineno
    method = caller_info.base_label

    print_colored_message(
      msg: "==> #{e}: File: #{file} — Line: #{line} — Method: ##{method}",
      color: :red,
      marked: false
    )
  end

  def success_msg(e)
    print_colored_message(
      msg: "==> #{e}",
      color: :green,
      marked: false
    )
  end

  def info_msg(e)
    caller_info = caller_locations(1, 1).first
    method = caller_info&.base_label.to_s

    if method.include?("<top")
      print_colored_message(
        msg: "==> #{e}",
        color: :blue,
        marked: false
      )
    else
      print_colored_message(
        msg: "==> #{e} — Method: ##{method}",
        color: :blue,
        marked: false
      )
    end
  end
  def alert_msg(e)
    # Get the first caller outside of this file
    caller_info = caller_locations(1, 1).first
    file = caller_info.path
    line = caller_info.lineno
    method = caller_info.base_label

    print_top_line
    print_colored_message(
      msg: "==> #{e}: File: #{file} — Line: #{line} — Method: ##{method}",
      color: :magenta,
      marked: false
    )
    print_bottom_line
  end

  def print_top_line
    line_space
    print_colored_line(color: :magenta)
  end

  def print_bottom_line
    print_colored_line(color: :magenta)
    line_space
  end

  def line_space
    puts ""
  end

  # ================================================================
  # Prints a colored announcement for console log. The announcement
  # text and color can be customized. The announcement is surrounded
  # by lines for emphasis, making it stand out in the console log.
  # ----------------------------------------------------------------
  def print_colored_announcement(msg:, color: :white)
    if Rails.env.production? || Rails.env.test?
      puts "#{'-' * 80}\n#{msg}\n#{'-' * 80}"
    else
      print_colored_line(color: color)
      puts "#{CLR[:txt][color]}#{CLR[:bld]}#{msg}#{CLR[:stop]}"
      print_colored_line(color: color)
    end
  end

  # ================================================================
  # Prints a row with colored text and background for console log.
  # The values, spacings between values, text color, and background
  # color can all be customized. This is useful for printing table
  # data in the console log.
  # ----------------------------------------------------------------
  def print_row(values:, spacings:, color: :white, bg_color: :blue)
    format_string = values.zip(spacings).map { |_, spacing| "%-#{spacing}s" }.join(' ')

    if Rails.env.production? || Rails.env.test?
      printf("#{format_string}\n", *values)
    else
      printf("#{CLR[:txt][color]}#{CLR[:bld]}#{CLR[:bg][bg_color]}#{format_string}\n", *values)
    end
  end
end
# :nocov:
