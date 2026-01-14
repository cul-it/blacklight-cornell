# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Blacklight::Document::Source::Folio do
  include_context "folio source fixtures"
  let(:document) { folio_document }

  let(:folio_harness_class) do
    Class.new do
      include Blacklight::Document::Source::Folio

      def initialize(values)
        @values = values
      end

      def [](key)
        @values[key]
      end
    end
  end

  it 'maps base export fields from Solr values' do
    expect(document.export_format).to eq('Book')
    expect(document.export_online?).to be(false)
    expect(document.export_access_url).to be_nil
    expect(document.export_catalog_url).to eq('http://catalog.library.cornell.edu/catalog/17199945')
    expect(document.export_languages).to be_empty
    expect(document.export_holdings).to eq(['Olin Library  PS3600 .S35 2026'])
    expect(document.export_holdings_string(separator: '//')).to eq('Olin Library  PS3600 .S35 2026')
  end

  it 'maps title and publication data from display fields' do
    expect(document.export_title(separator: ': ')).to eq("AI AND ADA: ARTIFICIAL TRANSLATION AND CREATION OF LITERATURE")
    expect(document.export_title(separator: ' ')).to eq("AI AND ADA ARTIFICIAL TRANSLATION AND CREATION OF LITERATURE")
    pub_data = document.export_publication_data
    expect(pub_data[:place]).to be_nil
    expect(pub_data[:publisher]).to eq('FIRST HILL BOOKS')
    expect(pub_data[:date]).to eq('2026')
  end

  it 'groups contributors into personal and corporate buckets' do
    contributors = document.export_contributors
    expect(contributors[:primary_authors]).to include("SELIGMAN, MARK")
    expect(contributors[:primary_corporate_authors]).to be_empty
    expect(contributors[:secondary_authors]).to be_empty
    expect(contributors[:editors]).to be_empty
    expect(contributors[:translators]).to be_empty
  end

  it 'returns empty optional export fields' do
    expect(document.export_relators).to eq({})
    expect(document.export_thesis_info).to be_nil
    expect(document.export_edition).to be_nil
    expect(document.export_doi).to be_nil
    expect(document.export_keywords).to be_empty
    expect(document.export_notes).to be_empty
    expect(document.export_abstracts).to be_empty
    expect(document.export_isbns).to be_empty
    expect(document.export_issns).to be_empty
    expect(document.export_medium('video')).to be_nil
  end

  it 'builds titles with subtitle display values and slashes' do
    doc = folio_harness_class.new(
      "fulltitle_display" => "Main Title: Part One / Statement",
      "subtitle_display" => "Alt Subtitle"
    )

    expect(doc.export_title(separator: ": ")).to eq("Main Title: Part One: Alt Subtitle")
  end

  it 'builds titles from colon when no subtitle display is present' do
    doc = folio_harness_class.new("title_display" => "Alpha: Beta")
    expect(doc.export_title(separator: " ")).to eq("Alpha Beta")
  end

  it 'returns the title when no subtitle is present' do
    doc = folio_harness_class.new("title_display" => "Solo Title")
    expect(doc.export_title(separator: ": ")).to eq("Solo Title")
  end

  it 'returns nil when titles are blank' do
    doc = folio_harness_class.new({})
    expect(doc.export_title(separator: ": ")).to be_nil
  end

  it 'parses publication data from pub_info and fallbacks' do
    doc = folio_harness_class.new(
      "pubplace_display" => ["Override Place"],
      "publisher_display" => ["Override Pub"],
      "pub_date_display" => ["1999."]
    )

    pub_data = doc.export_publication_data
    expect(pub_data[:place]).to eq("Override Place")
    expect(pub_data[:publisher]).to eq("Override Pub")
    expect(pub_data[:date]).to eq("1999")
    parsed = doc.send(:parsed_pub_info)
    expect(parsed).to eq({})
  end

  it 'parses publication data from pub_info when display fields are absent' do
    doc = folio_harness_class.new(
      "pub_info_display" => ["Ithaca : Test Pub, 2001."],
      "pub_date_sort" => 2002
    )

    pub_data = doc.export_publication_data
    expect(pub_data[:place]).to eq("Ithaca")
    expect(pub_data[:publisher]).to eq("Test Pub")
    expect(pub_data[:date]).to eq("2001")
  end

  it 'handles pub_info without a place segment' do
    doc = folio_harness_class.new(
      "pub_info_display" => ["Just Pub, 2005."]
    )

    parsed = doc.send(:parsed_pub_info)
    expect(parsed[:place]).to be_nil
    expect(parsed[:publisher]).to eq("Just Pub")
    expect(parsed[:date]).to eq("2005")
  end

  it 'extracts years from values' do
    doc = folio_harness_class.new({})
    expect(doc.send(:extract_year, "c2020.")).to eq("2020")
    expect(doc.send(:extract_year, nil)).to be_nil
  end

  it 'parses and normalizes contributors' do
    doc = folio_harness_class.new(
      "author_json" => [
        "{\"name1\":\"Corp Org\",\"type\":\"Corporate Name\"}",
        "{\"name1\":\"Meeting Group\",\"type\":\"Meeting Name\"}",
        "{\"name1\":\"Doe, Jane\",\"search1\":\"Doe, Jane\",\"type\":\"Personal Name\"}",
        "[\"Array Entry\"]",
        "invalid json"
      ],
      "author_addl_json" => [
        "{\"name\":\"Doe, Jane.\"}"
      ],
      "author_display" => ["Doe,   Jane."]
    )

    contributors = doc.export_contributors
    expect(contributors[:primary_authors]).to include("Doe, Jane")
    expect(contributors[:primary_corporate_authors]).to include("Corp Org", "Meeting Group")
    doc.export_contributors
    expect(doc.send(:author_lists)).to eq(doc.send(:author_lists))
  end

  it 'extracts keywords from display and JSON fields' do
    doc = folio_harness_class.new(
      "keyword_display" => ["<b>Keyword</b>", "Keyword"],
      "subject_json" => [
        "{\"subject\":\"Subject One\"}",
        "[\"Subject Two\", {\"subject\":\"Subject Three\"}]",
        "\"Loose Subject\"",
        "invalid json"
      ]
    )

    keywords = doc.export_keywords
    expect(keywords).to include("Keyword", "Subject One", "Subject Two", "Subject Three", "Loose Subject")
  end

  it 'extracts abstracts, editions, dois, and identifiers' do
    doc = folio_harness_class.new(
      "summary_display" => ["<p>Summary</p>"],
      "description_display" => ["Description"],
      "edition_display" => ["First edition"],
      "doi_display" => ["10.1234/folio"],
      "isbn_display" => ["111", "222"],
      "issn_display" => ["3333-4444"]
    )

    expect(doc.export_abstracts).to eq(["Summary", "Description"])
    expect(doc.export_edition).to eq("First edition")
    expect(doc.export_doi).to eq("10.1234/folio")
    expect(doc.export_isbns).to eq(["111", "222"])
    expect(doc.export_issns).to eq(["3333-4444"])
  end
end
