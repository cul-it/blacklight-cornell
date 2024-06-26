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

  def advsearch user_parameters
    query_string = ""
    qparam_display = ""
    my_params = {}

    user_parameters[:fl] = "*" if blacklight_params["controller"] == "bookmarks" || blacklight_params["format"].present? || blacklight_params["controller"] == "book_bags"

    # secondary parsing of advanced search params.  Code will be moved to external functions for clarity
    # fix return to search links
    if blacklight_params[:q_row].present?
      blacklight_params.delete('q')

      my_params = make_adv_query(blacklight_params)
      spellstring = ""
      if !my_params[:q_row].nil?
        blacklight_params[:q_row].each do |term|
          spellstring += term += ' '
          #spellstring  += term +  ' '
        end
      else
      end
      user_parameters[:q] = my_params[:q] #blacklight_params[:q]
 #     blacklight_params[:q] = user_parameters[:q]
      user_parameters[:search_field] = "advanced"
      #user_parameters["mm"] = "100"
      user_parameters["mm"] = "1"
      user_parameters["defType"] = "edismax"
    else # simple search code below
      if blacklight_params[:q].nil?
        blacklight_params[:q] = ''
        if !blacklight_params[:f].nil?
          	user_parameters[:fq] = []
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
				  	user_parameters[:fq] << fq_string
          	    	blacklight_params[:fq] = user_parameters[:fq]
          	  	end
          	 # end
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
#      search_session[:q] = user_parameters[:show_query]
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
#          blacklight_params[:q] = blacklight_params[1..-2]
#          blacklight_params[:search_field] = blacklight_params[:search_field]#[0..-5]
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
#           blacklight_params[:q] = "(lc_callnum:" + query_string + ') OR lc_callnum:' + query_string
           blacklight_params[:q] = 'lc_callnum:' + query_string
      #      blacklight_params[:sort] = "callnum_sort asc"
           user_parameters[:search_field] = blacklight_params[:search_field]
           if blacklight_params[:sort].nil? or blacklight_params[:sort] == 'callnum_sort asc, pub_date_sort desc' #or blacklight_params[:sort] == '' or blacklight_params.nil?
             blacklight_params[:sort] = 'callnum_sort asc, pub_date_sort desc'
           end
           user_parameters[:sort] = blacklight_params[:sort]
          # user_parameters[:sort_order] = "asc"
          #user_parameters[:sort] = blacklight_params[:sort]
        end
#        user_parameters[:q] = blacklight_params[:q]


      if blacklight_params[:search_field] == 'journaltitle'
      #   blacklight_params[:search_field] = 'title'
       # if !blacklight_params[:q].include?(':')
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
#           blacklight_params[:q] = "(lc_callnum:" + query_string + ') OR lc_callnum:' + query_string
         blacklight_params[:q] =  query_string + ' AND format:Journal/Periodical'
    #      blacklight_params[:sort] = "callnum_sort asc"
         user_parameters[:search_field] = blacklight_params[:search_field]
  #       user_parameters[:f] = {'format' => ['Journal/Periodical']}
          #format << "Journal/Periodical"
 #        blacklight_params[:f] = '[format][]=Journal/Periodical'
       #  if blacklight_params[:sort].nil? or blacklight_params[:sort] == 'callnum_sort asc, pub_date_sort desc' #or blacklight_params[:sort] == '' or blacklight_params.nil?
       #    blacklight_params[:sort] = 'callnum_sort asc, pub_date_sort desc'
       #  end
       #  user_parameters[:sort] = blacklight_params[:sort]
        # user_parameters[:sort_order] = "asc"
        #user_parameters[:sort] = blacklight_params[:sort]
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
                 user_parameters[:q] = blacklight_params[:q]
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

  #        blacklight_params[:q] = "(\"lupin\" AND \"arsene\" ) OR phrase:\"lupin arsene\""
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
              user_parameters["mm"] = "1"
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
         #    	if token != ':'
                 query_string = '+' + blacklight_params[:search_field] + ':"' + token + '"'
                 clean_array << query_string
          #      end
             end
            #  Example 1: clean_array = ["+publisher:\"publisher_quoted:\"National\"", "+publisher:\"Geographic\"", "+publisher:\"Partners\"\""]
            #  Example 2: clean_array = ["+publisher:\"National\"", "+publisher:\"Geographic\"", "+publisher:\"Partners\""]
             new_query = '('
             clean_array.each do |query|
                new_query = new_query + query + ' '
             end
             new_query = new_query.rstrip
    #         if new_query.include?(':')
    #         	new_query = new_query.gsub(':','')
    #         end
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
 #      if blacklight_params[:q].include?(':')
 #      	blacklight_params[:q].gsub(':','')
 #      end
 #      user_parameters[:q] = blacklight_params[:q]

       end
    # justa placeholder
    #    blacklight_params[:q] = blacklight_params[:search_field] + ":" + blacklight_params[:q]
       # blacklight_params[:search_field] = ''
     #   blacklight_params[:q] = "(+lc_callnum:\"PQ6657.U37 P63\") OR lc_callnum_phrase:\"PQ6657.U37 P63\""
 #       if blacklight_params[:q].include?(':')
 #       	blacklight_params[:q].gsub(':','')
 #       end
        user_parameters[:q] = blacklight_params[:q]
        user_parameters[:f] = blacklight_params[:f]
        user_parameters[:sort] = blacklight_params[:sort]
       # user_parameters[:q] = 'subject_quoted:\"architecture\"'
        #user_parameters["mm"] = "100"
        user_parameters["mm"] = "1"
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

    def parseAdvQuotedQuery(quotedQuery)
      quotedQueryArray = quotedQuery.split(',')
      if quotedQuery.class == String
      	str = quotedQuery
      	quotedQueryArray = str.split(" ")
      end
      quotedQueryArray.each do | qq |
        queryArray = []
        token_string = ''
        length_counter = 0
        quote_flag = 0
    #    qq.each do |term|
          qq.each_char do | x |

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
             if x == '"' and quote_flag == 0 and
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
             if length_counter == qq.size

               queryArray << token_string
               length_counter = 0
             end

         # end
      #  quote_flag = 0
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

        length_counter = 0
        return queryArray
      end
    end


  def checkAdvMixedQuoted(params)
    newreturnArray = []
    returnArray = []
    addFieldsArray = []

    # TODO: params[:q_row] is already an array, so splitting shouldn't do anything but just nest it in another array?
    termsArray = params[:q_row].split(',')
    if termsArray.size == 1
      termsArray = params[:q_row].split(" ")
    end
    termsArray.each do | term |
      if (params[:op_row][0] == 'begins_with' && params[:search_field_row][0] == 'title')
        returnArray << 'title_starts:"' + params[:q_row][0].gsub('"', '') + '"'
      elsif params[:search_field_row][0] == 'lc_callnum'
        returnArray << 'lc_callnum:"' + params[:q_row][0].gsub('"', '') + '"'
      else
        if term.first != '"' && term.last != '"'
          if term.count('"') >= 2
            returnArray = parseAdvQuotedQuery(term)

            returnArray.each do |token|
                if params[:search_field_row] == 'all_fields'
                    if token.first == '"'
                      token = '+quoted:' + token
                    else
                      token = '+' + token
                    end
                else
                    sfr = get_sfr_name(my_params[:search_field_row])
                    if token.first == '"'
                      if !my_params[:search_field_row] == 'all_fields'
                        token = '+' + sfr + '_quoted:' + token
                      else
                        token = '+' + 'quoted:' + token
                      end
                    else
                      if !my_params[:search_field_row] == 'all_fields'
                          token = '+' + sfr +':' + token
                      else
                          token = '+' + token
                      end
                    end
                end
                addFieldsArray << token
            end
            returnArray = addFieldsArray.join
            return returnArray
          else
            returnArray << params[:q_row]
            #    return returnArray
          end
        else
          newArray = []

          clearArray = []
          newArray << term
          returnArray = parseAdvQuotedQuery(newArray)
          returnArray.each do |token|
            if params[:search_field_row][0] == 'all_fields'
              if token.first == '"'
                clearArray << '+quoted:' + token
              else
                clearArray << '+"' + token + '"'
              end
            else
              sfr = get_sfr_name(params[:search_field_row][0].to_s)

              if token.first == '"'
                if sfr != 'lc_callnum'
                  clearArray << '+' + sfr + '_quoted:' + token
                else
                  clearArray << sfr + ':' + token
                end
              else
                if sfr != 'lc_callnum'
                  clearArray << '+' + sfr + ':"' + token + '"'
                else
                  clearArray << sfr + ':' + token
                end
              end
            end
          end
          newreturnArray << clearArray.join(' ')
          #returnArray <<  returnArray

        end
      end
    end
    if !newreturnArray.empty?
      returnArray = newreturnArray
    end
    return returnArray
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
                sfr = get_sfr_name(blacklight_params[:search_field])
                if blacklight_params[:search_field] != 'all_fields'
                  token = '+' + sfr + '_quoted:' + token
                else
                  token = '+' + 'quoted:' + token
                end
              else
                sfr = get_sfr_name(blacklight_params[:search_field])
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
            sfr = get_sfr_name(blacklight_params[:search_field])
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

  # Remove any blank rows from advanced search form
  def remove_blank_rows(params)
    # Example params: {
    #   "q_row"=>["test", ""],
    #   "op_row"=>["AND", "AND"],
    #   "search_field_row"=>["all_fields", "all_fields"],
    #   "boolean_row"=>{"1"=>"AND"}
    # }
    cleaned_params = Hash.new { |h, k| h[k] = [] }
    row_count = params[:q_row].count
    row_count.times do |i|
      if params[:q_row][i].strip.present?
        # TODO: Should we handle/raise an error if # of values in each row type don't match?
        cleaned_params[:q_row] << params[:q_row][i]
        cleaned_params[:op_row] << params[:op_row][i]
        cleaned_params[:search_field_row] << params[:search_field_row][i]

        # Don't add last bool in boolean_row
        if i <= row_count - 1
          if params[:boolean_row].present? && params[:boolean_row][i.to_s.to_sym].present?
            cleaned_params[:boolean_row] << params[:boolean_row][i.to_s.to_sym]
          end
        end
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

  def make_adv_query(params)
    return if params[:q_row].blank?

    # Remove any blank rows from advanced search form
    params = remove_blank_rows(params)
    # Remove parentheses and unpaired quotation marks from q_row
    params[:q_row] = parse_q_row(params)
    # ??
    params[:q_row] = parse_QandOp_row(params)
    # ??
    # params[:q] = '(((+title:"Encyclopedia") OR title_phrase:"Encyclopedia") -springer)'
    params[:q] = group_bools(params).gsub('-+', '-')

    params

   end

   def parse_QandOp_row(params)
     index = 0
     q_rowArray = []
     q_row_string = ''
     hold_row = []
     row_number = 0

     params[:search_field_row].each do |sfr|
       q_row_string = ''
       sfr_name = get_sfr_name(sfr)
       if params[:q_row][row_number].include?('"') && params[:op_row][row_number] != 'phrase'
          hold_row = checkAdvMixedQuoted(params)
       else
          hold_row = params[:q_row][row_number]
       end

       #row_number = row_number + 1
       if !hold_row[row_number].nil? and (hold_row[row_number].include?('+') or hold_row.include?(':'))
       #  if params[:search_field_row][0] == 'all_fields'

      #    fixString = hold_row
          fixString = hold_row[row_number] #.join(' ')
          fixString = fixString.gsub('"]:',':')
          fixString = fixString.gsub('"]_','_')
          fixString = fixString.gsub('+["','+')
          fixString = fixString.gsub(']', '')
       fixString = fixString.gsub('[', '')
          q_rowArray << fixString
        #  params[:q_row][index] = fixString
       #   q_rowArray << params[:q_row].join(' ')

       #  else
          # params[:search_field_row] = params[:search_field_row][0].to_s
       #  end
       else
               if (params[:q_row][row_number][0] == "\"" or params[:q_row][row_number][1] == '"' ) and params[:op_row][index] != 'begins_with'

 	                if sfr_name == ""
                   sfr_name = "quoted:"
                 else
                   if sfr_name == 'notes_qf'
                     sfr_name = 'notes'
                   end
                   sfr_name = sfr_name + '_quoted:'
                 end
                 q_rowArray << sfr_name + params[:q_row][row_number]#.gsub!('"','')
           #      params[:q_row] = q_rowArray
               else
                 split_q_string_Array = params[:q_row][row_number].split(' ')
                 if split_q_string_Array.length > 1 and sfr_name != 'lc_callnum'
                   if params[:op_row][row_number] == 'AND'
                     split_q_string_Array.each do |add_sfr|
                       if sfr_name == ""
                         q_row_string << '+"' + add_sfr + '" '
                       else

                         q_row_string << '+' + sfr_name + ':"' + add_sfr + '" '
                       end
                     end
                     if sfr_name == '' or sfr_name == 'title' or sfr_name == 'number'
                       if sfr_name != ''
                          q_row_string = '((' + q_row_string + ') OR (' + sfr_name + '_phrase:"' + params[:q_row][index] + '"))'
                       else
                          q_row_string = '((' + q_row_string + ') OR (' + sfr_name + 'phrase:"' + params[:q_row][index] + '"))'
                       end
                     else

                       if sfr_name != 'lc_callnum'
                         q_row_string = '((' + q_row_string + ') OR (' + sfr_name + ':"' + params[:q_row][index] + '"))'
                       else
                         q_row_string = '(' + q_row_string + ')'
                        end
                     end
                     q_rowArray << q_row_string
                   end
                   if params[:op_row][row_number] == "phrase"
                      split_q_string_Array.each do |add_sfr|
                          q_row_string << add_sfr + " "
                      end

                     if sfr_name != 'lc_callnum' and sfr_name != ""
                         if sfr_name == 'notes_qf'
                           sfr_name = 'notes'
                         end
                         sfr_name = sfr_name + '_quoted'
                     else
                       sfr_name = sfr_name + ''
                     end
                      if sfr_name == '' or sfr_name == 'title' or sfr_name == 'number'
                        if sfr_name != ''
                           q_row_string = sfr_name + '_quoted:"' + params[:q_row][row_number] + '"'
                        else
                           q_row_string = sfr_name + 'quoted:"' + params[:q_row][row_number] + '"'
                        end
                      else
                        q_row_string = "(" + sfr_name + ':"' + params[:q_row][row_number] + '")'
                      end
                     q_rowArray << q_row_string
                   end
                   if params[:op_row][row_number] == 'OR'
                      split_q_string_Array.each do |add_sfr|
                        if sfr_name == ""
                          q_row_string <<  add_sfr + " OR "
                        else
                          q_row_string << sfr_name + ':' + add_sfr + " OR "
                        end
                      end
                      q_row_string = '(' + q_row_string[0..-5] + ')'
                      q_rowArray << q_row_string
                   end
                   if params[:op_row][row_number] == 'begins_with'
                        split_q_string_Array.each do |add_sfr|
                          q_row_string << add_sfr + " "
                        end

                        if sfr_name == ""
                          if q_row_string[0] == '"'
                            q_row_string = 'starts:"' + q_row_string[1..-1]
                            if q_row_string[-2] != '"'
                              q_row_string = q_row_string[0..-1] + '"'
                            end
                          else
                            q_row_string = 'starts:"' + q_row_string + '"'
                          end
                        else
                          if q_row_string[0] == '"'
                             q_row_string = sfr_name + '_starts:' + q_row_string + ''
                          else
                             q_row_string = sfr_name + '_starts:"' + q_row_string + '"'
                          end
                        end
                        q_rowArray << q_row_string
                   end
                 else
                   if params[:op_row][index] == 'begins_with'
                     q_row_string = params[:q_row][index]
                      if sfr_name == ""
                        if q_row_string[0] == '"'
                          q_row_string = 'title_starts:' + q_row_string[1..-1]
                          if q_row_string[-2] != '"'
                            q_row_string = q_row_string[0..-1] + '"'
                          end
                        else
                          q_row_string = 'starts:"' + q_row_string + '"'
                        end
                       q_rowArray << q_row_string
                      else
                        if q_row_string[0] == '"'
                           q_row_string = sfr_name + '_starts:' + q_row_string + ''
                        else
                           q_row_string = sfr_name + '_starts:"' + q_row_string + '"'
                        end
                        q_rowArray << q_row_string
                      end
                  else
                   if sfr_name != ""
                      if sfr_name == 'title' or sfr_name == 'number'
                          q_rowArray << '((+' + sfr_name + ':"' + params[:q_row][row_number] + '") OR ' + sfr_name + '_phrase:"' + params[:q_row][row_number] + '")'
                      else
                        if sfr_name != 'lc_callnum'
                          if params[:search_field_row][row_number] == 'journaltitle'
                            q_rowArray << '((+title:"' + params[:q_row][row_number] + '" OR title_phrase:"' + params[:q_row][row_number] + '") AND format:Journal/Periodical)'
                          else
                   	      	if params[:op_row][row_number] == "phrase"
                   	  	     	q_rowArray << '' + sfr_name + '_quoted:"' + params[:q_row][row_number] + '"'
                   	  	  	else
                           		q_rowArray << '((+' + sfr_name + ':"' + params[:q_row][row_number] + '") OR ' + sfr_name + ':"' + params[:q_row][row_number] + '")'
                          	end
                          end
                        else

                   	      if params[:op_row][row_number] == "phrase"
                   	      	if sfr_name == "lc_callnum"
                   	  	     q_rowArray << '' + 'quoted:"' + params[:q_row][row_number] + '"'
                   	        else
                   	  	     q_rowArray << '' + sfr_name + '_quoted:"' + params[:q_row][row_number] + '"'
                   	  	    end
                   	  	  else
                   	  	     q_rowArray << '' + sfr_name + ':"' + params[:q_row][row_number] + '"'
                   	  	  end
                        end
                      end
                   else
                   	  if params[:op_row][row_number] == "phrase"
                   	  	if params[:q_row][row_number].first == '"' && params[:q_row][row_number].last == '"'
                           q_rowArray << ' quoted:' + params[:q_row][row_number]
                        else
                           q_rowArray << ' quoted:"' + params[:q_row][row_number] + '"'
                        end

                     else
                      if params[:search_field_row][row_number] == '' or params[:search_field_row][row_number] == 'all_fields'
                        q_rowArray << '+' + params[:q_row][row_number]
                      else
                        q_rowArray << '((+"' + params[:q_row][row_number] + '") OR phrase:"' + params[:q_row][row_number] + ')'
                      end
                      end
                   end
                  end
                 end
               end
              # q_rowArray = ['(' + q_rowArray[0] + ')']
                index = index +1

       end
       row_number = row_number + 1
     end
     # q_rowArray = ['(' + q_rowArray[0] + ')']
     return q_rowArray
   end

   def get_sfr_name(sfr)
      sfr == 'all_fields' ? '' : sfr
   end

  # Remove parentheses and unpaired quotation marks from q_row
  def parse_q_row(params)
    params[:q_row].map do |row|
      # Replace left and right quotation marks with regular quotes
      row.gsub!(/[”“]/, '"')

      # Count to see if someone did not close their quotes
      numquotes = row.count '"'
      # Get rid of the offending quotes
      if numquotes == 1
        if row[0] == '"'
          row  = row + '"'
        end
      else
        # TODO: gsub doesn't actually mutate the row!! What are we trying to do here??
        # TODO: Also, what about if numquotes % 2 == 1 but numquotes > 1? Might want to just ignore all quotes in that case? But should be valid if numquotes % 2 == 0
        row.gsub('"', '')
      end
      row.gsub(/[()]/, '').gsub(':','\:')
    end
  end

  # Default any missing booleans to "AND"
  # Shouldn't happen unless directly tampering with search params
  DEFAULT_BOOL = 'AND'

  def group_bools(my_params)
     for a in 0..my_params[:q_row].size - 1 do
       if my_params[:q_row][a].include?('journaltitle:') or my_params[:q_row][a].include?('journaltitle_starts')
         my_params[:q_row][a].gsub!('journaltitle','title')
         my_params[:q_row][a] = '(' + my_params[:q_row][a] + ' AND format:Journal/Periodical )'
       end
     end

     if my_params[:q_row].size == 1
       return '( ' + my_params[:q_row][0] + ' )'
     else
       index = 0
       newstring = ""
       if my_params[:q_row].size > 1
         for a in 0..my_params[:q_row].size - 1 do
          if a == 0
            if my_params[:boolean_row][a] == "NOT"
              newstring = "(" + newstring + my_params[:q_row][a] + ' ' + "-" + my_params[:q_row][a + 1] + ") "
            else
              newstring = "(" + newstring + my_params[:q_row][a] + ' ' + (my_params[:boolean_row][a] || DEFAULT_BOOL) + " " + my_params[:q_row][a + 1] + ") "
            end
          else
            if a < my_params[:q_row].size  and a > 1
              if my_params[:boolean_row][a - 1] == "NOT"
                newstring = '( ' + newstring + ' ' + '-' + my_params[:q_row][a] + ')'
              else
                newstring = '( ' + newstring + ' ' + (my_params[:boolean_row][a - 1] || DEFAULT_BOOL) + ' ' + my_params[:q_row][a] + ')'
              end
              a = a + 1
            end
           end
           a = 1
         end
        end
       return newstring
     end
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

