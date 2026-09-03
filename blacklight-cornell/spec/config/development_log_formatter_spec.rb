# frozen_string_literal: true

require 'rails_helper'
# Only config/environments/development.rb requires this, so the test env has to
# ask for it explicitly.
require_relative '../../config/development_log_formatter'

RSpec.describe DevelopmentLogFormatter do
  subject(:formatter) { described_class.new }

  # The formatter carries per-request state on the thread; make each example
  # start from a clean one.
  before { Thread.current[described_class::MCP_FLAG] = nil }
  after  { Thread.current[described_class::MCP_FLAG] = nil }

  # FORMAT_SOLR_QUERY is a real env var a developer may well have set in their
  # env file, and dotenv loads it here too. Clear it for every example so these
  # specs describe the code rather than the machine they run on; the examples
  # that care about it set it explicitly through #with_flag.
  around do |example|
    original = ENV['FORMAT_SOLR_QUERY']
    ENV['FORMAT_SOLR_QUERY'] = nil
    example.run
    ENV['FORMAT_SOLR_QUERY'] = original
  end

  def with_flag(value)
    original = ENV['FORMAT_SOLR_QUERY']
    ENV['FORMAT_SOLR_QUERY'] = value
    yield
  ensure
    ENV['FORMAT_SOLR_QUERY'] = original
  end

  def format(message, severity: 'INFO')
    formatter.call(severity, Time.zone.now, nil, message)
  end

  # Formatted output is ANSI-wrapped; these make the assertions readable.
  def badged?(line)
    line.start_with?(described_class::MCP_BADGE)
  end

  def strip_ansi(line)
    line.gsub(/\e\[[0-9;]*m/, '')
  end

  def strip_badge(line)
    line.sub(described_class::MCP_BADGE, '')
  end

  def strip_badges(text)
    text.gsub(described_class::MCP_BADGE, '')
  end

  MCP_START = 'Started POST "/mcp" for 192.168.65.1 at 2026-08-31 17:00:09 +0000'
  MCP_PROCESSING = 'Processing by McpController#handle as JSON'
  CATALOG_START = 'Started GET "/catalog?q=test" for 192.168.65.1 at 2026-08-31 17:00:09 +0000'

  describe 'badging MCP traffic' do
    it 'badges the request line' do
      expect(badged?(format(MCP_START))).to be true
    end

    it 'badges every line of the request, not just the first' do
      format(MCP_START)

      expect(badged?(format(MCP_PROCESSING))).to be true
      expect(badged?(format('Solr query: get select {...}'))).to be true
      expect(badged?(format('Solr fetch (12.0ms)'))).to be true
    end

    # The Completed line names no path, so it can only be attributed by tracking
    # the request it belongs to.
    it 'badges the completion line, which carries no path of its own' do
      format(MCP_START)
      expect(badged?(format('Completed 200 OK in 684ms'))).to be true
    end

    it 'badges the summary lines McpController logs itself' do
      expect(badged?(format('[MCP] tools/call search {"query":"Stephen King"}'))).to be true
    end

    it 'badges a line that already carries its own colours, without recolouring it' do
      format(MCP_START)
      line = format("\e[1mSolr query\e[0m")

      expect(badged?(line)).to be true
      expect(line).to include("\e[1mSolr query\e[0m")
    end

    it 'gives the MCP hue to the lines about the exchange itself' do
      expect(format(MCP_START)).to include(described_class::COLORS[:mcp])
      expect(format(MCP_PROCESSING)).to include(described_class::COLORS[:mcp])
      # The jsonrpc envelope itself is dropped; any other Parameters line is not.
      expect(format('  Parameters: {"something" => "else"}')).to include(described_class::COLORS[:mcp])
      expect(format('[MCP] tools/call search {}')).to include(described_class::COLORS[:mcp])
    end

    # The badge already says whose request it is, so the colour stays free to
    # say what kind of line it is. A Solr query inside an MCP request should be
    # visually identical to one from a browser request.
    describe 'lines that merely happen inside an MCP request' do
      before { format(MCP_START) }

      it 'colours Solr queries exactly as they are coloured anywhere else' do
        query = 'Solr query: get select {"qt" => "search", "rows" => 10}'

        mcp_line = strip_badge(format(query, severity: 'DEBUG'))
        Thread.current[described_class::MCP_FLAG] = nil
        plain_line = format(query, severity: 'DEBUG')

        expect(mcp_line).to eq(plain_line)
        expect(mcp_line).to include(described_class::COLORS[:debug])
      end

      it 'colours Solr fetch timings the same way' do
        mcp_line = strip_badge(format('Solr fetch (641.0ms)', severity: 'DEBUG'))
        Thread.current[described_class::MCP_FLAG] = nil

        expect(mcp_line).to eq(format('Solr fetch (641.0ms)', severity: 'DEBUG'))
      end

      # Otherwise a failing tool call would hide inside a uniformly coloured block.
      it 'keeps the completion line on its status colour' do
        expect(format('Completed 500 Internal Server Error in 4ms')).to include(described_class::COLORS[:fatal])

        format(MCP_START)
        expect(format('Completed 405 Method Not Allowed in 3ms')).to include(described_class::COLORS[:yellow])

        format(MCP_START)
        expect(format('Completed 200 OK in 684ms')).to include(described_class::COLORS[:green])
      end

      it 'still badges all of them' do
        expect(badged?(format('Solr fetch (641.0ms)', severity: 'DEBUG'))).to be true
        expect(badged?(format('Completed 200 OK in 684ms'))).to be true
      end
    end
  end

  describe 'multi-line messages' do
    let(:summary) do
      "[MCP] #14 tools/call advanced_search\n" \
        "  rows:     [1] query=\"Stephen King\"  field=author\n" \
        "            [2] query=cats  field=subject\n" \
        "  sort:     year ascending"
    end

    it 'badges every physical line so the gutter is unbroken' do
      lines = format(summary).lines

      expect(lines.length).to eq(4)
      expect(lines).to all(satisfy { |line| badged?(line) })
    end

    it 'opens and closes the colour on each line, so it never bleeds across a newline' do
      format(summary).lines.each do |line|
        expect(line).to include(described_class::COLORS[:mcp])
        expect(line).to end_with("#{described_class::RESET}\n")
      end
    end

    it 'colours the whole block from its first line, not line by line' do
      # The continuation lines match none of the lifecycle patterns on their own;
      # they should still take the MCP hue rather than the severity fallback.
      expect(format(summary).lines.last).to include(described_class::COLORS[:mcp])
    end

    it 'preserves the alignment of the original text' do
      expect(strip_ansi(strip_badges(format(summary)))).to eq("#{summary}\n")
    end
  end

  describe 'the raw JSON-RPC envelope' do
    # McpController re-logs the same content immediately after, aligned and
    # readable, so the raw line is duplication -- and it is the unreadable one.
    it 'is dropped inside an MCP request' do
      format(MCP_START)

      expect(format('  Parameters: {"jsonrpc" => "2.0", "id" => 14, "method" => "tools/call"}')).to eq('')
    end

    it 'is kept when it is not that envelope, so an unexpected shape still shows up' do
      format(MCP_START)

      expect(format('  Parameters: {"something" => "else"}')).not_to be_empty
    end

    it 'is kept for ordinary requests' do
      format(CATALOG_START)

      expect(format('  Parameters: {"q" => "test"}')).not_to be_empty
    end

    it 'does not disturb the badge state of the lines around it' do
      format(MCP_START)
      format('  Parameters: {"jsonrpc" => "2.0"}')

      expect(badged?(format('Completed 200 OK in 684ms'))).to be true
    end
  end

  describe 'leaving other traffic alone' do
    it 'does not badge ordinary catalog requests' do
      expect(badged?(format(CATALOG_START))).to be false
      expect(badged?(format('Processing by CatalogController#index as HTML'))).to be false
      expect(badged?(format('Completed 200 OK in 2116ms'))).to be false
    end

    it 'keeps the existing colours for non-MCP lines' do
      expect(format(CATALOG_START)).to include(described_class::COLORS[:bold_blue])
      expect(format('Completed 200 OK in 12ms')).to include(described_class::COLORS[:green])
    end

    it 'does not badge a path that merely starts with the same letters' do
      expect(badged?(format('Started GET "/mcpanything" for 127.0.0.1 at 2026-08-31 17:00:09 +0000'))).to be false
    end

    it 'stops badging once an MCP request completes' do
      format(MCP_START)
      format('Completed 200 OK in 684ms')

      expect(badged?(format('Cache fetch_hit: something'))).to be false
    end

    # Puma reuses threads. If an MCP request dies before its Completed line, the
    # next request on that thread must not inherit the badge.
    it 'clears the flag on the next request even if the MCP one never completed' do
      format(MCP_START)
      expect(badged?(format(CATALOG_START))).to be false
      expect(badged?(format('Processing by CatalogController#index as HTML'))).to be false
    end
  end

  describe 'FORMAT_SOLR_QUERY' do
    SOLR_LINE = 'Solr query: get select {"qt" => "search", "rows" => 20, "fq" => ["a", "b"]}'

    def solr_lines(value)
      with_flag(value) { format(SOLR_LINE, severity: 'DEBUG').lines }
    end

    context 'when it is off' do
      it 'leaves the Solr query on one line' do
        expect(solr_lines(nil).length).to eq(1)
      end
    end

    context 'when it is on' do
      it 'breaks the query out one parameter per line, keeping the literal structure' do
        lines = solr_lines('true').map { |line| strip_ansi(line).chomp }

        expect(lines.first).to eq('Solr query: get select {')
        expect(lines).to include('     "qt" => "search",')
        expect(lines.last).to eq('}')
      end

      it 'keeps the standard Solr colour on every expanded line' do
        solr_lines('true').each { |line| expect(line).to include(described_class::COLORS[:debug]) }
      end

      it 'badges every expanded line when the query runs inside an MCP request' do
        format(MCP_START)
        lines = solr_lines('true')

        expect(lines.length).to be > 1
        expect(lines).to all(satisfy { |line| badged?(line) })
      end

      it 'keeps the original line when the message cannot be parsed' do
        unparseable = 'Solr query: get select'
        line = with_flag('true') { format(unparseable, severity: 'DEBUG') }

        expect(strip_ansi(line)).to eq("#{unparseable}\n")
      end

      it 'leaves other messages alone' do
        line = with_flag('true') { format('Solr fetch (641.0ms)', severity: 'DEBUG') }

        expect(line.lines.length).to eq(1)
      end
    end

    context 'accepted values' do
      %w[true TRUE 1 yes on].each do |value|
        it "treats #{value.inspect} as on" do
          expect(solr_lines(value).length).to be > 1
        end
      end

      ['false', '0', 'no', '', nil, 'maybe'].each do |value|
        it "treats #{value.inspect} as off" do
          expect(solr_lines(value).length).to eq(1)
        end
      end
    end
  end

  describe 'NO_COLOR' do
    around do |example|
      original = ENV['NO_COLOR']
      ENV['NO_COLOR'] = '1'
      example.run
      ENV['NO_COLOR'] = original
    end

    it 'still marks MCP lines, in plain text, so they stay greppable' do
      line = format(MCP_START)

      expect(line).to start_with(described_class::MCP_BADGE_PLAIN)
      expect(line).not_to include("\e[")
    end

    it 'does not double up on lines already tagged [MCP]' do
      line = format('[MCP] tools/call search {}')

      expect(strip_ansi(line)).to eq("[MCP] tools/call search {}\n")
    end

    it 'leaves other traffic untouched' do
      line = format(CATALOG_START)

      expect(line).to eq("#{CATALOG_START}\n")
    end
  end
end
