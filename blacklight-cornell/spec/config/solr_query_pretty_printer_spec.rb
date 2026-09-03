# frozen_string_literal: true

require 'rails_helper'
require_relative '../../config/solr_query_pretty_printer'

RSpec.describe SolrQueryPrettyPrinter do
  # Blacklight logs `solr_params.to_hash.inspect`, so this is the exact shape the
  # printer has to read back. Ruby renders string keys as `"k" => v` and symbol
  # keys as `k: v`, and real Solr parameter hashes contain both.
  let(:message) do
    'Solr query: get select {"qt" => "search", "rows" => 20, ' \
      '"q" => "((author:\"Stephen\" AND author:\"King\") NOT (subject:\"cats\"))", ' \
      '"fq" => ["{!lucene}{!query v=$f_inclusive.format.0} OR {!query v=$f_inclusive.format.1}", ' \
      '"pub_date_facet:[1984 TO 1999]", "{!term f=language_facet}Spanish"], ' \
      '"stats.field" => ["pub_date_facet"], "facet" => true}'
  end

  subject(:lines) { described_class.call(message) }

  describe 'the overall shape' do
    it 'opens the hash on the message line and closes it on its own' do
      expect(lines.first).to eq('Solr query: get select {')
      expect(lines.last).to eq('}')
    end

    it 'indents each parameter and separates them with commas' do
      expect(lines).to include('     "qt" => "search",')
      expect(lines).to include('     "rows" => 20,')
    end

    it 'leaves the last parameter without a trailing comma' do
      expect(lines).to include('     "facet" => true')
      expect(lines.grep(/"facet" => true,/)).to be_empty
    end
  end

  # The whole point of the rewrite: the literal structure stays visible.
  describe 'preserving the literal' do
    it 'inserts newlines and indentation and changes nothing else' do
      expect(lines.join.gsub(/\s+/, '')).to eq(message.gsub(/\s+/, ''))
    end

    it 'keeps quotes and escapes on values exactly as Ruby wrote them' do
      expect(lines).to include('     "q" => "((author:\"Stephen\" AND author:\"King\") NOT (subject:\"cats\"))",')
    end

    it 'keeps the brackets around an expanded array' do
      expect(lines).to include('     "fq" => [')
      expect(lines).to include('     ],')
    end

    it 'keeps the quotes on each element of an expanded array' do
      expect(lines).to include('          "pub_date_facet:[1984 TO 1999]",')
      expect(lines).to include('          "{!term f=language_facet}Spanish"')
    end
  end

  describe 'deciding what to expand' do
    it 'gives each element its own line when the array is too wide for one' do
      expect(lines.grep(/\A {10}"/).length).to eq(3)
    end

    it 'leaves a short array inline, so it does not cost three lines to say one thing' do
      expect(lines).to include('     "stats.field" => ["pub_date_facet"],')
    end

    it 'leaves a long scalar alone -- there is nothing to break it on' do
      long = %(Solr query: get select {"q" => "#{'a' * 200}"})
      expect(described_class.call("#{long}}").grep(/\A {5}"q" =>/).length).to eq(1)
    end

    it 'expands a nested container inside an expanded one' do
      nested = 'Solr query: get select {"json" => {"facet" => {"formats" => ' \
               "\"#{'x' * 120}\", \"languages\" => \"#{'y' * 120}\"}}}"
      out = described_class.call(nested)

      expect(out).to include('     "json" => {')
      expect(out).to include('          "facet" => {')
      expect(out.grep(/\A {15}"formats" =>/).length).to eq(1)
    end
  end

  describe 'reading the inspect output correctly' do
    def parameters(hash_literal)
      described_class.call("Solr query: get select #{hash_literal}").grep(/\A {5}\S/)
    end

    it 'does not split on a comma inside a quoted value' do
      long = 'pub_date_sort asc, title_sort asc, author_sort asc, callnum_sort asc, acquired_dt desc, score desc'
      out = parameters(%({"sort" => "#{long}", "rows" => 20}))

      expect(out.length).to eq(2)
      expect(out.first).to include(long)
    end

    it 'does not split on a comma inside a nested array' do
      expect(parameters('{"facet.field" => ["a", "b"], "rows" => 1}').length).to eq(2)
    end

    it 'does not split on a => inside a quoted value' do
      expect(parameters('{"q" => "a => b", "rows" => 1}')).to include('     "q" => "a => b",')
    end

    it 'reads symbol keys as well as string keys' do
      out = parameters('{qt: "document", "id" => "12275844"}')

      expect(out).to include('     qt: "document",')
      expect(out).to include('     "id" => "12275844"')
    end

    it 'is not confused by braces inside a value' do
      long = "{!lucene}{!query v=$a} OR {!query v=$b} OR {!query v=$c} OR {!query v=$d} OR {!query v=$e} OR {!query v=$f}"
      out = parameters(%({"fq" => "#{long}", "rows" => 1}))

      expect(out.length).to eq(2)
      expect(out.first).to include(long)
    end
  end

  # A log pretty-printer must never lose the message.
  describe 'giving up safely' do
    it 'returns nil for a message that is not a Solr query' do
      expect(described_class.call('Completed 200 OK in 4ms')).to be_nil
      expect(described_class.call('Solr fetch (641.0ms)')).to be_nil
    end

    it 'returns nil when there is no hash to expand' do
      expect(described_class.call('Solr query: get select')).to be_nil
      expect(described_class.call('Solr query: get select {}')).to be_nil
    end

    it 'returns nil for an empty or nil message' do
      expect(described_class.call('')).to be_nil
      expect(described_class.call(nil)).to be_nil
    end
  end

  it 'caps a pathological number of lines' do
    huge = (1..300).map { |i| "\"field#{i}\" => #{i}" }.join(', ')
    out = described_class.call("Solr query: get select {#{huge}}")

    expect(out.length).to eq(described_class::MAX_LINES + 3) # opener + capped body + notice + closer
    expect(out[-2]).to match(/more line\(s\)/)
  end
end
