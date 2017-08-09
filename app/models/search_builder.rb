# rozen_string_literal: true
# operations on strings are so prevalent must unfreeze them.
class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include BlacklightRangeLimit::RangeLimitBuilder


  #self.solr_search_params_logic += [:sortby_title_when_browsing, :sortby_callnum]
  self.default_processor_chain += [:sortby_title_when_browsing, :sortby_callnum, :advsearch]

  def sortby_title_when_browsing user_parameters
    Rails.logger.info("es287_debug #{__FILE__} #{__LINE__} #{__method__} user_parameters = #{user_parameters.inspect}")
    Rails.logger.info("es287_debug #{__FILE__} #{__LINE__} #{__method__} blacklight_params = #{blacklight_params.inspect}")
    # if no search term is submitted and user hasn't specified a sort
    # assume browsing and use the browsing sort field
    if user_parameters[:q].blank? and user_parameters[:sort].blank?
      browsing_sortby =  blacklight_config.sort_fields.values.select { |field| field.browse_default == true }.first
  #    solr_parameters[:sort] = browsing_sortby.field
    end
  end

  #sort call number searches by call number
  def sortby_callnum user_parameters
    Rails.logger.info("es287_debug #{__FILE__} #{__LINE__} #{__method__} user_parameters = #{user_parameters.inspect}")
    Rails.logger.info("es287_debug #{__FILE__} #{__LINE__} #{__method__} blacklight_params = #{blacklight_params.inspect}")
    if blacklight_params[:search_field] == 'lc_callnum' && blacklight_params[:sort].nil?
       callnum_sortby =  blacklight_config.sort_fields.values.select { |field| field.callnum_default == true }.first
      #solr_parameters[:sort] = callnum_sortby.field
       user_parameters[:sort] = callnum_sortby.field
      Rails.logger.info("es287_debug #{__FILE__} #{__LINE__} #{__method__} user_parameters = #{user_parameters.inspect}")
    end
  end

  def advsearch user_parameters
    Rails.logger.info("es287_debug #{__FILE__} #{__LINE__} #{__method__} user_parameters = #{user_parameters.inspect}")
    Rails.logger.info("es287_debug #{__FILE__} #{__LINE__} #{__method__} blacklight_params = #{blacklight_params.inspect}")
    Rails.logger.info("SQUERCH = #{blacklight_params}")
    query_string = ""
    qparam_display = ""
    my_params = {}

    # secondary parsing of advanced search params.  Code will be moved to external functions for clarity
    if blacklight_params[:q_row].present?
      my_params = make_adv_query(blacklight_params)
      #blacklight_params = my_params
      user_parameters["spellcheck.maxResultsForSuggest"] = 1
      spellstring = ""
      if !my_params[:q_row].nil?
      blacklight_params[:q_row].each do |term|
        spellstring += term += ' '
        #spellstring  += term +  ' '
      end
      
        user_parameters["spellcheck.q"]= spellstring #blacklight_params["show_query"].gsub('"','')
      else
      end
      user_parameters[:q] = blacklight_params[:q]
 #     blacklight_params[:q] = user_parameters[:q]
      Rails.logger.info("BPQ = #{user_parameters}")
      user_parameters[:search_field] = "advanced"
      user_parameters["mm"] = "1"
      user_parameters["defType"] = "edismax"
    else 
      if blacklight_params[:q].nil?
        blacklight_params[:q] = ''
      end
    # End of secondary parsing
#    search_session[:q] = user_parameters[:show_query]
      if !blacklight_params.nil? and !blacklight_params[:search_field].nil?
        if blacklight_params[:search_field] == 'call number'
           blacklight_params[:search_field] = 'lc_callnum'
        end
        if blacklight_params[:search_field] == 'author/creator'
           blacklight_params[:search_field] = 'author'
        end
        if blacklight_params[:search_field] == 'all_fields' or blacklight_params[:search_field] == ''
        blacklight_params[:q] = blacklight_params[:q]
        else
        blacklight_params[:q] = blacklight_params[:search_field] + ":" + blacklight_params[:q]
     #   blacklight_params[:q] = blacklight_params[:q]
        end
    #    blacklight_params[:q] = blacklight_params[:search_field] + ":" + blacklight_params[:q] 
       # blacklight_params[:search_field] = ''
#        blacklight_params[:q] = "(+title:ethnoarchaeology\\:) OR title:\"ethnoarchaeology\\:\""
        user_parameters[:q] = blacklight_params[:q]
        Rails.logger.info("BPS = #{blacklight_params}")
        user_parameters["mm"] = "1"
      end
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

#   def set_advanced_search_params(params)
#         # Use :advanced_search param as trustworthy indicator of search type
#         removeBlanks(params)
#         counter = test_size_param_array(params[:q_row])
#         if counter > 1
#            query_string = massage_params(params)
#            params[:advanced_search] = true
#            params["advanced_query"] = "yes"
#             holdparams = []
#             terms = []
#             ops = 0
#             params["op"] = []
##             holdparams = query_string.split("&")
#             for i in 0..params[:q_row].count - 1
#               search_session[params[:search_field_row][i]] = params[:q_row][i]
#               params[params[:search_field_row][i]] = params[:q_row][i]
#             end
#             for i in 1..params[:boolean_row].count
#               n = i.to_s
#               params["op"][i-1] = params[:boolean_row][n.to_sym]
#             end
##             if holdparams.count > 2
#             if params[:q_row].count > 1
#               params["search_field"] = "advanced"
#               params[:q] = query_string
#               search_session[:q] = query_string
#               search_session[:search_field] = "advanced"

#             else
#               params[:q] = params["q"]
#               search_session[:q] = params[:q]
#               params[:search_field] = params["search_field"]
#               search_session[:search_field] = params[:search_field]
#             end
#             params["commit"] = "Search"
##             params["sort"] = "score desc, pub_date_sort desc, title_sort asc";
#             params["action"] = "index"
#             params["controller"] = "catalog"
#       else
#            params.delete(:advanced_search)
#            params.delete("advanced_query")
#            query_string = parse_single(params)
#            holdparams = query_string.split("&")
#            for i in 0..holdparams.count - 1
#              terms = holdparams[i].split("=")
#              params[terms[0]] = terms[1]
#              search_session[terms[0]] = terms[1]
#              session[:search][:"#{terms[0]}"] = terms[1]
#              session[:search][:search_field] = params[:search_field_row][0]
#            end
#           #  params[:q] = query_string
#             params.delete("q_row")
#             params.delete("op_row")
#             params.delete("search_field_row")
#             params["commit"] = "Search"
#             params["action"] = "index"
#             params["controller"] = "catalog"
#       end
#     return query_string
#  end

  def test_size_param_array(param_array)
    countit = 0
    for i in 0..param_array.count - 1
       unless param_array[i] == "" and !param_array[i].nil?
        countit = countit + 1
       end
    end
    return countit
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
                params[:boolean_row][n.to_sym] = "OR"
              end
              new_query = " " << current_query << " " << params[:boolean_row][n.to_sym] << " " << new_query_string << " "
              rowHash[search_field_rowArray[i]] = new_query
           else
              rowHash[search_field_rowArray[i]] = new_query_string
              if params[:boolean_row][n.to_sym].nil?
                params[:boolean_row][n.to_sym] = "OR"
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
            opArray[i] = 'AND'
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
   Rails.logger.info("3616 = #{query_string_two}")
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
          returnstring = splitArray.join(' ' + op + ' ')
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
      Rails.logger.info("3616 = #{query_string}")
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
          if my_params[:q_row][i] != '' and !my_params[:q_row][i].nil?
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
            if i == my_params[:q_row].count - 1 #and  hasNonBlankcount > 1
                if !my_params[:boolean_row][i.to_s.to_sym].nil?
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
# Check to make sure this is an AS
     # IF 1
     if !my_params[:q_row].nil? and !my_params[:q_row].blank?
# Remove any blank rows in AS
       my_params = removeBlanks(my_params)
       blacklight_params = my_params
       newMyParams = {}
       for i in 0..my_params[:boolean_row].count - 1
         n = i + 1
         n = n.to_s.to_sym
         newMyParams[n] = my_params[:boolean_row][i]
       end
       my_params[:boolean_row] = newMyParams
       # IF 1.1
       if my_params[:boolean_row] == {} or my_params[:boolean_row].nil?
         my_params = makesingle(my_params)
# If reduction results in only one row return to cornell_catalog.rb
#         my_params[:boolean_row] = {"1" => "AND"}
        # my_params[:boolean_row] = blacklight_params[:boolean_row]
       #  my_params[:q] = "((+Bibliotheca +Instituti +Historici) OR \"Bibliotheca Instituti Historici\")"
         return my_params
       # end IF 1.1
       end
       
       q_string = ""
       q_string2 = ""
       q_string_hold = ""
       q_stringArray = []
       q_string2Array = []
       opArray = []
       newOpArray = []
       solr6query = ""
       journal_title_flag = 0
       # IF 1.2
       if !my_params[:boolean_row].nil? && !my_params[:search_field_row].nil?
          #convert hash to array The front end numbers boolean_row differently than the search_field, q_row arrays.
          for k in 0..my_params[:boolean_row].count - 1
             realsub = k + 1;
             n = realsub.to_s
             opArray[k] = my_params[:boolean_row][n.to_sym]
          end
          #loop on the search_fields checking the q_rows for crappy user input.
          for i in 0..my_params[:search_field_row].count - 1
              #or dimwits cutting and pasting the quotes we are checking for in the next line
              my_params[:q_row][i].gsub!('”', '"')
              #count to see if someone did not close their quotes 
              numquotes = my_params[:q_row][i].count '"'
              #get rid of the offending quotes
              if numquotes == 1
                 my_params[:q_row][i].gsub!('"', '')
              end
              my_params[:q_row][i].gsub!(/[()]/, '')
              my_params[:q_row][i].gsub!(':','\:')
         
              if my_params[:op_row][i] == "phrase" or my_params[:search_field_row][i] == 'call number'
                  numquotes = my_params[:q_row][i].count '"'
                  if numquotes > 0
                    my_params[:q_row][i].gsub!('"', '')
                  end
                  newpass = '"' + my_params[:q_row][i] + '"'
              else
                newpass = my_params[:q_row][i]
              end
              if my_params[:search_field_row][i] == 'journal title'
                my_params['format'] = "Journal/Periodical"
              end
              pass_param = { my_params[:search_field_row][i] => my_params[:q_row][i]}
              returned_query = ParsingNesting::Tree.parse(newpass)
              newstring = returned_query.to_query(pass_param)
              holdarray = newstring.split('}')
              holdarray[1] = holdarray[1].chomp('"')
           #   if my_params[:op_row][i] == "OR"
           #     holdarray[1] = parse_query_row(holdarray[1], "OR")
           #   end
              #    if my_params[:op_row][i] == 'begins_with'
              #     holdarray[1] = parse_query_row(holdarray[1], "OR")
              #    end
              q_string2 = q_string2 +  ""
Rails.logger.info("QSTRING2 = #{newstring}")
              fieldNames = blacklight_config.search_fields["#{my_params[:search_field_row][i]}"]
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
                  solr_stuff = "title"
                  journal_title_flag = 1
                end
                if solr_stuff == "notes"
                  solr_stuff = "notes_qf"
                end
                if solr_stuff == "all_fields"
                  solr_stuff = ""
                end
                field_name =  solr_stuff
#                    q_string2 << field_name << " = "
                if my_params[:op_row][i] == 'begins_with'
                  if field_name == ""
                    field_name = 'starts:'
                  else
                    if field_name == 'notes_qf'
                       field_name = 'notes_starts'
                    else
                       field_name = field_name + '_starts'
                    end
                  end
                end
                if my_params[:op_row][i] == 'phrase'
                  if field_name == ""
                    field_name = 'quoted'
#                      solr6query << field_name #<< ":"
                  else
                    if field_name == 'notes_qf'
                      field_name = 'notes_quoted'
#                      solr6query << field_name #<< ":"
                    else
                      field_name = field_name +  '_quoted'
#                      solr6query << field_name #<< ":"
                    end
                  end
                end
                      q_string2 << field_name << " = "


              end #of if
              if holdarray.count > 1 #D
                if field_name.nil?
                  field_name = ''
                end
                for j in 1..holdarray.count - 1
                   opfill = ""
                   holdarray_parse = holdarray[j].split('_query_')
                   holdarray[1] = holdarray_parse[0]
                   if(j < holdarray.count - 1)
                      if my_params[:op_row][i] == 'begins_with' or my_params[:search_field_row][i] == 'call number' or my_params[:op_row][i] == 'phrase'
                        holdarray[1].gsub!('"','')
                        holdarray[1].gsub!('\\','')
                        q_string2 << holdarray[1] 
                        if journal_title_flag == 1
                        solr6query = '(' + solr6query
                        solr6query << '"' + holdarray[1] + '") AND format:"Journal/Periodical)"'
                        journal_title_flag = 0
                        else
                        solr6query << "\"" + holdarray[1] + "\""
                        end
                      Rails.logger.info("solr6query13 = #{solr6query}")
                      else
                        tokenArray = holdarray[1].split(" ")
                        if tokenArray.size > 1
                          newTerm = " ("
                          if my_params[:op_row][i] == "AND"
                            opfill = "AND"
                          else
                            opfill = "OR"
                          end
                          for k in 0..tokenArray.size - 2
                               if field_name == ''
                                newTerm << field_name + tokenArray[k] + " " + opfill + " "
                              else
                                if opfill == "AND"
                                  newTerm << "+" << field_name + ":" + tokenArray[k] + " "
                                else
                                  newTerm << field_name + ":" + tokenArray[k] + " " + opfill + " "
                                end
                              end
                          end
                          if field_name == ''
                            newTerm << + tokenArray[tokenArray.size - 1] + ")"
                          else
                            newTerm << field_name + ":" + tokenArray[tokenArray.size - 1] + ")" 
                          end
Rails.logger.info("NEWTERM = #{newTerm}")
                          q_string2 << holdarray[1]
                          if journal_title_flag == 1
                            solr6query = '(' + solr6query
                            solr6query << newTerm << ') AND format:"Journal/Periodical)"'
                            journal_title_flag = 0
                          else
                            solr6query << newTerm
                          end
Rails.logger.info("solr6query12 = #{solr6query}")
                        else
                          q_string2 << holdarray[1]
                          if field_name == ''
                            solr6query << "(+" << field_name  + holdarray[1] + ') OR phrase:"' + holdarray[1] + ")" 
                          else
                            if journal_title_flag == 1
                              solr6query = '(' + solr6query
                              solr6query << field_name + ":" + holdarray[1] + ') AND format:"Journal/Periodical")'
                              journal_title_flag = 0
                            else
                              if field_name == "title" or field_name == "number"
                                solr6query << "((+" << field_name + ":" + holdarray[1] << ') OR ' + field_name << '_phrase:"' << holdarray[1] << '")' 
                              else
                                solr6query << "((+" << field_name + ":" + holdarray[1] << ') OR ' + field_name << ':"' << holdarray[1] << '")'
                              end
                            end
                          end
Rails.logger.info("solr6query42 = #{solr6query}")
                      end
                      end
                   else
                     if my_params[:op_row][i] == 'begins_with' or my_params[:search_field_row][i] == 'call number' or my_params[:op_row][i] == 'phrase'
                       holdarray[1].gsub!('"','')
                       holdarray[1].gsub!('\\','')
                       q_string2 << holdarray[1] << " "
                       if field_name == ''
                          solr6query << "\"" + holdarray[1] + "\""
                       else
                          if journal_title_flag == 1
                            solr6query << field_name << '"' + holdarray[1] + '" AND format:"Journal/Periodical")'
                            journal_title_flag = 0
                          else
                            solr6query << field_name << ":\"" + holdarray[1] + "\""
                          end
                       end
#Rails.logger.info("solr6query2 = #{solr6query}")
                     else
                       tokenArray = holdarray[1].split(" ")
                        if tokenArray.size > 1
                          newTerm = " ("
                          if my_params[:op_row][i] == "AND"
                            opfill = "AND"
                          else
                            opfill = "OR"
                          end
                          for k in 0..tokenArray.size - 2
                               if field_name == ''
                                newTerm << field_name + tokenArray[k] + " " +opfill + " "
                               else
                                 if opfill == "AND"
                                   newTerm << "+" << field_name + ":" + tokenArray[k] + " "
                                 else
                                   newTerm << field_name + ":" + tokenArray[k] + " " +opfill + " "
                                 end
                               end
                          end
                          if field_name == ''
                            newTerm <<  tokenArray[tokenArray.size - 1] + ")"
                          else
                            if opfill == "AND"
                              newTerm << "+" << field_name + ":" + tokenArray[tokenArray.size - 1] + ")"
                            else  
                              newTerm << field_name + ":" + tokenArray[tokenArray.size - 1] + ")"
                            end
                              if field_name == "title" or field_name == "number"
                               newTerm = "(" + newTerm + " OR " + field_name + "_phrase" + ':"' + holdarray[1] + '")'
                              else
                               newTerm = "(" + newTerm + " OR " + field_name + ':"' + holdarray[1] + '")'
                              end
                          end
Rails.logger.info("solr6query22= #{newTerm}")
                          q_string2 << holdarray[1]
                          if journal_title_flag == 1
                            solr6query << newTerm << ' AND format:"Journal/Periodical")'
                            journal_title_flag = 0
                          else
                            solr6query << newTerm
                          end
                        else
                          Rails.logger.info("solr6query23= #{solr6query}")

                          q_string2 << holdarray[1] << " "
                          if field_name == '' or field_name == "number"
                            if field_name == "number"
                              solr6query += "((+number:" + holdarray[1] + ') OR number_phrase:"' + holdarray[1] + '")' 
                            else
                              solr6query += "((+" + holdarray[1] + ') OR phrase:"' + holdarray[1] + '")'
                            end
                          else
                            if journal_title_flag == 1
                              solr6query << " (" + field_name + ":" + holdarray[1] + ' AND format:"Journal/Periodical")'
                              journal_title_flag = 0
                            else
                              solr6query << "((+" + field_name + ":" + holdarray[1] + ') OR ' + field_name + ':"' + holdarray[1] + '")'
                            end
                          end 
                        end
                     end

                   end
                end
              else #D
                q_string2 = q_string2 #<< holdarray[1]
#Rails.logger.info("solr6query2 = #{solr6query}")

              end #D
              if i < my_params[:q_row].count - 1 && !opArray[i].nil?
                q_string2 << " "
                if journal_title_flag == 1
                solr6query << " " + opArray[i] + " ("
                else
                solr6query << " " + opArray[i] + " "
                end  
              end
              
              q_string2Array << q_string2
              q_string2 = "";
Rails.logger.info("solr6query80 = #{solr6query}")
           end #of For C
           #fix opArray
        #   opArray = opArray.shift
        ####   test_q_string = groupBools(q_stringArray, opArray)
          test_q_string2 = groupBools(q_string2Array, opArray)
        #  test_q_string2 = solr6query
           my_params[:show_query] = test_q_string2.gsub!('(', '')
           if !my_params[:show_query].nil?
             my_params[:show_query] = my_params[:show_query].gsub!(')','')
             my_params[:show_query] = my_params[:show_query].gsub!('_starts','')
           end
         end #B
       else #A
         if params[:search_field] == "call number" and !my_params[:q].nil? and !my_params[:q].include?('"')
           params[:q] = '"' + my_params[:q] + '"'
         end
         session[:search][:q] = my_params[:q]
         session[:search][:counter] = my_params[:counter]
         session[:search][:search_field] = my_params[:search_field]
         session[:search].delete(:q_row)
         params.delete(:q_row)
         my_params.delete(:boolean_row)
         session[:search].delete(:boolean_row)
         session[:search]["search_field"] = my_params["search_field"]
         #    solr_parameters[:q] = my_params[:q]
         #    solr_parameters[:sort] = "score desc, title_sort asc"
         my_params[:search_field] = my_params["search_field"]
         params[:search_field] = my_params[:search_field]
         session[:search][:search_field] = my_params[:search_field]

       end #A
       if my_params[:advanced_query] == 'yes'
         #   solr_parameters[:defType] = "lucene"
       end
       if my_params[:show_query].nil? && !test_q_string2.nil?
        my_params[:show_query] = test_q_string2
       end
   #  my_params["q"] = "+title:either/or AND author:Kierkegaard"  
   #  my_params["q"] = "title:bauhaus OR subject:design"  
   #  my_params["q"] = "(+title:bauhaus) NOT (+subject:design)"  
    # my_params["q"] = "(title:bauhaus)OR (subject:design)"  
   #  my_params["q"] = "mm=1&q.op=OR&q=(title:bauhaus) OR subject:design"  
   #  my_params["q"] = "title_starts:\"South\" NOT title_starts:\"South Africa\" NOT title_starts:\"South Carolina\""
   #  my_params["q"] = "title:Minnesota AND  (author:Office OR author:of OR author:Personnel OR author:Management) NOT title_starts:\"small\""
  #   my_params["q"] = "+marvel +masterworks"
  #  solr6query = "(notes:English, AND notes:German, AND notes:Italian, AND notes:Latin, AND notes:or AND notes:Portugese)" # AND ((+Bibliotheca +Instituti +Historici) OR \\\"Bibliotheca Instituti Historici\\\")" 
    #solr6query = '(title_starts:"Science advances" AND format:"Journal/Periodical") OR (title_starts:"advances" AND format:"Journal/Periodical")'  
         if journal_title_flag == 1
           solr6query = '(' + solr6query
         end
#         solr6query = '( (+number:L +number:37) OR number_phrase:"L 37") AND  ( (+number:L _number:37) OR number_phrase:"L 37")'
#       solr6query = '((+title:David +title:Copperfield) OR title_phrase:"David Copperfield") AND ((+author:Charles +author:Dickens) OR author:"Charles Dickens")'
Rails.logger.info("FINISH1 = #{solr6query}")    
         my_params["q"] = solr6query 
       return my_params

  end  #def
  
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
                       query << "starts:"
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
                        query << field_name << ':'
                    end
                  end
                end
          if my_params[:q_row].count == 1
            qarray = my_params[:q_row][0].split
            newq = '('
            if qarray.size == 1
              if qarray[0].include?(':')
                qarray[0].gsub!(':','\:')
              end
               if field_name == '' and (op_name != 'begins_with' and op_name != 'phrase')
                 newq << qarray[0] << ') OR "' << qarray[0] << '"'
               else 
                 if op_name == 'begins_with' or op_name == 'phrase' or field_name == 'lc_callnum:'
                   if qarray[0].start_with? '"' and qarray[0].end_with? '"'
                     qarray[0] = qarray[0][1...-1]
                   end
                   
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
                   newq = '(' + newq
                   newq << '+' << field_name << '"' << qarray[0] << '") OR ' << field_name << '"' << qarray[0] << '") AND format:"Journal/Periodical"'
                   journal_title_flag = 0
                   else
                   newq << '+' << field_name << '"' << qarray[0] << '") OR ' << field_name << '"' << qarray[0] << '"'
                   end
                 else
                   if journal_title_flag == 1
                   newq = '(' + newq
                   newq << '+' << field_name << ":" << qarray[0] << ') OR ' << field_name << ':"' << qarray[0] << '") AND format:"Journal/Periodical"'
                   journal_title_flag = 0
                   else
                     if field_name == '' or field_name == 'title' or field_name == 'number'
                       if field_name == ''
                         newq << '+' << qarray[0] << ') OR ' << 'phrase:"' << qarray[0] << '"'
                       else
                         newq << '+' << field_name << ':' << qarray[0] << ') OR ' << field_name << '_phrase:"' << qarray[0] << '"'
                       end
                     else
                      newq << '+' << field_name << ":" << qarray[0] << ') OR ' << field_name << ':"' << qarray[0] << '"'
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
                newq = '(' + newq
                newq << '+' << field_name << '"' << my_params[:q_row][0] << '") OR ' << field_name << '"' << my_params[:q_row][0] << '") AND format:"Journal/Periodical"'
                journal_title_flag = 0
               else
                newq << '+' << field_name << '"' << my_params[:q_row][0] << '") OR ' << field_name << '"' << my_params[:q_row][0] << '"'
               end
              else  
               qarray.each do |bits|
                 if bits.include?(':')
                   bits.gsub!(':','\:')
                 end
                  if field_name == ''
                     newq << '+' << bits << ' '
                  else
                     newq << '+' << field_name << ':' << bits << ' '
                  end
               end
               if field_name == ''
                  newq << ') OR "' << my_params[:q_row][0] << '"'
               else
                 if journal_title_flag == 1
                  newq = '(' + newq
                  newq << ') OR ' << field_name << ':"' << my_params[:q_row][0] << '") AND format:"Journal/Periodical"'
                  journal_title_flag = 0
                 else
                   if field_name == 'title' or field_name == 'number' or field_name == ''
                     if field_name == ''
                       newq << ') OR phrase:"' << my_params[:q_row[0]] << '"'
                     else
                       newq << ') OR ' << field_name << '_phrase:"' << my_params[:q_row][0] << '"'
                     end
                   else  
                     newq << ') OR ' << field_name << ':"' << my_params[:q_row][0] << '"'
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
       my_params.delete(:q_row)
       my_params.delete(:op_row)
       my_params.delete(:search_field_row)
       my_params.delete(:boolean_row)
   #    my_params[:q] = "subject:(+hydrology) OR \"hydrology\""
        my_params[:mm] = 1
        blacklight_params = my_params
#        my_params[:q] = "(+number:L +number:37.30 ) OR number_phrase:\"L 37.30\""
        Rails.logger.info("FINISHER = #{my_params}")
    return my_params
  
  end
  def groupBools(q_stringArray, opArray)
     grouped = []
     newString = q_stringArray.flatten
     if !q_stringArray.nil?
       newString = q_stringArray[0];
       for i in 0..opArray.count - 1
         if !q_stringArray[i + 1].nil?
          newString = newString + " " + opArray[i] + " ( "+ q_stringArray[i + 1]
         end
       end
     else
     end
     if !newString.nil?
       newString = newString.gsub('author/creator','author')
     end
     closingparensNum = newString.count('(')
     for i in 1..closingparensNum
       newString = newString + ')'
       i = i + 1
     end
     #newString = newString.gsub('"',"")
#     newString =  "_query_:{!edismax}bauhaus  AND ( _query_:{!edismax spellcheck.dictionary=subject qf=$subject_qf pf=$subject_pf}architecture  NOT  _query_:{!edismax spellcheck.dictionary=subject qf=$subject_qf pf=$subject_pf}graphic design )"
#     newString =  "_query_:{!edismax qf=$lc_callnum_qf pf=$lc_callnum_pf}\"PQ7798.416.A43\"\" AND  _query_:{!edismax spellcheck.dictionary=title qf=$title_qf pf=$title_pf}\"00\""
#     newString =  "_query_:{!edismax qf=$lc_callnum_qf pf=$lc_callnum_pf}\"PR2983 .I61\"\""
#     newString =  "_query_:{!edismax qf=$author_qf pf=$author_pf}Shakespeare"
     #NEWSTRING = \"PQ7798.416.A43 H6\""   AND title = hora"
#     if newString.include?(')') && !newString.include?('(')
#       newString.gsub!(')','')
#     end
#     if newstring.count(')') > newString.count('(')
       
#     end
     if newString.include?('%26')
       newString.gsub!('%26','&')
     end
    # newString = "_query_:{!edismax spellcheck.dictionary=title_starts qf=$title_starts_qf pf=$title_starts_pf}rat\"\"  OR  _query_:{!edismax spellcheck.dictionary=subject_starts qf=$subject_starts_qf pf=$subject_starts_pf}war\"\""
 #    newString = "_query_:{!edismax spellcheck.dictionary=subject qf=$subject_qf pf=$subject_pf}bauhaus\"\"  AND  _query_:{!edismax spellcheck.dictionary=title qf=$title_qf pf=$title_pf}history\"\"" #  OR  _query_:{!edismax spellcheck.dictionary=title qf=$title_qf pf=$title_pf}design\"\""
     return newString
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
  
end
