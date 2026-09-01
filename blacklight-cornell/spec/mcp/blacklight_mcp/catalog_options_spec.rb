# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BlacklightMcp::CatalogOptions do
  let(:bl_config) { CatalogController.blacklight_config }

  describe '.search_fields' do
    it 'exposes every configured search field' do
      expect(described_class.search_field_keys).to include('all_fields', 'title', 'journaltitle', 'author',
                                                           'subject', 'lc_callnum', 'series', 'publisher',
                                                           'pubplace', 'number', 'isbnissn', 'notes', 'donor')
    end

    it 'omits the "---" separators used only to break up the UI dropdown' do
      expect(bl_config.search_fields.keys).to include('separator_1')
      expect(described_class.search_field_keys).not_to include('separator_1')
    end
  end

  describe '.advanced_search_fields' do
    it 'is the subset the /advanced form offers' do
      expect(described_class.advanced_search_fields.keys).to include('all_fields', 'title', 'journaltitle', 'author')
    end

    it 'excludes click-to-search and browse fields' do
      expect(described_class.advanced_search_fields.keys).not_to include('title_starts', 'author_browse', 'author_cts')
    end
  end

  describe '.sort_fields' do
    it 'lists every configured sort with its label' do
      labels = described_class.sort_options.map { |option| option['label'] }
      expect(labels).to include('relevance', 'year descending', 'year ascending', 'author A-Z',
                                'author Z-A', 'title A-Z', 'title Z-A', 'call number', 'date acquired')
    end

    it 'reports the catalog default sort' do
      expect(described_class.default_sort).to eq(bl_config.default_sort_field.key)
    end
  end

  describe '.normalize_sort' do
    it 'passes a sort key through unchanged' do
      expect(described_class.normalize_sort('pub_date_sort desc, title_sort asc'))
        .to eq('pub_date_sort desc, title_sort asc')
    end

    it 'resolves a human label to its sort key' do
      expect(described_class.normalize_sort('relevance')).to eq('score desc, pub_date_sort desc, title_sort asc')
      expect(described_class.normalize_sort('year descending')).to eq('pub_date_sort desc, title_sort asc')
      expect(described_class.normalize_sort('title A-Z')).to eq('title_sort asc, pub_date_sort desc')
    end

    it 'matches labels case-insensitively and ignores surrounding space' do
      expect(described_class.normalize_sort('  RELEVANCE ')).to eq('score desc, pub_date_sort desc, title_sort asc')
    end

    it 'returns nil for anything unconfigured' do
      expect(described_class.normalize_sort('popularity')).to be_nil
      expect(described_class.normalize_sort(nil)).to be_nil
      expect(described_class.normalize_sort('')).to be_nil
    end
  end

  describe '.facet_fields' do
    it 'includes the sidebar facets' do
      expect(described_class.facet_field_keys).to include('online', 'format', 'location', 'author_facet',
                                                          'pub_date_facet', 'language_facet', 'fast_topic_facet',
                                                          'fast_geo_facet', 'fast_era_facet', 'fast_genre_facet',
                                                          'subject_content_facet', 'lc_callnum_facet')
    end

    it 'excludes internal facets hidden from public catalog requests' do
      expect(described_class.facet_field_keys).not_to include('authortitle_facet', 'availability_facet', 'collection',
                                                              'format_main_facet', 'source', 'workid_facet',
                                                              'subject_topic_lc_facet')
    end
  end

  describe '.filterable_facet_fields' do
    it 'excludes range facets, which take begin/end instead of values' do
      expect(described_class.filterable_facet_field_keys).not_to include('pub_date_facet')
    end

    it 'excludes query facets, whose values are fixed keys rather than terms' do
      expect(described_class.filterable_facet_field_keys).not_to include('acquired_dt_query')
    end
  end

  describe '.range_facet_fields' do
    it 'is the publication year facet' do
      expect(described_class.range_facet_field_keys).to eq(['pub_date_facet'])
      expect(described_class.range_facet_field?('pub_date_facet')).to be true
      expect(described_class.range_facet_field?('format')).to be false
    end
  end

  describe '.advanced_facet_fields' do
    it 'is the facet set the /advanced form draws, in form order' do
      expect(described_class.advanced_facet_fields.keys).to eq(%w[pub_date_facet format language_facet])
    end
  end

  # Everything calls it by name, but it is still an ordinary module, so it can
  # be mixed into a class that would rather call it directly.
  describe 'as a mixin' do
    it 'can be included' do
      host = Class.new { include BlacklightMcp::CatalogOptions }.new
      expect(host.search_field_keys).to eq(described_class.search_field_keys)
    end

    it 'can be extended' do
      host = Class.new { extend BlacklightMcp::CatalogOptions }
      expect(host.sort_options).to eq(described_class.sort_options)
    end
  end

  describe 'operator vocabularies' do
    it 'matches the boolean_row select in the advanced form' do
      expect(described_class::BOOLEANS).to eq(%w[AND OR NOT])
    end

    it 'matches the op_row select in the advanced form' do
      expect(described_class::OPS.keys).to eq(%w[AND OR phrase begins_with])
    end
  end
end
