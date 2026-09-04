# frozen_string_literal: true

module BlacklightMcp
  # Turns search results into a short JSON reply for the AI.
  #
  # Kept small on purpose: enough to cite a record and decide how to narrow the
  # next search, without dumping every field Solr stores. Use `get_record` when
  # the whole record is wanted.
  class ResultPresenter

    # Which Solr fields fill each key in the reply. The first one that has a
    # value wins.
    DOCUMENT_FIELDS = {
      'title' => %w[title_display fulltitle_display title_vern_display],
      'author' => %w[author_display author_vern_display],
      'format' => %w[format],
      'publication_year' => %w[pub_date_display pub_date],
      'publication' => %w[pub_info_display],
      'language' => %w[language_display],
      'edition' => %w[edition_display],
      'call_number' => %w[lc_callnum_display]
    }.freeze

    # How many values to return per facet.
    FACET_VALUE_LIMIT = 20

    def initialize(response, params: {}, base_url: nil)
      @response = response
      @params = params
      @base_url = base_url
    end

    def to_h
      {
        'total' => response.total.to_i,
        'page' => response.current_page.to_i,
        'per_page' => response.limit_value.to_i,
        'total_pages' => response.total_pages.to_i,
        'search' => search_summary,
        'documents' => documents,
        'facets' => facets
      }.compact
    end

    # One record on its own, without the surrounding results.
    def self.document(document, base_url: nil)
      new(nil, base_url: base_url).document(document)
    end

    def document(doc)
      summary = { 'id' => doc.id.to_s }

      DOCUMENT_FIELDS.each do |key, solr_fields|
        value = solr_fields.filter_map { |field| doc[field].presence }.first
        summary[key] = scalarize(value) unless value.nil?
      end

      summary['path'] = "/catalog/#{doc.id}"
      summary['url'] = "#{base_url}/catalog/#{doc.id}" if base_url.present?
      summary
    end

    private

    attr_reader :response, :params, :base_url

    def documents
      response.documents.map { |doc| document(doc) }
    end

    # Repeats back what was actually searched, so the AI can build on it
    # and can see when it guessed a facet value wrong.
    def search_summary
      summary = {}
      summary['query'] = params[:q] if params[:q].present?
      summary['search_field'] = params[:search_field] if params[:search_field].present?
      summary['rows'] = advanced_row_summary if params[:q_row].present?
      summary['filters'] = params[:f_inclusive] if params[:f_inclusive].present?
      summary['filters_all'] = params[:f] if params[:f].present?
      summary['ranges'] = params[:range] if params[:range].present?
      summary['sort'] = params[:sort] if params[:sort].present?
      summary
    end

    def advanced_row_summary
      booleans = params[:boolean_row] || {}

      params[:q_row].each_with_index.map do |query, index|
        row = {
          'query' => query,
          'field' => params[:search_field_row][index],
          'op' => params[:op_row][index]
        }
        row['joined_to_previous_by'] = booleans[index.to_s] if index.positive?
        row
      end
    end

    def facets
      return {} if response.aggregations.blank?

      response.aggregations.each_with_object({}) do |(field, facet), result|
        items = Array(facet.items).first(FACET_VALUE_LIMIT)
        next if items.empty?

        result[FacetNames.public_name(field)] = {
          'label' => CatalogOptions.label_for_facet(field),
          'values' => items.map { |item| { 'value' => item.value.to_s, 'count' => item.hits.to_i } }
        }
      end.merge(range_facets)
    end

    # Date facets come back as a lowest and highest value rather than a list, so
    # the AI can see which years are worth asking for.
    def range_facets
      stats = response.dig('stats', 'stats_fields')
      return {} if stats.blank?

      stats.each_with_object({}) do |(field, values), result|
        next unless CatalogOptions.range_facet_field?(field)
        next if values.blank? || values['min'].nil?

        result[FacetNames.public_name(field)] = {
          'label' => CatalogOptions.label_for_facet(field),
          'type' => 'range',
          'min' => values['min'].to_i,
          'max' => values['max'].to_i
        }
      end
    end

    # Some Solr fields hold a list, some a single value. Unwrap lists of one.
    def scalarize(value)
      value.is_a?(Array) && value.one? ? value.first : value
    end
  end
end
