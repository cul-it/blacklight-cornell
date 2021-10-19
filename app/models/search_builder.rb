# frozen_string_literal: false
# operations on strings are so prevalent must unfreeze them.
class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include BlacklightRangeLimit::RangeLimitBuilder

# again add a comment so we can do a trivial PR
  #self.solr_search_params_logic += [:sortby_title_when_browsing, :sortby_callnum]
  self.default_processor_chain += [:sortby_title_when_browsing, :sortby_callnum, :advsearch, :homepage_default]
#  self.default_processor_chain += [:advsearch]

  def sortby_title_when_browsing user_parameters 

   # Rails.logger.info("es287_debug #{__FILE__} #{__LINE__} #{__method__} user_parameters = #{user_parameters.inspect}")
   # Rails.logger.info("es287_debug #{__FILE__} #{__LINE__} #{__method__} blacklight_params = #{blacklight_params.inspect}")
    # if no search term is submitted and user hasn't specified a sort
    # assume browsing and use the browsing sort field
    if user_parameters[:q].blank? and user_parameters[:sort].blank?
      browsing_sortby =  blacklight_config.sort_fields.values.select { |field| field.browse_default == true }.first
  #    solr_parameters[:sort] = browsing_sortby.field
    end
  end

  # Removes unnecessary elements from the solr query when the homepage is loaded.
  # The check for the q parameter ensures that searches, including empty searches, and
  # advanced searches are not affected.
  def homepage_default user_parameters
    if user_parameters['q'].nil? && user_parameters['fq'].size == 0
      user_parameters = streamline_query(user_parameters)
    end
  end

  #sort call number searches by call number
  def sortby_callnum user_parameters
   # Rails.logger.info("es287_debug #{__FILE__} #{__LINE__} #{__method__} user_parameters = #{user_parameters.inspect}")
   # Rails.logger.info("es287_debug #{__FILE__} #{__LINE__} #{__method__} blacklight_params = #{blacklight_params.inspect}")
    if blacklight_params[:search_field] == 'lc_callnum' && blacklight_params[:sort].nil?
       callnum_sortby =  blacklight_config.sort_fields.values.select { |field| field.callnum_default == true }.first
      #solr_parameters[:sort] = callnum_sortby.field
       user_parameters[:sort] = callnum_sortby.field
   #   Rails.logger.info("es287_debug #{__FILE__} #{__LINE__} #{__method__} user_parameters = #{user_parameters.inspect}")
    end
  end

  def advsearch user_parameters
    #user_parameters[:q] = 'title_starts:"Mad bad and dangerous to know"'
#    if blacklight_params[:search_field] == 'title_starts'
#      user_parameters[:q] = blacklight_params[:search_field] + ':' + blacklight_params[:q]
#    end
#    blacklight_params[:q] = 'title_starts:"Mad bad and dangerous to know"'
#    Rails.logger.info("es287_debug #{__FILE__} #{__LINE__} #{__method__} user_parameters = #{user_parameters.inspect}")
#    Rails.logger.info("es287_debug #{__FILE__} #{__LINE__} #{__method__} blacklight_params = #{blacklight_params.inspect}")
#    blacklight_params[:q] = 'title_starts:"Mad bad and dangerous to know"'

    query_string = ""
    qparam_display = ""
    my_params = {}
    if !blacklight_params[:search_field_row].nil? and blacklight_params[:search_field_row[0]] == "publisher number/other identifier"
      blacklight_params[:search_field_row[0]] = "number"
    end
    if !blacklight_params[:search_field].nil? and blacklight_params[:search_field] == "publisher number/other identifier"
      blacklight_params[:search_field] = "number"
    end


    user_parameters[:fl] = "*" if blacklight_params["controller"] == "bookmarks" || blacklight_params["format"].present? || blacklight_params["controller"] == "book_bags"

    # secondary parsing of advanced search params.  Code will be moved to external functions for clarity
    # fix return to search links 
    if blacklight_params[:q_row].present? and blacklight_params[:q].present?
      blacklight_params.delete('q')
    end

    if blacklight_params[:q_row].present? and blacklight_params[:q].blank?
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
      #check for author/creator param
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
        #check for author/creator param
        if blacklight_params[:search_field] == 'author/creator' or blacklight_params[:search_field] == 'author%2Fcreator'
          blacklight_params[:search_field] = 'author'
        end
 
        #check for call number search
        if blacklight_params[:search_field] == 'call number'
           blacklight_params[:search_field] = 'lc_callnum'
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

        
      if blacklight_params[:search_field] == 'journal title'
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
                # returned_query = simple_fix(returned_query)
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
#           user_parameters[:q] = blacklight_params[:q]            
           #Not an all fields search test if query is quoted
          if blacklight_params[:q].first == '"' and blacklight_params[:q].last == '"' and blacklight_params[:q].count('"') == 2 and blacklight_params[:search_field] != 'journal title' and blacklight_params[:search_field] != 'lc_callnum' and !blacklight_params[:search_field].include?('_cts')
            if blacklight_params[:search_field] == 'author' or blacklight_params[:search_field == 'author_quoted']
              if blacklight_params[:search_field] == 'author_quoted' 
                blacklight_params[:q] = blacklight_params[:search_field] + ':' + blacklight_params[:q]
              else
                blacklight_params[:q] =  blacklight_params[:search_field] + '_quoted:' + blacklight_params[:q]
              end 
            end  
            if blacklight_params[:search_field] == 'publisher' or blacklight_params[:search_field == 'publisher_quoted']
              if blacklight_params[:search_field] == 'publisher_quoted' 
                blacklight_params[:q] = blacklight_params[:search_field] + ':' + blacklight_params[:q]
              else
                blacklight_params[:q] =  blacklight_params[:search_field] + '_quoted:' + blacklight_params[:q]
              end 
            end  
            if blacklight_params[:search_field] == 'title' or blacklight_params[:search_field] == 'title_quoted' or blacklight_params[:search_field] == 'subject' or blacklight_params[:search_field] == 'subject_quoted'
              if blacklight_params[:search_field] == 'subject_quoted' or blacklight_params[:search_field] == 'title_quoted'
                blacklight_params[:q] = '(+' + blacklight_params[:search_field] + ':' + blacklight_params[:q] + ')'
              else
                blacklight_params[:q] =  blacklight_params[:search_field] + '_quoted:' + blacklight_params[:q]
     #           blacklight_params[:q] =   blacklight_params[:q]
              end 
            end
            if blacklight_params[:search_field] == 'title_starts'
              blacklight_params[:q] = blacklight_params[:search_field] + ':' + blacklight_params[:q]
            end
#          if blacklight_params[:search_field] == 'authortitle_browse' #= 'title_starts'
#            blacklight_params[:q] = blacklight_params[:search_field] + ":" + blacklight_params[:q]

          else
            #check if this is a crazy multi quoted multi token search
            if blacklight_params[:q].include?('"') and blacklight_params[:search_field] != 'title_starts' and blacklight_params[:search_field] != 'series' and blacklight_params[:search_field] != 'lc_callnum' and blacklight_params[:search_field] != 'journal title' and !blacklight_params[:search_field].include?('_cts')
               if blacklight_params[:search_field] == 'author/creator'
                  blacklight_params[:search_field] = 'author'
               end
               if blacklight_params[:q].first != '('
                 if blacklight_params[:q].include?('"')
                   query_string = '('
                   return_query = checkMixedQuoted(blacklight_params)

                   return_query.each do |token|
                   query_string = query_string + token + ' '
                 end
                 query_string = query_string.rstrip
                 query_string = query_string + ')'
                 blacklight_params[:q] = query_string
               end
            else
              blacklight_params[:search_field] = 'author'
              blacklight_params[:q] = blacklight_params[:search_field] + ':' + blacklight_params[:q]
            end
         #   user_parameters["mm"] = "100"
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
        ['title_starts','series','journal title','lc_callnum'].include?(blacklight_params[:search_field])
      )
         query_array = blacklight_params[:q].split(' ')
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
             new_query = '('
             clean_array.each do |query|
                new_query = new_query + query + ' '
             end
             new_query = new_query.rstrip
    #         if new_query.include?(':')
    #         	new_query = new_query.gsub(':','')
    #         end
             if blacklight_params[:search_field] == 'title' or blacklight_params[:search_field] == 'number'
             	if !blacklight_params[:q].include?('title_quoted')  and !blacklight_params[:q].include?('subject_quoted')
              		new_query = new_query + ') OR ' + blacklight_params[:search_field] + '_phrase:"' + blacklight_params[:q] + '"'
                else
                	new_query = blacklight_params[:q]
                end
             else
              if blacklight_params[:q].first == '"' and blacklight_params[:q].last == '"'
                new_query = new_query + ') OR ' + blacklight_params[:search_field] + ':' + blacklight_params[:q]
              else
              	if !blacklight_params[:q].include?('title_quoted') and !blacklight_params[:q].include?('subject_quoted')
                  new_query = new_query + ') OR '  + blacklight_params[:search_field] + ':"' + blacklight_params[:q] + '"'
                else
                  new_query = blacklight_params[:q]
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
  
  def simple_fix(returned_query)
    tokenArray = returned_query.split(' ')
    if tokenArray.size == 1
      returned_query = '"' + returned_query + '"'
      return returned_query
    else
      test_string = ''
      tokenArray.each do | token |
        if token[0] == '+'
          token.gsub!('+','')
        end
        test_string = test_string + '+"' + token + '" '
      end
      return test_string
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
  
  
    def checkAdvMixedQuoted(my_params)
      newreturnArray = []
        returnArray = []
        addFieldsArray = []
        termsArray = my_params[:q_row].split(',')
        if termsArray.size == 1
        	termsArray = my_params[:q_row].split(" ")
        end
        termsArray.each do | term |
	
          if (my_params[:op_row][0] == 'begins_with' and my_params[:search_field_row][0] == 'title') or my_params[:search_field_row][0] == 'call number'
            if my_params[:op_row][0] == 'begins_with'
               returnArray << 'title_starts:"' + my_params[:q_row][0].gsub!('"', '') + '"'
            else
               returnArray << 'lc_callnum:"' + my_params[:q_row][0].gsub!('"', '') + '"'
            end
          else
              if term.first != '"' and term.last != '"'
                 if term.count('"') >= 2
                    returnArray = parseAdvQuotedQuery(term)

                    returnArray.each do |token|
                        if my_params[:search_field_row] == 'all_fields'
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
                    returnArray << my_params[:q_row]
                    #    return returnArray
                 end
              else
                newArray = []

                clearArray = []
                newArray << term
                returnArray = parseAdvQuotedQuery(newArray)
                returnArray.each do |token|
                  if my_params[:search_field_row][0] == 'all_fields'
                    if token.first == '"'
                      clearArray << '+quoted:' + token
                    else
                      clearArray << '+"' + token + '"'
                    end
                  else
                    sfr = get_sfr_name(my_params[:search_field_row][0].to_s)
                    
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
                newreturnArray << clearArray.join( ' ')
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
                if !blacklight_params[:search_field] == 'all_fields'
                  token = '+' + sfr + '_quoted:' + token
                else
                  token = '+' + 'quoted:' + token
                end
              else
                sfr = get_sfr_name(blacklight_params[:search_field])
                if !blacklight_params[:search_field] == 'all_fields'
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

  def cjk_query_addl_params(params)
    if params && params.has_key?(:q)
      q_str = (params[:q] ? params[:q] : '')
      num_uni = num_cjk_uni(q_str)
      if num_uni > 2
        solr_params.merge!(cjk_mm_qs_params(q_str))
      end

      if num_cjk_uni(params[:q]) > 0
        cjk_query_addl_params({}, params)
      end

      if num_uni > 0
        case params[:search_field]
          when 'all_fields', nil
           solr_params[:q] = "{!qf=$qf pf=$pf pf3=$pf3 pf2=$pf2}#{q_str}"
          when 'title'
           solr_params[:q] = "{!qf=$title_qf pf=$title_pf pf3=$title_pf3 pf2=$title_pf2}#{q_str}"
          when 'author/creator'
           solr_params[:q] = "{!qf=$author_qf pf=$author_pf pf3=$pf3_author_pf3 pf2=$author_pf2}#{q_str}"
          when 'journal title'
           solr_params[:q] = "{!qf=$journal_qf pf=$journal_pf pf3=$journal_pf3 pf2=$journal_pf2}#{q_str}"
          when 'subject'
           solr_params[:q] = "{!qf=$subject_qf pf=$subject_pf pf3=$subject_pf3 pf2=$subject_pf2}#{q_str}"
        end
      end
    end
  end

  def cjk_mm_val
    silence_warnings { @@cjk_mm_val = '3<86%'}
  end

  def cjk_mm_qs_params(str)
 #   cjk_mm_val = []
    num_uni = num_cjk_uni(str)
    if num_uni > 2
      num_non_cjk_tokens = str.scan(/[[:alnum]]+/).size
      if num_non_cjk_tokens > 0
        lower_limit = cjk_mm_val[0].to_i
        mm = (lower_limit + num_non_cjk_tokens).to_s + cjk_mm_val[1, cjk_mm_val.size]
        {'mm' => mm, 'qs' => 0}
      else
        {'mm' => cjk_mm_val, 'qs' => 0}
      end
    else
      {}
    end
  end


  def num_cjk_uni(str)
    if str
      str.scan(/\p{Han}|\p{Katakana}|\p{Hiragana}|\p{Hangul}/).size
    else
      0
    end
  end


  def test_size_param_array(param_array)
    countit = 0
    for i in 0..param_array.count - 1
       unless param_array[i] == "" and !param_array[i].nil?
        countit = countit + 1
       end
    end
    return countit
  end
  
  def parse_simple_search_query(blacklight_params)
    return_query = ''
    simp_search_field = blacklight_params[:search_field]
    simp_search_query = blacklight_params[:q]
 #   if simp_search_field != 'title_starts'
    qArray = simp_search_query.split(' ')
    if qArray.size > 1
      qArray.each do |token|
        token = '+' + simp_search_field + ':' + token + ' '
        return_query << token
      end
      return_query = return_query[0..-2]
      if simp_search_field != 'title_starts'
      return_query = '(' + return_query + ') OR ' + simp_search_field + '_phrase:"' + blacklight_params[:q] + '"'
      else 
        return_query = simp_search_field + ':"' + blacklight_params[:q] + '"'
      end
    else
      return_query = '(+' + simp_search_field + ':' + qArray[0] + ') OR ' + simp_search_field + '_phrase:"' + qArray[0] + '"'  
    end
    return return_query
  end

  def massage_params(params)
    rowHash = {}
    opArray = []
    query_string = ""
    new_query_string = ""
    query_rowArray = params[:q_row]
    op_rowArray = params[:op_row]
#    if params[:op_row] == "begins_with"
#      params[:search_field_row] = params[:search_field_row] + "_starts"
#    end
    search_field_rowArray = params[:search_field_row]
    if query_rowArray.count > 1
#first row
       if query_rowArray[0] != ""
         new_query_string = parse_query_row(query_rowArray[0], op_rowArray[0])
         rowHash[search_field_rowArray[0]] = new_query_string
         new_query_string = ""
       end

       for i in 1..query_rowArray.count - 1
         n = i.to_s
         if query_rowArray[i] != ""
           new_query_string = parse_query_row(query_rowArray[i], op_rowArray[i])
           if rowHash.has_key?(search_field_rowArray[i])
              current_query = rowHash[search_field_rowArray[i]]
              if params[:boolean_row][n.to_sym].nil?
                params[:boolean_row][n.to_sym] = " OR "
              end
              new_query = " " << current_query << " " << params[:boolean_row][n.to_sym] << " " << new_query_string << " "
              rowHash[search_field_rowArray[i]] = new_query
           else
              rowHash[search_field_rowArray[i]] = new_query_string
              if params[:boolean_row][n.to_sym].nil?
                params[:boolean_row][n.to_sym] = " OR "
              end
              opArray << params[:boolean_row][n.to_sym]
           end
         end
       end
       opcount = 0;
       query_string_two = ""
       newArray = rowHash.flatten
       keywordscount = newArray.count / 2
       for i in 0..keywordscount -1
         if i < keywordscount - 1
          if opArray[i].nil?
            opArray[i] = ' AND '
          end
          if opArray[i] == "begins_with"
            query_string_two << newArray[i*2] << "=" << newArray[(i*2)+1] << ""
          else
            query_string_two << newArray[i*2] << "=" << newArray[(i*2)+1] << "&op[]=" << opArray[i] << "&"
          end
         else
          query_string_two << newArray[i*2] << "=" << newArray[(i*2)+1] << ""
         end
       end
       #account for some bozo not selecting different search_fields
       bozocheck = query_string_two.split("=")
       if bozocheck.count < 3
         query_string_two = "q=" + bozocheck[1] + "&search_field=" + bozocheck[0]
         params["search_field"] = bozocheck[0]
         params.delete("advanced_query")
       end
    end
   return query_string_two
  end

  def parse_query_row(query, op)
    splitArray = []
    returnstring = ""
    if !query.nil?
     if query.include?('%26')
       query.gsub!('%26','&')
     end
     query.gsub!("&","%26")
     if op == "phrase" or op == "begins_with"
       query.gsub!("\"", "\'")
#       returnstring << '"' << query << '"'
       returnstring = query
     else
       splitArray = query.split(" ")
       if splitArray.count > 1
         # returnstring = splitArray.join(' ' + op + ' ')
         return string = '"' + splitArray.join() + '"'
       else
          returnstring = query
       end
     end
    end
    return returnstring
  end


  def parse_single(params)
    query_string = ""
    query_rowArray = params[:q_row]
    op_rowArray = params[:op_row]

    if params[:op_row][0] == "begins_with"
      params[:search_field_row][0] = params[:search_field_row][0] + "_starts"
      search_field_rowArray = params[:search_field_row]

    else
     search_field_rowArray = params[:search_field_row]
    end
      for i in 0..query_rowArray.count - 1
         if query_rowArray[i] != ""
           query_string << "q="
           query_rowSplitArray = query_rowArray[i].split(" ")
           if(query_rowSplitArray.count > 1 && op_rowArray[i] != "phrase")
             if op_rowArray[i] == 'begins_with'

             query_string << query_rowSplitArray[0] << " "
             else
             query_string << query_rowSplitArray[0] << " " #<< op_rowArray[i] << " "
             end
             for j in 1..query_rowSplitArray.count - 2
               if !op_rowArray[i] == 'begins_with'
                query_string << query_rowSplitArray[j] << " " << op_rowArray[i] << " "
               else
                query_string << query_rowSplitArray[j] << " "
               end
             end
             query_string << query_rowSplitArray[query_rowSplitArray.count - 1] << "&search_field=" << search_field_rowArray[i]
           elsif(query_rowSplitArray.count > 1 && op_rowArray[i] == "phrase" )
             query_rowArray[i].gsub!("\"", "\'")
             query_string << '"' << query_rowArray[i] << '"&search_field=' << search_field_rowArray[i]
             query_string << query_rowArray[i] << "&search_field=" << search_field_rowArray[i]
           else
             query_string << query_rowArray[i] << "&search_field=" << search_field_rowArray[i]
           end
         end
      end
      return query_string
  end

  def test_size_param_array(param_array)
    countit = 0
    for i in 0..param_array.count - 1
       unless param_array[i] == "" and !param_array[i].nil?
        countit = countit + 1
       end
    end
    return countit
  end

    def removeBlanks(my_params = params || {} )
       testQRow = [] #my_params[:q_row]
       testOpRow = []
       testSFRow = []
       testBRow = []
       for i in 0..my_params[:q_row].count - 1
         if (my_params[:q_row][i] != '' and !my_params[:q_row][i].nil?) and my_params[:q_row][i] != ' '
             testQRow << my_params[:q_row][i]
             testOpRow << my_params[:op_row][i]
             testSFRow << my_params[:search_field_row][i]
          end
       end
       hasNonBlankcount = 0
       for i in 0..my_params[:q_row].count - 1
          if my_params[:q_row][i].blank? or my_params[:q_row][i].nil?
          #  if i == 0
          #    next
          #  end
          #  if i == my_params[:q_row].count - 1
              next
          #  end
          else
            hasNonBlankcount = hasNonBlankcount + 1
            if i <= my_params[:q_row].count - 1 #and  hasNonBlankcount > 1
                if !my_params[:boolean_row].nil? and !my_params[:boolean_row][i.to_s.to_sym].nil?
                testBRow << my_params[:boolean_row][i.to_s.to_sym]
                end
            end
 #           if i < my_params[:q_row].count - 1 #and (hasNonBlankcount > 1 and my_params[:q_row][i + 1].blank?)
 #               if !my_params[:boolean_row][i.to_s.to_sym].nil?
 #               testBRow << my_params[:boolean_row][i.to_s.to_sym]
 #               end
 #           end
          end
       end
        my_params[:q_row] = testQRow
        my_params[:op_row] = testOpRow
        my_params[:search_field_row] = testSFRow
        my_params[:boolean_row] = testBRow
          return my_params
     end

   def make_adv_query(my_params = params || {})
     if !my_params[:q_row].nil? and !my_params[:q_row].blank?
# Remove any blank rows in AS

       my_params = removeBlanks(my_params)
 
         q_rowArray = parse_Q_row(my_params)
         
         my_params[:q_row] = q_rowArray
         my_params[:q_row] = parse_QandOp_row(my_params)
         test_q_string2 = groupBools(my_params)
         if test_q_string2.include?('-+')
         	test_q_string2.gsub!('-+','-')
         end
      #   test_q_string2 = '(((+title:"Encyclopedia") OR title_phrase:"Encyclopedia") -springer)'
        my_params[:q] = test_q_string2
      return my_params
     end
   end

   def parse_QandOp_row(my_params)
     index = 0
     q_rowArray = []
     q_row_string = ''
     hold_row = []
     row_number = 0
     
     my_params[:search_field_row].each do |sfr|
       q_row_string = ""
       sfr_name = get_sfr_name(sfr)
       if my_params[:q_row][row_number].include? '"' and my_params[:op_row][row_number] != "phrase"
          hold_row = checkAdvMixedQuoted(my_params)
       else
          hold_row = my_params[:q_row][row_number]
       end
       
       #row_number = row_number + 1
       if !hold_row[row_number].nil? and (hold_row[row_number].include?('+') or hold_row.include?(':'))
       #  if my_params[:search_field_row][0] == 'all_fields'

      #    fixString = hold_row
          fixString = hold_row[row_number] #.join(' ')
          fixString = fixString.gsub('"]:',':')
          fixString = fixString.gsub('"]_','_')
          fixString = fixString.gsub('+["','+')
          fixString = fixString.gsub(']', '')
       fixString = fixString.gsub('[', '')
          q_rowArray << fixString
        #  my_params[:q_row][index] = fixString
       #   q_rowArray << my_params[:q_row].join(' ')
            
       #  else
          # my_params[:search_field_row] = my_params[:search_field_row][0].to_s
       #  end
       else
               if (my_params[:q_row][row_number][0] == "\"" or my_params[:q_row][row_number][1] == '"' ) and my_params[:op_row][index] != 'begins_with'
                     
 	                if sfr_name == ""
                   sfr_name = "quoted:"
                 else
                   if sfr_name == 'notes_qf'
                     sfr_name = 'notes'
                   end
                   sfr_name = sfr_name + '_quoted:'
                 end
                 q_rowArray << sfr_name + my_params[:q_row][row_number]#.gsub!('"','')
           #      my_params[:q_row] = q_rowArray
               else
                 split_q_string_Array = my_params[:q_row][row_number].split(' ')
                 if split_q_string_Array.length > 1 and sfr_name != 'lc_callnum'
                   if my_params[:op_row][row_number] == 'AND' 
                     split_q_string_Array.each do |add_sfr|
                       if sfr_name == ""
                         q_row_string << '+"' + add_sfr + '" '
                       else
                         
                         q_row_string << '+' + sfr_name + ':"' + add_sfr + '" '
                       end
                     end
                     if sfr_name == '' or sfr_name == 'title' or sfr_name == 'number'
                       if sfr_name != ''
                          q_row_string = '((' + q_row_string + ') OR (' + sfr_name + '_phrase:"' + my_params[:q_row][index] + '"))'
                       else
                          q_row_string = '((' + q_row_string + ') OR (' + sfr_name + 'phrase:"' + my_params[:q_row][index] + '"))'
                       end
                     else
                       
                       if sfr_name != 'lc_callnum'
                         q_row_string = '((' + q_row_string + ') OR (' + sfr_name + ':"' + my_params[:q_row][index] + '"))'
                       else
                         q_row_string = '(' + q_row_string + ')'
                        end
                     end
                     q_rowArray << q_row_string
                   end
                   if my_params[:op_row][row_number] == "phrase"
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
                           q_row_string = sfr_name + '_quoted:"' + my_params[:q_row][row_number] + '"'
                        else
                           q_row_string = sfr_name + 'quoted:"' + my_params[:q_row][row_number] + '"'
                        end
                      else
                        q_row_string = "(" + sfr_name + ':"' + my_params[:q_row][row_number] + '")'
                      end
                     q_rowArray << q_row_string
                   end
                   if my_params[:op_row][row_number] == 'OR'
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
                   if my_params[:op_row][row_number] == 'begins_with'
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
                   if my_params[:op_row][index] == 'begins_with'
                     q_row_string = my_params[:q_row][index]
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
                          q_rowArray << '((+' + sfr_name + ':"' + my_params[:q_row][row_number] + '") OR ' + sfr_name + '_phrase:"' + my_params[:q_row][row_number] + '")'
                      else
                        if sfr_name != 'lc_callnum'
                          if my_params[:search_field_row][row_number] == 'journal title'
                            q_rowArray << '((+title:"' + my_params[:q_row][row_number] + '" OR title_phrase:"' + my_params[:q_row][row_number] + '") AND format:Journal/Periodical)'
                          else
                   	      	if my_params[:op_row][row_number] == "phrase"
                   	  	     	q_rowArray << '' + sfr_name + '_quoted:"' + my_params[:q_row][row_number] + '"'
                   	  	  	else
                           		q_rowArray << '((+' + sfr_name + ':"' + my_params[:q_row][row_number] + '") OR ' + sfr_name + ':"' + my_params[:q_row][row_number] + '")'
                          	end
                          end   
                        else
                        	
                   	      if my_params[:op_row][row_number] == "phrase"
                   	      	if sfr_name == "lc_callnum"
                   	  	     q_rowArray << '' + 'quoted:"' + my_params[:q_row][row_number] + '"'
                   	        else
                   	  	     q_rowArray << '' + sfr_name + '_quoted:"' + my_params[:q_row][row_number] + '"'
                   	  	    end
                   	  	  else
                   	  	     q_rowArray << '' + sfr_name + ':"' + my_params[:q_row][row_number] + '"'
                   	  	  end                         
                        end
                      end
                   else
                   	  if my_params[:op_row][row_number] == "phrase"
                   	  	if my_params[:q_row][row_number].first == '"' and my_params[:q_row][row_number].last == '"'
                           q_rowArray << ' quoted:' + my_params[:q_row][row_number] 
                        else
                           q_rowArray << ' quoted:"' + my_params[:q_row][row_number] + '"'                        
                        end
                       
                     else
                      if my_params[:search_field_row][row_number] == '' or my_params[:search_field_row][row_number] == 'all_fields'
                        q_rowArray << '+' + my_params[:q_row][row_number] 
                      else
                        q_rowArray << '((+"' + my_params[:q_row][row_number] + '") OR phrase:"' + my_params[:q_row][row_number] + ')'
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
      if sfr == "author/creator"
        sfr = "author"
      end
      if sfr == "call number"
        sfr = "lc_callnum"
      end
      if sfr == "place of publication"
        sfr = "pubplace"
      end
      if sfr == "publisher number/other identifier"
        sfr = "number"
      end
      if sfr == "isbn/issn"
        sfr = "isbnissn"
      end
      if sfr == "donor name"
        sfr = "donor"
      end
      if sfr == "journal title"
        sfr = "journaltitle"
        #journal_title_flag = 1
      end
      if sfr == "notes"
        sfr = "notes"
      end
      if sfr == "all_fields"
        sfr = ""
      end
      return sfr
   end


   def parse_Q_row(my_params)
     q_rowArray = []
     my_params[:q_row].each do |row|
       row.gsub!('”', '"')
       row.gsub!('“', '"')
       #count to see if someone did not close their quotes
       numquotes = row.count '"'
       #get rid of the offending quotes
       if numquotes == 1
          if row[0] == '"'
             row  = row + '"'
          end
       else
          row.gsub('"', '')
       end
       row.gsub!(/[()]/, '')
       row.gsub!(':','\:')
       q_rowArray << row
     end
     return q_rowArray
   end

  def makesingle(my_params)
    op_name = my_params[:op_row][0]
    query = my_params[:q_row][0]
    field_name = my_params[:search_field_row][0]
    op_name = my_params[:op_row][0]
    query = ""
    journal_title_flag = 0
              fieldNames = blacklight_config.search_fields["#{field_name}"]
              if !fieldNames.nil?
                solr_stuff = fieldNames["key"]
                if solr_stuff == "author/creator"
                  solr_stuff = "author"
                end
                if solr_stuff == "call number"
                  solr_stuff = "lc_callnum"
                end
                if solr_stuff == "place of publication"
                  solr_stuff = "pubplace"
                end
                if solr_stuff == "publisher number/other identifier"
                  solr_stuff = "number"
                end
                if solr_stuff == "isbn/issn"
                  solr_stuff = "isbnissn"
                end
                if solr_stuff == "donor name"
                  solr_stuff = "donor"
                end
                if solr_stuff == "journal title"
                  my_params[:f] = {}
                  solr_stuff = "title"
                  format = []
                  format << "Journal/Periodical"
                  my_params[:f][:format] = format
                  journal_title_flag = 1
                end
                if solr_stuff == "notes"
                  solr_stuff = "notes_qf"
                end
                if solr_stuff == "series"
                  solr_stuff = "series"
                end
                if solr_stuff == "all_fields"
                  solr_stuff = ''
                end
                field_name = solr_stuff
                if op_name == 'begins_with'
                    query << ""
                    if field_name == 'all_fields'
                       query << "starts"
                    else
                      if field_name == 'notes_qf'
                       query << 'notes_starts:'
                      else
                       query << field_name << "_starts:"
                      end
                    end
                 else
                    if op_name == 'phrase'
                      query << ""
                      if field_name == ''
                        query << "quoted:"
                      else
                        if field_name == 'notes_qf'
                          query << 'notes_quoted:'
                        else
                          if field_name != 'lc_callnum'
                            query << field_name << "_quoted:"
                          end
                        end
                      end
                    else
                      if field_name != ''
                        query << field_name << ':'
                      end
                    end
                  end
                end
          if my_params[:q_row].count == 1
            qarray = qtoken(my_params[:q_row][0])
            newq = '('
            if qarray.size == 1
              if qarray[0].include?(':')
                qarray[0].gsub!(':','\:')
              end
               if field_name == '' and (op_name != 'begins_with' and op_name != 'phrase')
                 if qarray[0].first == '"' and qarray[0].last == '"'
                   if field_name == ''
                     newq << "quoted:" << qarray[0] << ')'
                   else
                     newq << field_name << "_quoted:" << qarray[0] << ')'
                   end
                 end
               else
                 if op_name == 'begins_with' or op_name == 'phrase' or field_name == 'lc_callnum:'
                   if qarray[0].first == '"' and qarray[0].last ==  '"'
                     qarray[0] = qarray[0][1...-1]
                   end

                   if op_name == 'begins_with'
                      if field_name == ''
                         field_name = 'starts'
                      else
                        if field_name == 'notes_qf'
                          field_name = 'notes_starts:'
                        else
                         field_name = field_name + '_starts:'
                        end
                      end
                   else
                      if op_name == 'phrase'
                        if field_name == ''
                           field_name = 'quoted:'
                        else
                           if field_name == 'notes_qf'
                              field_name = 'notes_quoted:'
                           else
                            if field_name != 'lc_callnum'
                             field_name = field_name + '_quoted:'
                            else
                             field_name = field_name + ':'
                            end
                           end
                        end
                      else
                       field_name = field_name + ':'
                      end
                   end

                   if journal_title_flag == 1
                   newq = '' + newq
                   newq << '' << field_name << ':' << qarray[0] << '' #") OR ' << field_name << '"' << qarray[0] << '") AND format:"Journal/Periodical"'
                   journal_title_flag = 0
                   else
                   newq << '' << field_name << ':' << qarray[0] << '")'# OR ' << field_name << '"' << qarray[0] << '"'
                   end
                 else
                   if journal_title_flag == 1
                   newq = '' + newq
                   newq << '' << field_name << ":" << qarray[0] << ''#) OR ' << field_name << ':"' << qarray[0] << '") AND format:"Journal/Periodical"'
                   journal_title_flag = 0
                   else
                     if field_name == '' or field_name == 'title' or field_name == 'number'
                       if field_name == ''
                         newq << '' << qarray[0] << '' # OR ' << 'phrase:"' << qarray[0] << '"'
                       else
                         newq << '' << field_name << ':' << qarray[0] << ''# OR ' << field_name << '_phrase:"' << qarray[0] << '"'
                       end
                     else
                      newq << '' << field_name << ":" << qarray[0] << ''# OR ' << field_name << ':"' << qarray[0] << '"'
                     end
                   end
                 end
               end
            else
              if op_name == 'begins_with' or op_name == 'phrase' or field_name == 'lc_callnum'
                   if op_name == 'begins_with'
                          if field_name == ''
                             field_name = 'starts:'
                          else
                            if field_name == 'notes_qf'
                              field_name = 'notes_starts:'
                            else
                             field_name = field_name + '_starts:'
                            end
                          end
                          if my_params[:q_row][0].start_with? '"' and my_params[:q_row][0].end_with? '"'
                            my_params[:q_row][0] = my_params[:q_row][0][1...-1]
                          end

                   else
                          if op_name == 'phrase'
                                 if field_name == ''
                                    field_name = 'quoted:'
                                 else
                                       if field_name == 'notes_qf'
                                          field_name = 'notes_quoted:'
                                       else
                                            if field_name != 'lc_callnum'
                                             field_name = field_name + '_quoted:'
                                            else
                                             field_name = field_name + ':'
                                            end
                                       end
                                 end
                          else
                              field_name = field_name + ':'
                          end
                   end
                   if journal_title_flag == 1
                    newq = '' + newq
                    newq << '' << field_name << '"' << my_params[:q_row][0] << '"'# OR ' << field_name << '"' << my_params[:q_row][0] << '") AND format:"Journal/Periodical"'
                    journal_title_flag = 0
                   else
                    newq << '' << field_name << '"' << my_params[:q_row][0] << '"'# OR ' << field_name << '"' << my_params[:q_row][0] << '"'
                   end
              else
                  newqcount = 1
                  quoted = ''
                  quotedUnder = ''
                  qarray.each do |bits|
                        if bits.include?(':')
                          bits.gsub!(':','\:')
                        end
                        if bits.include?('"')
                          bits.gsub!('"','\"')
                        end
                        if bits.first == '\\' and bits.last == '"'
                          if field_name == ''
                            quoted = ' quoted:'
                          else
                            if field_name == 'notes_qf'
                               quoted = 'notes_quoted:'
                            else
                              if field_name != 'lc_callnum'
                                quoted = field_name + '_quoted:'
                              else
                                quoted = field_name
                              end
                            end
                          end
                        else
                          if field_name != ''
                            quoted = field_name + ':'
                          else
                            quoted = ''
                          end
                        end
                        if field_name == '' and op_name == 'AND'
                          if bits.first == '\\' and bits.last == '"'
                            newq << '+quoted:' << bits << ' '
                          else
                           newq << '+' << bits << ' '
                          end
                        else
                           if op_name == 'AND'
                             if field_name != ''
                               newq << '+' << quoted << '_quoted:' << bits << ' '
                             else
                               newq << '+' << bits << ' '
                             end
                           else
                             if newqcount < qarray.size
                               if field_name == ''
                                newq << quoted << bits << ' OR '
                               else
                                newq << quoted << bits << ' OR '
                               end
                               newqcount = newqcount + 1
                             else
                               if field_name == ''
                                 newq << bits << ' '
                               else
                                 newq << quoted << bits << ' '
                               end
                             end
                           end
                        end
                   end
                   if field_name == ''
                      newq << ')'# OR "' << my_params[:q_row][0] << '"'
                   else
                         if journal_title_flag == 1
                          newq = '' + newq
                          newq << '' # OR ' << field_name << ':"' << my_params[:q_row][0] << '") AND format:"Journal/Periodical"'
                          journal_title_flag = 0
                         else
                               if field_name == 'title' or field_name == 'number' or field_name == ''
                                       if field_name == ''
                                         newq << ''# OR phrase:"' << my_params[:q_row[0]] << '"'
                                       else
                                         newq << ''# OR ' << field_name << '_phrase:"' << my_params[:q_row][0] << '"'
                                       end
                               else
                                 newq << ''# OR ' << field_name << ':"' << my_params[:q_row][0] << '"'
                               end
                         end
                   end
              end
          end#encoding: UTF-8

#            querystring = newq #my_params[:q_row][0]
#            if field_name == "lc_callnum" or op_name == "phrase" or op_name == "begins_with"
#              query = "\"" + querystring + "\" "
#            else
#              query = query << querystring
#            end
            my_params[:q] = newq #query #   "_query_:\"{!edismax  qf=$lc_callnum_qf pf=$lc_callnum_pf}\"1451621175\\\" "#OR (  _query_:\"{!edismax  qf=$title_qf pf=$title_pf}catch-22\")"
          end
        my_params[:mm] = 1
        blacklight_params = my_params
  #      my_params[:q] = '(madness OR quoted:"mentally ill" OR quoted:"mental illness" OR insanity )' # OR phrase:("madness "mentally ill" "mental illness" insanity")'
        #Rails.logger.info("FINISHER = #{my_params}")
    return my_params

  end

  def qtoken(q_string)
    qnum = q_string.count('"')
    if qnum % 2 == 1
      q_string = q_string + '"'
    end
      q_string.gsub!('(','')
      q_string.gsub!(')','')
      p = q_string.split(/\s(?=(?:[^"]|"[^"]*")*$)/)
    return p

  end

  def groupBools(my_params)
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
         #newstring = my_params[:q_row][0]
         for a in 0..my_params[:q_row].size - 1 do
          if a == 0
                 if my_params[:boolean_row][a] == "NOT"
                 	newstring = "(" + newstring + my_params[:q_row][a] + ' ' + "-" + my_params[:q_row][a + 1] + ") "
                 else
                 	newstring = "(" + newstring + my_params[:q_row][a] + ' ' + my_params[:boolean_row][a] + " " + my_params[:q_row][a + 1] + ") "
                 end
          else
            if a < my_params[:q_row].size  and a > 1
                 if my_params[:boolean_row][a - 1] == "NOT"
                         newstring = '( ' + newstring + ' ' + '-' + my_params[:q_row][a] + ')'
                 else
                         newstring = '( ' + newstring + ' ' + my_params[:boolean_row][a - 1 ] + ' ' + my_params[:q_row][a] + ')'
                 end
                a = a + 1
             #newstring = '(' + my_params[:q_row][index] + ' )' + bool + '( ' + my_params[:q_row][index + 1] + ')'
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
        
  def reorderBooleanRow(paramshash)
    newHash = {}
    newKey = 1
    paramshash.each do |key, value|
      n = newKey.to_s
      newHash[n.to_sym] = value
      newKey = newKey + 1
    end
   return newHash
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

