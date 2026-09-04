# frozen_string_literal: true

require 'rails_helper'

# The vocabulary the MCP endpoint promises to clients it cannot see.
#
# Tool schemas are generated from the live catalog configuration, which is the
# right design -- add a facet in catalog_controller.rb and MCP offers it. The
# cost is that a *rename* is silent: the enum changes underneath every client
# already using the old value, and all they see is "not a configured facet
# field" on a call that worked yesterday. Nothing else in the suite fails.
#
# So these lists are checked in on purpose. When this spec fails, the catalog
# configuration changed. Decide which it was:
#
#   * A new field, facet or sort -- add it here. Additive, safe to ship.
#   * A rename or removal -- this is a breaking change to a published API.
#     Update the list and bump BlacklightMcp::VERSION
#     so clients can see that the vocabulary moved.
#
# Never "fix" a failure by regenerating the list from the config: that is the
# thing being guarded against.
RSpec.describe 'MCP tool vocabulary' do
  describe 'search fields' do
    it 'offers exactly the fields clients have been told about' do
      expect(BlacklightMcp::CatalogOptions.search_field_keys).to contain_exactly(
        'all_fields', 'title', 'journaltitle', 'title_starts', 'author', 'author_browse', 'at_browse',
        'subject', 'subject_browse', 'lc_callnum', 'callnumber_browse', 'series', 'publisher', 'pubplace',
        'number', 'isbnissn', 'notes', 'donor', 'author_cts', 'subject_cts', 'author_pers_browse',
        'author_corp_browse', 'author_event_browse', 'subject_pers_browse', 'subject_corp_browse',
        'subject_event_browse', 'subject_topic_browse', 'subject_era_browse', 'subject_genr_browse',
        'subject_geo_browse', 'subject_work_browse', 'authortitle_browse'
      )
    end
  end

  describe 'facets' do
    it 'offers exactly the filterable facets clients have been told about' do
      expect(BlacklightMcp::CatalogOptions.filterable_facet_field_keys).to contain_exactly(
        'online', 'format', 'location', 'author_facet', 'language_facet', 'fast_topic_facet',
        'fast_geo_facet', 'fast_era_facet', 'fast_genre_facet', 'subject_content_facet',
        'hierarchy_facet', 'lc_callnum_facet'
      )
    end

    it 'offers exactly the range facets clients have been told about' do
      expect(BlacklightMcp::CatalogOptions.range_facet_field_keys).to contain_exactly('pub_date_facet')
    end

    it 'keeps internal and staff-only facets out of the public vocabulary' do
      internal = CatalogController.blacklight_config.facet_fields.keys - BlacklightMcp::CatalogOptions.facet_field_keys

      expect(internal).to include('availability_facet')
      expect(BlacklightMcp::CatalogOptions.facet_field_keys).not_to include('availability_facet')
    end
  end

  # The names in the tool schemas, which is what a client actually sends. These
  # come from the facet labels in catalog_controller.rb, so renaming a facet
  # heading on the website renames it here too -- a breaking change for every
  # client already using the old name.
  describe 'facet names' do
    it 'advertises exactly the readable facet names clients have been told about' do
      expect(BlacklightMcp::FacetNames.public_names).to contain_exactly(
        'Access', 'Format', 'Library Location', 'Author, etc.', 'Language', 'Subject',
        'Subject: Region', 'Subject: Era', 'Genre', 'Fiction/Non-Fiction', 'Hierarchy Facet',
        'Call Number'
      )
    end

    it 'advertises exactly the readable range facet names' do
      expect(BlacklightMcp::FacetNames.public_range_names).to contain_exactly('Publication Year')
    end
  end

  describe 'sorts' do
    it 'offers exactly the sort keys clients have been told about' do
      expect(BlacklightMcp::CatalogOptions.sort_field_keys).to contain_exactly(
        'score desc, pub_date_sort desc, title_sort asc',
        'pub_date_sort desc, title_sort asc',
        'pub_date_sort asc, title_sort asc',
        'author_sort asc, title_sort asc',
        'author_sort desc, title_sort asc',
        'title_sort asc, pub_date_sort desc',
        'title_sort desc, pub_date_sort desc',
        'callnum_sort asc, pub_date_sort desc',
        'acquired_dt desc, title_sort asc'
      )
    end

    it 'offers exactly the sort labels clients have been told about' do
      labels = BlacklightMcp::CatalogOptions.sort_options.map { |option| option['label'] }

      expect(labels).to contain_exactly('relevance', 'year descending', 'year ascending', 'author A-Z',
                                        'author Z-A', 'title A-Z', 'title Z-A', 'call number', 'date acquired')
    end
  end

  describe 'tools' do
    # A tool name is the most visible part of the contract: renaming one breaks
    # every saved prompt and every client that names it.
    it 'offers exactly the tool names clients have been told about' do
      expect(BlacklightMcp::Server.tools.map(&:name_value)).to contain_exactly(
        'search', 'advanced_search', 'describe_search_options', 'facet_values', 'get_record',
        'check_availability', 'fetch'
      )
    end
  end
end
