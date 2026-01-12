# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Blacklight::Document::Source::Folio do
  include_context "folio source fixtures"
  let(:document) { folio_document }

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
end
