# Builds solr q param for simple, advanced, and bento search
module SolrQueryBuilder
  extend ActiveSupport::Concern

  DEFAULT_BOOLEAN = 'AND'
  DEFAULT_OP = 'AND'
  DEFAULT_SEARCH_FIELD = 'all_fields'

  # Builds solr q param from search fields, booleans, and ops (simple and advanced search)
  def build_solr_q(params)
    return '' if !params.is_a?(Hash)

    if has_multiple_queries?(params)
      build_advanced_search_query(params)
    else
      build_simple_search_query(params)
    end
  end

  # Remove any blank rows from advanced search form
  def remove_blank_rows(params)
    # Example params: {
    #   "q_row"=>["test", ""],
    #   "op_row"=>["AND", "AND"],
    #   "search_field_row"=>["all_fields", "all_fields"],
    #   "boolean_row"=>{"1"=>"AND"}
    # }
    cleaned_params = { q_row: [], op_row: [], search_field_row: [], boolean_row: [] }
    row_count = params[:q_row].count
    row_count.times do |i|
      if params[:q_row][i].strip.present?
        cleaned_params[:q_row] << params[:q_row][i]
        cleaned_params[:op_row] << (params.fetch(:op_row, [])[i] || DEFAULT_OP)
        cleaned_params[:search_field_row] << (params.fetch(:search_field_row, [])[i] || DEFAULT_SEARCH_FIELD)
      end
      
      # Don't add last bool in boolean_row
      if cleaned_params[:q_row].present? && params[:q_row][i + 1].present?
        boolean_row_key = (i + 1).to_s
        cleaned_params[:boolean_row] << (params.dig(:boolean_row, boolean_row_key) || DEFAULT_BOOLEAN)
      end
    end

    # Example cleaned_params: {
    #   :q_row=>["test"],
    #   :op_row=>["AND"],
    #   :search_field_row=>["all_fields"],
    #   :boolean_row=>[]
    # }
    params.merge(cleaned_params)
  end

  def build_simple_search_query(params)
    return '' if params[:q].blank?

    query = clean_q(params[:q])
    search_field = params[:search_field]
    set_q_with_search_fields(query: query, search_field: search_field)
  end

  def build_advanced_search_query(params)
    return '' if params[:q_row].blank? || !params[:q_row].is_a?(Array)
    
    # Handle special characters and unpaired quotation marks in q_row
    params[:q_row] = clean_q_rows(params)

    # Remove any blank rows from advanced search form
    params = remove_blank_rows(params)

    # Add solr fields to q based on search_field and op
    params[:q_row] = set_q_row_with_search_fields(params)

    # Pair queries together with booleans
    # Return final q solr param
    set_q_row_with_bools(params)
  end

  def q_to_solr(query, op, search_field, search_field_config)
    solr_field = solr_field_or_default(search_field_config, 'field_override')
    solr_phrase_field = solr_field_or_default(search_field_config, 'phrase_field')
    solr_quoted_field = solr_field_or_default(search_field_config, 'quoted_field')
    solr_starts_field = solr_field_or_default(search_field_config, 'starts_field')

    q_words = query.split
    case op
    when 'OR'
      # Combine separate words with 'OR'
      # Theoretically okay to split up left-anchored search fields and cts fields if op is OR,
      #    though most of these fields aren't available in advanced search
      q_string = q_words.map { |q_word| solr_query(solr_field, q_word) }.join(' OR ')
    when 'phrase'
      q_string = solr_query(solr_quoted_field, query)
    when 'begins_with'
      q_string = solr_query(solr_starts_field, query)
    else
      # Default to handling op as 'AND'
      if search_whole_query(search_field)
        q_string = solr_query(solr_field, query)
      else
        # Combine separate words with 'AND'
        q_string = q_words.map { |q_word| solr_query(solr_field, q_word) }.join(' AND ')

        # If multi-word query or phrase field exists for search_field, add phrase query to q_string
        # Phrase fields include substantial result boosting for left-anchored/begins-with query matching, and exact query matching
        # So combining field with phrase_field (when available) is necessary even when q_words.size == 1
        q_string = "(#{q_string}) OR #{solr_query(solr_phrase_field, query)}" if search_field_config['phrase_field'] || q_words.size > 1
      end
    end

    q_string
  end

  def q_with_quotes_to_solr(query, op, search_field, search_field_config)
    if ['phrase', 'begins_with'].include?(op) || search_whole_query(search_field)
      # Don't break up queries if no quoted field exists for search_field
      # Remove quotation marks from query and handle as normal
      query.gsub!('"', '')
      q_to_solr(query, op, search_field, search_field_config)
    else
      # Parse quotes from query
      quoted_substrings = query.split(/(\s*"\s*)/)
      is_quoted = false
      all_substrings = []

      quoted_substrings.each do |substring|
        next unless substring.present?
        if substring.include?('"')
          is_quoted = !is_quoted
          next
        end

        # Replace op with 'phrase' if substring is quoted
        op_override = is_quoted ? 'phrase' : op
        all_substrings << q_to_solr(substring, op_override, search_field, search_field_config)
      end

      all_substrings.map { |substring| "(#{substring})" }.join(" #{op} ")
    end
  end

  # Add solr fields to q based on search_field and op
  def set_q_row_with_search_fields(params)
    form_q_to_solr_q = []

    params[:q_row].each_with_index do |query, q_index|
      op = params[:op_row][q_index]
      search_field = params[:search_field_row][q_index]
      form_q_to_solr_q << set_q_with_search_fields(query: query, search_field: search_field, op: op)
    end

    form_q_to_solr_q
  end

  def set_q_with_search_fields(query:, search_field: DEFAULT_SEARCH_FIELD, op: DEFAULT_OP)
    return '' if query.blank?

    # Default to 'all_fields' if no search_field
    search_field = DEFAULT_SEARCH_FIELD if search_field.blank?
    # Use search_field as-is if not in blacklight_config.search_fields
    search_field_config = blacklight_config.search_fields[search_field] || { 'field' => search_field }

    if query.count('"') > 0
      q_string = q_with_quotes_to_solr(query, op, search_field, search_field_config)
    else
      q_string = q_to_solr(query, op, search_field, search_field_config)
    end

    # If format value exists for search_field, add format to q_string
    q_string = "(#{q_string}) AND format:\"#{search_field_config['format']}\"" if search_field_config['format']

    q_string
  end

  def clean_q_rows(params)
    params[:q_row].map { |query| clean_q(query) }
  end

  # Handle special characters and unpaired quotation marks in q_row
  def clean_q(query)
    query.strip!

    # Replace left and right quotation marks with regular quotes
    query.gsub!(/[”“]/, '"')

    # Handle unpaired quotes
    # If the first character is an unpaired quotation mark, close quotation
    query = query + '"' if query.count('"') == 1 && query[0] == '"'        
    # Remove unpaired quotes
    query.gsub!('"', '') if query.count('"') % 2 == 1

    # Remove: parentheses, brackets. Escape: colons, plus signs, minus signs/dashes
    # From: https://solr.apache.org/guide/8_8/the-dismax-query-parser.html
    #       The DisMax query parser supports an extremely simplified subset of the Lucene QueryParser syntax.
    #       As in Lucene, quotes can be used to group phrases, and +/- can be used to denote mandatory and optional clauses.
    #       All other Lucene query parser special characters (except AND and OR) are escaped to simplify the user experience.
    query.gsub(/[\[\]\(\):+-]/, ':' => '\:', '+' => '\+', '-' => '\-')
  end

  # Pair 2 queries with booleans, wrap each pair in parentheses
  def set_q_row_with_bools(params)
    solr_q = ''
    params[:q_row].each_with_index do |query, q_index|
      if q_index == 0
        solr_q = "(#{query})"
      else
        solr_q += "(#{query}))"
      end
      if q_index < params[:q_row].size - 1
        solr_q = "(#{solr_q} #{params[:boolean_row][q_index]} "
      end
    end

    solr_q
  end

  private

  def has_multiple_queries?(params)
    params[:q_row].present?
  end

  def solr_query(field, q)
    solr_field_prefix = field.present? ? "#{field}:" : ''
    "#{solr_field_prefix}\"#{q}\""
  end

  def solr_field_or_default(field_config, field_type)
    field_config[field_type] || field_config['field']
  end

  def click_to_search_field(search_field)
    search_field.end_with?('_cts', '_browse')
  end

  def left_anchored_search_field(search_field)
    # Call number "all" search is an inherently left-anchored search and
    #   should be sent as a single phrase to lc_callnum (e.g. lc_callnum:"ABC123 .R12")
    # title_starts as search_field is only available in simple search and should be handled like op == 'begins_with'
    ['lc_callnum', 'title_starts'].include?(search_field)
  end

  # Don't break up queries for left-anchored search fields or cts fields
  def search_whole_query(search_field)
    search_field = search_field || DEFAULT_SEARCH_FIELD
    left_anchored_search_field(search_field) || click_to_search_field(search_field)
  end

  def blacklight_config
    blacklight_config ||= CatalogController.blacklight_config
  end
end
