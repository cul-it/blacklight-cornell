# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BlacklightMcp::Tools::Search do

  describe 'the tool declaration' do
    it 'is named search and is advertised as read-only' do
      expect(described_class.name_value).to eq('search')
      expect(described_class.annotations.read_only_hint).to be true
      expect(described_class.annotations.destructive_hint).to be false
    end

    it 'offers every configured search field as an enum' do
      schema = described_class.input_schema.to_h
      expect(schema[:properties][:search_field][:enum]).to eq(BlacklightMcp::CatalogOptions.search_field_keys)
    end

    it 'offers every configured sort, by key and by label' do
      enum = described_class.input_schema.to_h[:properties][:sort][:enum]
      expect(enum).to include('score desc, pub_date_sort desc, title_sort asc', 'relevance', 'title A-Z')
    end

    it 'accepts facet, range and paging arguments' do
      properties = described_class.input_schema.to_h[:properties].keys
      expect(properties).to include(:query, :search_field, :formats, :languages, :filters, :filters_all,
                                    :date_range, :sort, :page, :per_page)
    end

    # Publication year is the only range facet this catalog has, and date_range
    # covers it, so ranges could only duplicate it. Still accepted, not offered.
    it 'does not offer ranges while date_range covers the only range facet' do
      expect(described_class.input_schema.to_h[:properties].keys).not_to include(:ranges)
    end

    # formats and languages are one facet each. Saying which, in the schema,
    # lets a client offer that facet's real values instead of a text box.
    it 'says which facet the shortcut arguments draw their values from' do
      properties = described_class.input_schema.to_h[:properties]

      expect(properties[:formats][:'x-facet']).to eq('Format')
      expect(properties[:languages][:'x-facet']).to eq('Language')
    end

    # Which facets the argument takes, in the schema rather than only in prose,
    # so a client never has to guess or borrow the list from another tool.
    it 'names the facets filters accepts' do
      filters = described_class.input_schema.to_h[:properties][:filters]

      expect(filters[:propertyNames][:enum]).to eq(BlacklightMcp::FacetNames.public_names)
    end

    it 'refuses arguments it does not define, so a typo fails loudly' do
      expect(described_class.input_schema.to_h[:additionalProperties]).to be false
    end
  end

  describe '.call' do
    it 'runs the search the arguments describe' do
      captured = stub_search_runner
      tool_payload(described_class, query: 'batman', formats: ['Book'], sort: 'relevance')

      expect(captured).to include(
        q: 'batman',
        search_field: 'all_fields',
        f_inclusive: { 'format' => ['Book'] },
        sort: 'score desc, pub_date_sort desc, title_sort asc'
      )
    end

    it 'returns the presented results' do
      stub_search_runner(response: solr_response(docs: [{ 'id' => '1', 'title_display' => 'Batman' }]))
      payload = tool_payload(described_class, query: 'batman')

      expect(payload['total']).to eq(1)
      expect(payload['documents'].first).to include('id' => '1', 'title' => 'Batman')
    end

    it 'includes the record urls for the host that was called' do
      stub_search_runner(response: solr_response(docs: [{ 'id' => '1' }]))
      payload = tool_payload(described_class, { query: 'x' }, { base_url: 'https://catalog.example' })

      expect(payload['documents'].first['url']).to eq('https://catalog.example/catalog/1')
    end

    it 'searches with filters alone when no query is given' do
      captured = stub_search_runner
      tool_payload(described_class, languages: ['German'])

      expect(captured[:q]).to eq('')
      expect(captured[:f_inclusive]).to eq('language_facet' => ['German'])
    end

    describe 'explain' do
      it 'reports the catalog and Solr params without running the search' do
        stub_search_runner(solr_params: { q: '("cats") OR phrase:"cats"', rows: 20 })
        payload = tool_payload(described_class, query: 'cats', explain: true)

        expect(payload['explain']).to be true
        expect(payload['catalog_params']).to include('q' => 'cats')
        expect(payload['solr_params']).to include('q' => '("cats") OR phrase:"cats"')
        expect(payload).not_to have_key('documents')
      end
    end

    # Solr failures reach the assistant as a tool error it can act on, never as
    # an exception that takes the whole request down.
    describe 'when Solr fails' do
      def failing_runner(error)
        runner = instance_double(BlacklightMcp::SearchRunner)
        allow(runner).to receive(:search_results).and_raise(error)
        allow(BlacklightMcp::SearchRunner).to receive(:new).and_return(runner)
        allow(Rails.logger).to receive(:warn)
      end

      it 'says a rejected query could not be run, and logs why' do
        failing_runner(Blacklight::Exceptions::InvalidRequest.new('undefined field nope'))

        expect(tool_error(described_class, query: 'x')).to match(/could not run that search/)
        expect(Rails.logger).to have_received(:warn).with('[mcp] solr rejected request: undefined field nope')
      end

      it 'treats an HTTP error from Solr the same way' do
        failing_runner(RSolr::Error::Http.new({ uri: URI('http://solr.example/select') },
                                              { status: 400, body: +'bad request' }))

        expect(tool_error(described_class, query: 'x')).to match(/could not run that search/)
      end

      # Only the class name is logged: the message carries the Solr URL, and
      # that URL carries credentials.
      it 'says the catalog took too long, logging the class and not the connection' do
        failing_runner(Blacklight::Exceptions::RepositoryTimeout.new('http://user:secret@solr.example'))

        expect(tool_error(described_class, query: 'x')).to match(/took too long to answer/)
        expect(Rails.logger).to have_received(:warn).with('[mcp] solr unavailable: Blacklight::Exceptions::RepositoryTimeout')
        expect(Rails.logger).not_to have_received(:warn).with(/secret/)
      end

      it 'treats a refused connection as the catalog being unavailable' do
        failing_runner(Blacklight::Exceptions::ECONNREFUSED)

        expect(tool_error(described_class, query: 'x')).to match(/took too long to answer/)
      end
    end

    describe 'invalid arguments' do
      before { stub_search_runner }

      it 'reports an unknown facet as a tool error, not an exception' do
        expect(tool_error(described_class, query: 'x', filters: { 'nope' => ['y'] }))
          .to match(/unknown facet "nope"/)
      end

      it 'reports an unknown search field' do
        expect(tool_error(described_class, query: 'x', search_field: 'abstract'))
          .to match(/not a configured search field/)
      end

      it 'reports an unknown sort' do
        expect(tool_error(described_class, query: 'x', sort: 'popularity'))
          .to match(/not a configured sort/)
      end

      it 'reports a reversed date range' do
        expect(tool_error(described_class, query: 'x', date_range: { begin: 2020, end: 1990 }))
          .to match(/must not be later than end/)
      end
    end
  end
end
