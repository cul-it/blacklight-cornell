# frozen_string_literal: false
# operations on strings are so prevalent must unfreeze them.
class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include BlacklightRangeLimit::RangeLimitBuilder

  self.default_processor_chain += [:sortby_title_when_browsing, :sortby_callnum,
                                   :set_fl, :set_query,
                                   :homepage_default, :reset_facet_limit, :group_bento_results]

  DEFAULT_BOOLEAN = 'AND'
  DEFAULT_OP = 'AND'
  DEFAULT_SEARCH_FIELD = 'all_fields'

  # Display all lc_callnum_facet values when facet is present in params
  def reset_facet_limit(solr_params)
    return if facet != 'lc_callnum_facet' && blacklight_params[:f].try(:dig, 'lc_callnum_facet').blank?

    solr_params["f.lc_callnum_facet.facet.limit"] = -1
  end

  def sortby_title_when_browsing user_parameters
    # if no search term is submitted and user hasn't specified a sort
    # assume browsing and use the browsing sort field
    if user_parameters[:q].blank? and user_parameters[:sort].blank?
      browsing_sortby =  blacklight_config.sort_fields.values.select { |field| field.browse_default == true }.first
    end
  end

  # Removes unnecessary elements from the solr query when the homepage is loaded.
  # The check for the q parameter ensures that searches, including empty searches, and
  # advanced searches are not affected.
  def homepage_default user_parameters
    if !user_parameters['facet.field'].kind_of?(Array) || user_parameters['facet.field'].count == 1
      # this is a request for a facet page, like /catalog/facet/author_facet
    elsif user_parameters['q'].nil? && user_parameters['fq'].blank?
      user_parameters = streamline_query(user_parameters)
    end
  end

  #sort call number searches by call number
  def sortby_callnum user_parameters
    if blacklight_params[:search_field] == 'lc_callnum' && blacklight_params[:sort].nil?
       callnum_sortby =  blacklight_config.sort_fields.values.select { |field| field.callnum_default == true }.first
       user_parameters[:sort] = callnum_sortby.field
    end
  end

  def set_fl solr_parameters
    # Overrides default fl set in solrconfig to return all stored fields
    solr_parameters[:fl] = '*' if blacklight_params['controller'] == 'bookmarks' || blacklight_params['format'].present? || blacklight_params['controller'] == 'book_bags'
  end

  # Sets solr q param from search fields, booleans, and ops (simple, advanced, and bento search)
  def set_query solr_parameters
    # Standard blacklight_params from advanced search form:
    # {
    #   "advanced_query"=>"yes", 
    #   "boolean_row"=>{"1"=>"AND"},
    #   "commit"=>"Search", 
    #   "op_row"=>["AND", "AND"], 
    #   "q_row"=>["test", ""], 
    #   "range_end"=>"2025", 
    #   "range_field"=>"pub_date_facet", 
    #   "range_start"=>"0", 
    #   "search_field"=>"advanced", 
    #   "search_field_row"=>["all_fields", "all_fields"], 
    #   "sort"=>"score desc, pub_date_sort desc, title_sort asc", 
    #   "utf8"=>"✓", 
    #   "controller"=>"catalog", 
    #   "action"=>"range_limit"
    # }
    # For non-standard advanced search params, use presence of q_row to determine if query should be processed as advanced search
    if blacklight_params[:q_row].present?
      # Build solr q param for advanced search
      # Clean up/reset non-standard advanced search params
      blacklight_params.delete('q')
      solr_parameters[:search_field] = 'advanced'

      solr_parameters[:q] = build_advanced_search_query(blacklight_params)
    elsif blacklight_params[:search_field].present?
      # Remove any unexpected advanced search params
      if blacklight_params[:advanced_query].present?
        blacklight_params.delete(:advanced_query)
        blacklight_params.delete(:search_field_row)
        blacklight_params.delete(:op_row)
        blacklight_params.delete(:boolean_row)
        blacklight_params.delete(:count)
      end

      # Build solr q param for simple and bento search
      solr_parameters[:q] = build_simple_search_query(blacklight_params)
    end
  end

  # Set result grouping solr parameters for bento search results
  def group_bento_results solr_parameters
    if blacklight_params[:bento]
      # Group results by format_main_facet and remove unnecessary facet values and stats
      # format_main_facet is a single-valued field used specially for bento's type-aggregated relevance sorting
      #    vs catalog's show and index multivalued "format" solr field
      solr_parameters.merge!({
        :group => true,
        :'group.field' => 'format_main_facet',
        :'group.limit' => 3,
        :'group.ngroups' => 'true',
        :fl => 'id,pub_date_display,format,fulltitle_display,fulltitle_vern_display,author_display,score,pub_info_display,availability_json',
        :facet => false,
        :stats => false
      })
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
    return '' if params[:q].blank? || !params[:q].is_a?(String)

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

  def streamline_query(user_params)
    homepage_facets = ["online", "format", "language_facet", "location", "hierarchy_facet"]
    user_params['facet.field'] = homepage_facets
    user_params['stats'] = false
    user_params['stats.field'] = []
    user_params['rows'] = 0 if blacklight_params['controller'] == 'catalog'
    user_params.delete('sort')
    user_params.delete('f.lc_callnum_facet.facet.limit')
    user_params.delete('f.lc_callnum_facet.facet.sort')
    user_params.delete('f.author_facet.facet.limit')
    user_params.delete('f.fast_topic_facet.facet.limit')
    user_params.delete('f.fast_geo_facet.facet.limit')
    user_params.delete('f.fast_era_facet.facet.limit')
    user_params.delete('f.fast_genre_facet.facet.limit')
    user_params.delete('f.subject_content_facet.facet.limit')
    user_params.delete('f.lc_alpha_facet.facet.limit')
    return user_params
  end

  private

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
end
