# frozen_string_literal: true

# Breaks Blacklight's single-line Solr query log message across lines, for
# development only.
class SolrQueryPrettyPrinter
  # 'Solr query: get select {"qt" => "search", ...}'
  MESSAGE = /\A(Solr query:[^{]*)(\{.*\})\s*\z/m

  INDENT = '     '
  # A container wider than this gets one entry per line; anything narrower is
  # left alone, so short arrays don't cost three lines to say one thing.
  MAX_WIDTH = 100
  MAX_LINES = 120

  OPENERS = { '[' => ']', '{' => '}' }.freeze

  # @return [Array<String>, nil] one entry per output line, or nil to leave the
  #   original message alone
  def self.call(message)
    new(message).call
  end

  def initialize(message)
    @message = message.to_s
  end

  def call
    match = @message.match(MESSAGE)
    return nil unless match

    entries = split_top_level(inside(match[2]))
    return nil if entries.empty?

    ["#{match[1].rstrip} {", *cap(render_entries(entries, INDENT.length)), '}']
  end

  private

  # Renders the entries of a hash, each indented one level and comma-separated.
  # @return [Array<String>] lines relative to the enclosing construct's left edge
  def render_entries(entries, indent)
    render_elements(entries, indent) { |entry| render_entry(entry, indent + INDENT.length) }
  end

  def render_elements(elements, indent)
    elements.each_with_index.flat_map do |element, index|
      lines = yield(element).map { |line| INDENT + line }
      lines[-1] += ',' unless index == elements.length - 1
      lines
    end
  end

  # One `"key" => value` entry. Kept on one line whenever it fits, so only the
  # genuinely long parameters are restructured.
  # @return [Array<String>] lines relative to the entry's own left edge
  def render_entry(entry, indent)
    return [entry] if indent + entry.length <= MAX_WIDTH

    key, separator, value = split_pair(entry)
    return [entry] unless key

    # The value's own continuation lines are already relative to the key's left
    # edge -- the closing bracket lines up under the key, JSON style.
    value_lines = render_value(value, indent + key.length + separator.length)
    ["#{key}#{separator}#{value_lines.first}", *value_lines.drop(1)]
  end

  # @param indent [Integer] the column the value starts at, used to decide
  #   whether it still fits on one line
  # @return [Array<String>] lines relative to the value's left edge
  def render_value(value, indent)
    elements = container_elements(value)
    return [value] if elements.nil? || elements.empty?
    return [value] if indent + value.length <= MAX_WIDTH

    # A hash's elements are `key => value` entries, not bare values; sending them
    # through the value renderer would leave a long nested hash unexpanded.
    body = if value.start_with?('{')
             render_entries(elements, indent)
           else
             render_elements(elements, indent) { |element| render_value(element, indent + INDENT.length) }
           end

    [value[0], *body, value[-1]]
  end

  # @return [Array<String>, nil] the top-level entries if value is an array or
  #   hash literal, otherwise nil
  def container_elements(value)
    closer = OPENERS[value[0]]
    return nil unless closer && value.end_with?(closer)

    split_top_level(inside(value))
  end

  def inside(literal)
    literal.strip[1..-2].to_s
  end

  # Splits on commas that are at nesting depth zero and outside a string.
  def split_top_level(text)
    parts = []
    current = +''
    scan(text) do |char, top_level|
      if top_level && char == ','
        parts << current.strip
        current = +''
      else
        current << char
      end
    end
    parts << current.strip
    parts.reject(&:empty?)
  end

  # Ruby renders string keys as `"k" => v` and symbol keys as `k: v`; Solr
  # parameter hashes contain both.
  # @return [Array(String, String, String), nil] key, separator, value
  def split_pair(pair)
    index = nil
    scan(pair) do |_char, top_level, position|
      index ||= position if top_level && pair[position, 4] == ' => '
    end

    return [pair[0...index], ' => ', pair[(index + 4)..].strip] if index

    match = pair.match(/\A([A-Za-z_][\w.]*): (.*)\z/m)
    match && [match[1], ': ', match[2].strip]
  end

  # Yields each character with whether it sits at the top level (depth zero and
  # not inside a string).
  def scan(text)
    depth = 0
    in_string = false
    escaped = false

    text.each_char.with_index do |char, position|
      if escaped
        escaped = false
      elsif char == '\\'
        escaped = true
      elsif char == '"'
        in_string = !in_string
      elsif !in_string
        depth += 1 if '[{('.include?(char)
        depth -= 1 if ']})'.include?(char)
      end

      yield char, (!in_string && depth.zero?), position
    end
  end

  def cap(lines)
    return lines if lines.length <= MAX_LINES

    lines.first(MAX_LINES) << "#{INDENT}… #{lines.length - MAX_LINES} more line(s)"
  end
end
