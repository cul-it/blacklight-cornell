# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Blacklight::Document::Source::Marc do
  include_context "marc source fixtures"

  let(:document) { marc_document }

  it 'maps base export fields from Solr values' do
    expect(document.export_format).to eq('Musical Score')
    expect(document.export_online?).to be(true)
  end

  it 'builds titles from MARC 245 fields' do
    expect(document.export_title(separator: ' ')).to eq("Batman a film score")
    expect(document.export_title(separator: ': ')).to eq("Batman: a film score")
  end

  it 'extracts publication data, edition, and thesis info from MARC' do
    pub_data = document.export_publication_data
    expect(pub_data[:place]).to eq('Los Angeles, CA')
    expect(pub_data[:publisher]).to eq('Omni Music Publishing')
    expect(pub_data[:date]).to eq('2016')
    expect(document.export_edition).to eq('Second edition.')
    expect(document.export_thesis_info).to eq(type: 'Thesis', inst: 'Cornell Univ', date: '2016')
  end

  it 'extracts identifiers and medium details from MARC' do
    expect(document.export_isbns.map(&:strip)).to eq(['9780989004718', '0989004716'])
    expect(document.export_issns).to eq(['1234-5678'])
    expect(document.export_doi).to eq('10.1234/batman')
    expect(document.export_medium('video')).to eq('DVD')
  end

  it 'extracts contributors, roles, and relators' do
    contributors = document.export_contributors
    expect(contributors[:primary_authors]).to eq(['Elfman, Danny'])
    expect(contributors[:editors]).to include('Burton, Tim')
    expect(contributors[:secondary_authors]).to include('Brahms, Johannes')
    expect(contributors[:primary_corporate_authors]).to include('Gotham Music Group')
    expect(contributors[:secondary_corporate_authors]).to be_empty
    relators = document.export_relators
    expect(relators['Burton, Tim']).to include('edt')
    expect(relators['Elfman, Danny']).to be_empty
  end

  it 'extracts notes, abstracts, and keywords from MARC' do
    expect(document.export_notes).to include('Includes composer notes. ')
    expect(document.export_notes).to include('Suite and reprise.')
    expect(document.export_abstracts).to include('A symphonic score for the film. ')
    expect(document.export_keywords).to include('Motion picture music Scores ')
    expect(document.export_keywords).to include('Elfman, Danny 1953- ')
  end
end
