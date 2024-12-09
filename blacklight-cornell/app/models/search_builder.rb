# frozen_string_literal: false
# operations on strings are so prevalent must unfreeze them.
class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include BlacklightRangeLimit::RangeLimitBuilder

  self.default_processor_chain += [:sortby_title_when_browsing, :sortby_callnum, :advsearch, :homepage_default]

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

  def advsearch solr_parameters
    query_string = ""

    # Overrides default fl set in solrconfig to return all stored fields
    # TODO: Why do we need to do this? What fields do we need that aren't returned by default?
    solr_parameters[:fl] = "*" if blacklight_params["controller"] == "bookmarks" || blacklight_params["format"].present? || blacklight_params["controller"] == "book_bags"

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
      # Clean up/reset non-standard advanced search params
      blacklight_params.delete('q')
      solr_parameters[:search_field] = 'advanced'

      solr_parameters[:q] = build_advanced_search_query(blacklight_params)
    else # simple search code below
      if blacklight_params[:q].nil?
        blacklight_params[:q] = ''
        if !blacklight_params[:f].nil?
          solr_parameters[:fq] = []
          fq_string = ""
          blacklight_params[:f].each do |key, value|
            value.each do |val|
              if (val == 'last_1_week' or val == 'last_1_month' or val == 'last_1_years')
                if val == 'last_1_week'
                  fq_string = 'acquired_dt:[NOW-14DAY TO NOW-7DAY ]'
                else 
                  if val == 'last_1_month'
                    fq_string = 'acquired_dt:[NOW-30DAY TO NOW-7DAY ]'
                  else
                    if value[0] == 'last_1_years'
                      fq_string = 'acquired_dt:[NOW-1YEAR TO NOW-7DAY]'
                    end
                  end
                end                   
              else
                fq_string = '{!term f=' + key + '}' + val
              end
              solr_parameters[:fq] << fq_string
              blacklight_params[:fq] = solr_parameters[:fq]
            end
          end
        end
      end

      if !blacklight_params[:advanced_query].nil?
        blacklight_params.delete("advanced_query")
        blacklight_params.delete("search_field_row")
        blacklight_params.delete(:q_row)
        blacklight_params.delete(:op_row)
        blacklight_params.delete(:boolean_row)
        blacklight_params.delete(:count)
      end
      # End of secondary parsing

      journal_title_hack = 0
      if !blacklight_params.nil? and !blacklight_params[:search_field].nil?
        if blacklight_params[:search_field] == 'title_starts'
          if blacklight_params[:q].first == '"' and blacklight_params[:q].last == '"'
            blacklight_params[:q] = blacklight_params[:search_field] + ':' + blacklight_params[:q]
          else
            if blacklight_params[:q].include?('"')
              blacklight_params[:q].gsub!('"', '')
            end
            blacklight_params[:q] = blacklight_params[:search_field] + ':"' + blacklight_params[:q] + '"'
          end
        end

        if blacklight_params[:search_field] == 'series'
          if blacklight_params[:q].first == '"' and blacklight_params[:q].last == '"'
            blacklight_params[:q] = blacklight_params[:search_field] + ':' + blacklight_params[:q]
          else
            blacklight_params[:q] = blacklight_params[:search_field] + ':"' + blacklight_params[:q] + '"'
          end
        end
        if blacklight_params[:search_field].include?('_cts')
          if blacklight_params[:q].first == '"' and blacklight_params[:q].last == '"'
            blacklight_params[:q] = blacklight_params[:search_field] + ':' + blacklight_params[:q]
          else
            blacklight_params[:q] = blacklight_params[:search_field] + ':"' + blacklight_params[:q] + '"'
          end
        end
    
        #check for call number search
        if blacklight_params[:search_field] == 'lc_callnum'
          if blacklight_params[:q].first == '"' and blacklight_params[:q].last == '"'
            query_string = blacklight_params[:q]
          else
            query_string = '"' + blacklight_params[:q].gsub('"','') + '"'
          end
          blacklight_params[:q] = 'lc_callnum:' + query_string
          solr_parameters[:search_field] = blacklight_params[:search_field]
          if blacklight_params[:sort].nil? or blacklight_params[:sort] == 'callnum_sort asc, pub_date_sort desc'
            blacklight_params[:sort] = 'callnum_sort asc, pub_date_sort desc'
          end
          solr_parameters[:sort] = blacklight_params[:sort]
        end

        if blacklight_params[:search_field] == 'journaltitle'
          if blacklight_params[:q].first == '"' and blacklight_params[:q].last == '"'
            query_string = 'title_quoted:' + blacklight_params[:q]
          else
            tokens_array = []
            query_string = ''
            tokens_array = blacklight_params[:q].split(' ')
            if tokens_array.size > 1
              tokens_array.each do |token|
                query_string = query_string + '+title:' + token + ' '
              end
              query_string = '((' + query_string.rstrip + ') OR title_phrase:"' + blacklight_params[:q] + '")'
            else
              query_string = '(title:' + '"' + blacklight_params[:q].gsub('"','') + '" OR title_phrase:"' + blacklight_params[:q].gsub('"', '') + '") '
            end
          end
          blacklight_params[:q] =  query_string + ' AND format:Journal/Periodical'
          solr_parameters[:search_field] = blacklight_params[:search_field]
        end

        # All fields search calls parse_all_fields_query
        if blacklight_params[:search_field] == 'all_fields' or blacklight_params[:search_field] == ''
          returned_query = parse_all_fields_query(blacklight_params[:q])
          if returned_query == ''
            blacklight_params[:q] = ''
          else
            if blacklight_params[:q].first == '"' and blacklight_params[:q].last == '"' and blacklight_params[:q].count('"') == 2
              blacklight_params[:q] = 'quoted:' + blacklight_params[:q]
            else
              if !blacklight_params[:q].include?('"')
                if returned_query[0] != '+'
                  blacklight_params[:q] = '("' + returned_query + '") OR phrase:"' + blacklight_params[:q] + '"'
                else
                  blacklight_params[:q] = '('  + returned_query + ') OR phrase:"' + blacklight_params[:q] + '"'
                end
                solr_parameters[:q] = blacklight_params[:q]
              else
                query_string = '('
                return_query = checkMixedQuoted(blacklight_params)
                return_query.each do |token|
                  query_string = query_string + token + ' '
                end
                query_string = query_string.rstrip
                query_string = query_string + ')'
                blacklight_params[:q] = query_string
              end
            end
          end
        else
          #Not an all fields search test if query is quoted
          if blacklight_params[:q].first == '"' && blacklight_params[:q].last == '"' && blacklight_params[:q].count('"') == 2 && ['journaltitle', 'lc_callnum'].exclude?(blacklight_params[:search_field]) && blacklight_params[:search_field].exclude?('_cts')
            if ['author', 'publisher', 'title', 'subject'].include?(blacklight_params[:search_field])
              blacklight_params[:q] = "#{blacklight_params[:search_field]}_quoted:#{blacklight_params[:q]}"
            elsif ['author_quoted', 'publisher_quoted', 'title_starts'].include?(blacklight_params[:search_field])
              blacklight_params[:q] = "#{blacklight_params[:search_field]}:#{blacklight_params[:q]}"
            elsif ['title_quoted', 'subject_quoted'].include?(blacklight_params[:search_field])
              blacklight_params[:q] = "(+#{blacklight_params[:search_field]}:#{blacklight_params[:q]})"
            end
          else
            #check if this is a crazy multi quoted multi token search
            if blacklight_params[:q].include?('"') && ['title_starts', 'series', 'lc_callnum', 'journaltitle'].exclude?(blacklight_params[:search_field]) && blacklight_params[:search_field].exclude?('_cts')
              if blacklight_params[:q].first != '('
                query_string = '('
                return_query = checkMixedQuoted(blacklight_params)

                return_query.each do |token|
                  query_string = query_string + token + ' '
                end
                query_string = query_string.rstrip
                query_string = query_string + ')'
                blacklight_params[:q] = query_string
              else
                blacklight_params[:search_field] = 'author'
                blacklight_params[:q] = blacklight_params[:search_field] + ':' + blacklight_params[:q]
              end
              solr_parameters["mm"] = "1"
            end
          end
          if blacklight_params[:search_field].include?('_browse')
            blacklight_params[:q] = blacklight_params[:search_field] + ':' + blacklight_params[:q]
          end
          #queries are not all fields nor quoted  go ahead
          # exclude search_fields that match *_cts or *_browse
          if !(/_cts$/.match(blacklight_params[:search_field]) ||
            /_browse$/.match(blacklight_params[:search_field]) ||
            ['title_starts','series','journaltitle','lc_callnum'].include?(blacklight_params[:search_field])
          )
            # TODO: I don't think we want to split on the q param with included search_field?
            # Example: blacklight_params[:q] = "publisher_quoted:\"National Geographic Partners\""
            query_array = blacklight_params[:q].split(' ')
            # Example 1: query_array = ["publisher_quoted:\"National", "Geographic", "Partners\""]
            # Example 2: query_array = ["National", "Geographic", "Partners"]
            clean_array = []
            new_query = ''
            query_string = ''
            if query_array.size > 1
              query_array.each do |token|
                query_string = '+' + blacklight_params[:search_field] + ':"' + token + '"'
                clean_array << query_string
              end
              #  Example 1: clean_array = ["+publisher:\"publisher_quoted:\"National\"", "+publisher:\"Geographic\"", "+publisher:\"Partners\"\""]
              #  Example 2: clean_array = ["+publisher:\"National\"", "+publisher:\"Geographic\"", "+publisher:\"Partners\""]
              new_query = '('
              clean_array.each do |query|
                new_query = new_query + query + ' '
              end
              new_query = new_query.rstrip
              if ['number', 'title'].include?(blacklight_params[:search_field])
                if blacklight_params[:q].exclude?('_quoted')
                  new_query = new_query + ') OR ' + blacklight_params[:search_field] + '_phrase:"' + blacklight_params[:q] + '"'
                else
                  new_query = blacklight_params[:q]
                end
              else
                if blacklight_params[:q].first == '"' && blacklight_params[:q].last == '"'
                  new_query = new_query + ') OR ' + blacklight_params[:search_field] + ':' + blacklight_params[:q]
                else
                  if blacklight_params[:q].exclude?('_quoted')
                    new_query = new_query + ') OR '  + blacklight_params[:search_field] + ':"' + blacklight_params[:q] + '"'
                    # Example 2: new_query = "(+publisher:\"National\" +publisher:\"Geographic\" +publisher:\"Partners\") OR publisher:\"National Geographic Partners\""
                  else
                    # TODO: No need to run through all the query logic above if we're just going to revert to original q
                    new_query = blacklight_params[:q]
                    # Example 1: new_query = "publisher_quoted:\"National Geographic Partners\""
                  end
                end
              end
              blacklight_params[:q] = new_query
            else
              if blacklight_params[:search_field] == 'title'
                blacklight_params[:q] = '(+title:' + blacklight_params[:q] +  ') OR title_phrase:"' + blacklight_params[:q] + '"'
              else
                if blacklight_params[:q].first != '"+'
                  blacklight_params[:q] = '(+' + blacklight_params[:search_field] + ':"' + blacklight_params[:q] + '") OR ' + blacklight_params[:search_field] + ':"' + blacklight_params[:q] + '"'
                else
                  blacklight_params[:q] = ""
                end
              end
            end
          end
        end
        solr_parameters[:q] = blacklight_params[:q]
        solr_parameters[:f] = blacklight_params[:f]
        solr_parameters[:sort] = blacklight_params[:sort]
        solr_parameters["mm"] = "1"
      end
    end
  end    

  def parseQuotedQuery(quotedQuery)
    queryArray = []
    token_string = ''
    length_counter = 0
    quote_flag = 0
    quotedQuery.each_char do |x|
      length_counter = length_counter + 1
      if x != '"' and x != ' '
          token_string = token_string + x
      end
      if x == ' '
        if quote_flag != 0
          token_string = token_string + x
        else
          queryArray << token_string
          token_string = ''
        end
      end
      if x == '"' and quote_flag == 0
        if token_string != ''
          queryArray << token_string
          token_string = x
          quote_flag = 1
        else
          token_string = x
          quote_flag = 1
         end
      end
      if x == '"' and quote_flag == 1
        if token_string != '' and token_string != '"'
          token_string = token_string + x
          queryArray << token_string
          token_string = ''
          quote_flag = 0
        end
      end
      if length_counter == quotedQuery.size
        queryArray << token_string
      end
    end
    cleanArray = []
    queryArray.each do |toke|
      if toke != ''
        if !toke.blank?
          cleanArray << toke.rstrip
        end
      end
    end
    queryArray = cleanArray
    return queryArray
  end

  def checkMixedQuoted(blacklight_params)
      returnArray = []
      addFieldsArray = []
      if blacklight_params[:q].first == '"' and blacklight_params[:q].last == '"'
        if blacklight_params[:q].count('"') > 2
          returnArray = parseQuotedQuery(blacklight_params[:q])
          returnArray.each do |token|
            if blacklight_params[:search_field] == 'all_fields'
              if token.first == '"'
                token = '+quoted:' + token
              else
                token = '+' + token
              end
            else
              if token.first == '"'
                sfr = get_sf_name(blacklight_params[:search_field])
                if blacklight_params[:search_field] != 'all_fields'
                  token = '+' + sfr + '_quoted:' + token
                else
                  token = '+' + 'quoted:' + token
                end
              else
                sfr = get_sf_name(blacklight_params[:search_field])
                if blacklight_params[:search_field] != 'all_fields'
                  token = '+' + sfr +':' + token
                else
                  token = '+' + token
                end
              end
            end
            addFieldsArray << token
          end
          returnArray = addFieldsArray
          return returnArray
        else
          returnArray << blacklight_params[:q]
          return returnArray
        end
      else
        clearArray = []
        returnArray = parseQuotedQuery(blacklight_params[:q])
        returnArray.each do |token|
          if blacklight_params[:search_field] == 'all_fields'
            if token.first == '"'
              clearArray << '+quoted:' + token
            else
              clearArray << '+' + token
            end
          else
            sfr = get_sf_name(blacklight_params[:search_field])
            if token.first == '"'
              clearArray << '+' + sfr + '_quoted:' + token
            else
              clearArray << '+' + sfr + ':' + token
            end
          end
        end
        returnArray = clearArray
        return returnArray
      end
  end

  DEFAULT_BOOLEAN = 'AND'
  DEFAULT_OP = 'AND'
  DEFAULT_SEARCH_FIELD = 'all_fields'

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

  def build_advanced_search_query(params)
    return '' if params[:q_row].blank? || !params[:q_row].is_a?(Array)
    
    # Handle special characters and unpaired quotation marks in q_row
    params[:q_row] = clean_q_rows(params)

    # Remove any blank rows from advanced search form
    params = remove_blank_rows(params)

    # Add solr fields to q based on search_field and op
    params[:q_row] = set_q_fields(params)

    # Pair queries together with booleans
    # Return final q solr param
    group_bools(params)
  end

  def solr_query(field, q)
    solr_field_prefix = field.present? ? "#{field}:" : ''
    "#{solr_field_prefix}\"#{q}\""
  end

  def solr_field_or_default(field_config, field_type)
    field_config[field_type] || field_config['field']
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
      q_string = q_words.map { |q_word| solr_query(solr_field, q_word) }.join(' OR ')
    when 'phrase'
      q_string = solr_query(solr_quoted_field, query)
    when 'begins_with'
      q_string = solr_query(solr_starts_field, query)
    else
      # Default to handling op as 'AND'
      if search_field == 'lc_callnum'
        # Don't break up lc_callnum queries
        # Call number "all" search is an inherently left-anchored search and
        #   should be sent as a single phrase to lc_callnum (e.g. lc_callnum:"ABC123 .R12")
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
    if ['phrase', 'begins_with'].include?(op)
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
  def set_q_fields(params)
    form_q_to_solr_q = []

    params[:q_row].each_with_index do |query, q_index|
      op = params[:op_row][q_index]
      search_field = params[:search_field_row][q_index]
      # Default to search_field if field not in blacklight_config.search_fields
      search_field_config = blacklight_config.search_fields[search_field] || { 'field' => search_field }

      if query.count('"') > 0
        q_string = q_with_quotes_to_solr(query, op, search_field, search_field_config)
      else
        q_string = q_to_solr(query, op, search_field, search_field_config)
      end

      # If format value exists for search_field, add format to q_string
      q_string = "(#{q_string}) AND format:\"#{search_field_config['format']}\"" if search_field_config['format']
      form_q_to_solr_q << q_string
    end

    form_q_to_solr_q
  end

  def get_sf_name(search_field)
    search_field == 'all_fields' ? '' : search_field
  end

  # Handle special characters and unpaired quotation marks in q_row
  def clean_q_rows(params)
    params[:q_row].map do |query|
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
  end

  # Pair 2 queries with booleans, wrap each pair in parentheses
  def group_bools(params)
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

  def parse_all_fields_query(query)
    return_query = ''
    tokenArray = []
    count = 0
    if query.first == '"' and query.last == '"'
      query = query[1..-2]
    end
    if query.include?(' ')
      tokenArray = query.split(' ')
      tokenArray.each do |bits|

          if bits.include?(':')
             bits.gsub!(':','\\:')
          end
          if count == 0
          return_query << bits << '"'
          else
          	if count < (tokenArray.size - 1)
               return_query << ' AND "' << bits << '" '
            else
               return_query << ' AND "' << bits
            end
          end
          count = count + 1
      end
    else
        return_query = query
    end
    return return_query
  end

  def streamline_query(user_params)
    homepage_facets = ["online", "format", "language_facet", "location", "hierarchy_facet"]
    user_params['facet.field'] = homepage_facets
    user_params['stats'] = false
    user_params['stats.field'] = []
    user_params['rows'] = 0
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
end

