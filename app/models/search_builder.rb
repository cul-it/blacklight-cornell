# frozen_string_literal: true
class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include BlacklightRangeLimit::RangeLimitBuilder


  #self.solr_search_params_logic += [:sortby_title_when_browsing, :sortby_callnum]
  self.default_processor_chain += [:sortby_title_when_browsing, :sortby_callnum, :advsearch]

  def sortby_title_when_browsing user_parameters
    # if no search term is submitted and user hasn't specified a sort
    # assume browsing and use the browsing sort field
    if user_parameters[:q].blank? and user_parameters[:sort].blank?
      browsing_sortby =  blacklight_config.sort_fields.values.select { |field| field.browse_default == true }.first
  #    solr_parameters[:sort] = browsing_sortby.field
    end
  end

  #sort call number searches by call number
  def sortby_callnum user_parameters
    if user_parameters[:search_field] == 'call number'
      callnum_sortby =  blacklight_config.sort_fields.values.select { |field| field.callnum_default == true }.first
      solr_parameters[:sort] = callnum_sortby.field
    end
  end

  def advsearch user_parameters
    query_string = ""
    qparam_display = ""
    my_params = {}
    # secondary parsing of advanced search params.  Code will be moved to external functions for clarity
    if blacklight_params[:q_row].present?
      Rails.logger.info("GOOGOO = #{blacklight_params}")
      my_params = make_adv_query(blacklight_params)
      Rails.logger.info("GOOGOO1 = #{my_params}")
      #blacklight_params = my_params
      user_parameters["spellcheck.maxResultsForSuggest"] = 1
      spellstring = ""
      blacklight_params[:q_row].each do |term|
        spellstring << term << ' '
      end
        user_parameters["spellcheck.q"]= spellstring #blacklight_params["show_query"].gsub('"','')
      user_parameters[:q] = my_params[:q]
      user_parameters[:search_field] = "advanced"
      user_parameters["mm"] = "1"
      user_parameters["defType"] = "edismax"
      Rails.logger.info("FINISH4 = #{user_parameters}")
    end
    # End of secondary parsing
#    search_session[:q] = user_parameters[:show_query]
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

   def set_advanced_search_params(params)
         # Use :advanced_search param as trustworthy indicator of search type
         removeBlanks(params)
         counter = test_size_param_array(params[:q_row])
         if counter > 1
            query_string = massage_params(params)
            params[:advanced_search] = true
            params["advanced_query"] = "yes"
             holdparams = []
             terms = []
             ops = 0
             params["op"] = []
#             holdparams = query_string.split("&")
             for i in 0..params[:q_row].count - 1
               search_session[params[:search_field_row][i]] = params[:q_row][i]
               params[params[:search_field_row][i]] = params[:q_row][i]
             end
             for i in 1..params[:boolean_row].count
               n = i.to_s
               params["op"][i-1] = params[:boolean_row][n.to_sym]
             end
#             if holdparams.count > 2
             if params[:q_row].count > 1
               params["search_field"] = "advanced"
               params[:q] = query_string
               search_session[:q] = query_string
               search_session[:search_field] = "advanced"

             else
               params[:q] = params["q"]
               search_session[:q] = params[:q]
               params[:search_field] = params["search_field"]
               search_session[:search_field] = params[:search_field]
             end
             params["commit"] = "Search"
#             params["sort"] = "score desc, pub_date_sort desc, title_sort asc";
             params["action"] = "index"
             params["controller"] = "catalog"
       else
            params.delete(:advanced_search)
            params.delete("advanced_query")
            query_string = parse_single(params)
            holdparams = query_string.split("&")
            for i in 0..holdparams.count - 1
              terms = holdparams[i].split("=")
              params[terms[0]] = terms[1]
              search_session[terms[0]] = terms[1]
              session[:search][:"#{terms[0]}"] = terms[1]
              session[:search][:search_field] = params[:search_field_row][0]
            end
           #  params[:q] = query_string
             params.delete("q_row")
             params.delete("op_row")
             params.delete("search_field_row")
             params["commit"] = "Search"
             params["action"] = "index"
             params["controller"] = "catalog"
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

def oldremoveBlanks(params)
     queryRowArray = [] #params[:q_row]
     booleanRowArray = [] #params[:boolean_row]
     subjectFieldArray = [] #params[:search_field_row]
     opRowArray = [] #params[:op_row]
     boolHoldHash = {}
     qrowIndexes = []
     qrowSize = params[:q_row].count
     booleanRowCount = 1
     for i in 0..qrowSize - 1 
       n = (i + 1).to_s
       if params[:q_row][i] != ""
         qrowIndexes << i
         queryRowArray << params[:q_row][i]
         opRowArray <<  params[:op_row][i]
         subjectFieldArray << params[:search_field_row][i]
       end
       if qrowIndexes[0] == 0
         for i in 1..qrowIndexes.count - 1
           n = qrowIndexes[i].to_s
           boolHoldHash["#{booleanRowCount}"] = params[:boolean_row][n.to_sym]
           booleanRowCount = booleanRowCount + 1
         end
       else
 #not sure if needed yet      
       end
    end
     params[:q_row] = queryRowArray
     params[:op_row] = opRowArray
     params[:search_field_row] = subjectFieldArray
     params[:boolean_row] = boolHoldHash

     return params
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
       for i in 1..my_params[:boolean_row].count 
          if !my_params[:q_row][i - 1].blank? and !my_params[:q_row][i - 1].nil?
            if !my_params[:q_row][i].nil? and !my_params[:q_row][i].blank?
              testBRow << my_params[:boolean_row][i.to_s.to_sym]
            end
         # else
         #   testBRow << my_params[:boolean_row][i.to_s.to_sym]
          end
       end
        Rails.logger.info("TESTBROW = #{testBRow}")
        Rails.logger.info("TESTBROWq = #{testQRow}")
        Rails.logger.info("TESTBROWo = #{testOpRow}")
        Rails.logger.info("TESTBROWs = #{testSFRow}")
        my_params[:q_row] = testQRow
        my_params[:op_row] = testOpRow
        my_params[:search_field_row] = testSFRow
        my_params[:boolean_row] = testBRow
       return my_params
     end
    def make_adv_query(my_params = params || {})
# Check to make sure this is an AS
     # IF 1
     Rails.logger.info("GOOGOO2 = #{my_params}")
     if !my_params[:q_row].nil? || !my_params[:q_row].blank?
# Remove any blank rows in AS
       my_params = removeBlanks(my_params)
       blacklight_params = my_params
       Rails.logger.info("MYPARAMS1 = #{my_params}")
       newMyParams = {}
       for i in 0..my_params[:boolean_row].count - 1
         n = i + 1
         n = n.to_s.to_sym
         newMyParams[n] = my_params[:boolean_row][i]
       end
       my_params[:boolean_row] = newMyParams
     Rails.logger.info("GOOGOO3 = #{my_params[:boolean_row]}")
     Rails.logger.info("GOOGOO2 = #{my_params}")
     Rails.logger.info("GOOGOO3 = #{blacklight_params}")
       
       # IF 1.1
       if my_params[:boolean_row].nil?
         my_params = makesingle(my_params)
# If reduction results in only one row return to cornell_catalog.rb
#         my_params[:boolean_row] = {"1" => "AND"}
         my_params[:boolean_row] = blacklight_params[:boolean_row]
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
                my_params['format'] = "Journal"
              end
              pass_param = { my_params[:search_field_row][i] => my_params[:q_row][i]}
              returned_query = ParsingNesting::Tree.parse(newpass)
              newstring = returned_query.to_query(pass_param)
              Rails.logger.info("FINISH0 = #{newstring}")
              holdarray = newstring.split('}')
              holdarray[1] = holdarray[1].chomp('"')
           #   if my_params[:op_row][i] == "OR"
           #     holdarray[1] = parse_query_row(holdarray[1], "OR")
           #   end
              #    if my_params[:op_row][i] == 'begins_with'
              #     holdarray[1] = parse_query_row(holdarray[1], "OR")
              #    end
              q_string2 = q_string2 +  ""

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
                  solr_stuff = "journal title"
                end
                if solr_stuff == "notes"
                  solr_stuff = "notes_qf"
                end
                field_name =  solr_stuff
                if field_name == "journal title"
                    if my_params[:op_row][i] == 'begins_with'
                      field_name = "title_starts"
                    else
                      field_name = "title"
                    end
                    q_string2 << field_name << " = "
  
                else
                  if my_params[:op_row][i] == 'begins_with'
                      if field_name == 'all_fields'
                         field_name = " starts:"
                         solr6query << field_name 
                      else
                        q_string2 << field_name << "_starts"<< " = "
                        solr6query << " " << field_name << "_starts:"
                      end
                  else
                      q_string2 << field_name << " = "
           #           solr6query << field_name << ":"
                  end
                end

              end #of if
              if holdarray.count > 1 #D
                if field_name.nil?
                  field_name = 'all_fields'
                end

                for j in 1..holdarray.count - 1
                   opfill = ""
                   holdarray_parse = holdarray[j].split('_query_')
                   holdarray[1] = holdarray_parse[0]
                   if(j < holdarray.count - 1)
                      if my_params[:op_row][i] == 'begins_with' || my_params[:search_field_row][i] == 'call number' #|| my_params[:op_row][i] == 'phrase'
                        holdarray[1].gsub!('"','')
                        holdarray[1].gsub!('\\','')
                        q_string2 << holdarray[1]
                        solr6query << "\"" + holdarray[1] + "\""
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
                                newTerm << field_name + ":" + tokenArray[k] + " " + opfill + " "
                          end
                          newTerm << field_name + ":" + tokenArray[tokenArray.size - 1] + ")" 
                          Rails.logger.info("WOOK = #{newTerm}")
                          q_string2 << holdarray[1]
                          solr6query << newTerm
                        else
                          q_string2 << holdarray[1]
                          solr6query << field_name + ":" + holdarray[1] 
                      end
                      end
                   else
                     if my_params[:op_row][i] == 'begins_with'|| my_params[:search_field_row][i] == 'call number' # || my_params[:op_row][i] == 'phrase'
                       holdarray[1].gsub!('"','')
                       holdarray[1].gsub!('\\','')
                       q_string2 << holdarray[1] << " "
                       solr6query << "\"" + holdarray[1] + "\""
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
                                newTerm << field_name + ":" + tokenArray[k] + " " +opfill + " "
                          end
                          newTerm << field_name + ":" + tokenArray[tokenArray.size - 1] + ")"
                          Rails.logger.info("WOOK = #{newTerm}")
                          q_string2 << holdarray[1]
                          solr6query << newTerm
                        else

                        Rails.logger.info("WOOK = #{tokenArray}")
                        Rails.logger.info("WOOK1 = #{tokenArray.size}")
                       q_string2 << holdarray[1] << " "
                       solr6query << " " + field_name + ":" + holdarray[1] 
                     end
                     end

                   end
                end
              else #D
                q_string2 = q_string2 #<< holdarray[1]

              end #D
              if i < my_params[:q_row].count - 1 && !opArray[i].nil?
                q_string2 << " "
                   Rails.logger.info("OPARRAYL = #{i}")
                Rails.logger.info("OPARRAYM = #{opArray[i]}")

                solr6query << " " + opArray[i] + " "
              end
              q_string2Array << q_string2
              q_string2 = "";

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
     Rails.logger.info("FINISH1 = #{solr6query}")    
     Rails.logger.info("FINISH2 = #{my_params["q"]}")    


     my_params["q"] = solr6query 
       return my_params

  end  #def
  
  def makesingle(my_params)
    op_name = my_params[:op_row][0]
    query = my_params[:q_row][0]
    field_name = my_params[:search_field_row][0]
    op_name = my_params[:op_row][0]
    query = "_query_:\\\"{!edismax "
    
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
                  solr_stuff = "journal title"
                end
                field_name =  solr_stuff
                if field_name == "journal title"
                    if my_params[:op_row][i] == 'begins_with'
                      field_name = "title_starts"
                    else
                      field_name = "title"
                    end
                    query << " qf=$" 
                    if field_name == 'all_fields'
                      query << "qf pf=$pf"
                    else
                      query << field_name << "_qf pf=$" << field_name << "_pf format=Journal"
                    end
                   # q_string2 << field_name << " = "
                   # q_string_hold << " qf=$" + field_name + "_qf pf=$" + field_name + "_pf format=Journal"
  
                else
                  if op_name == 'begins_with'
                      query << " qf=$" 
                      if field_name == 'all_fields'
                        query << "starts_qf pf=$starts_pf"
                      else
                        query << field_name << "_starts_qf pf=$" << field_name << "_starts_pf"
                      end
                  #    q_string2 << field_name << "_starts"<< " = "
                  #    q_string_hold << " qf=$" + field_name + "_starts_qf pf=$" + field_name + "_starts_pf"
                  #    Rails.logger.info("BERNICE2 = #{q_string}")
                  else
                      query << " qf=$" 
                      if field_name == 'all_fields'
                        query << "qf pf=$pf"
                      else
                        query << field_name << "_qf pf=$" << field_name << "_pf"
                      end
                    #  q_string2 << field_name << " = "
                    #  q_string_hold << " qf=$" + field_name + "_qf pf=$" + field_name + "_pf"
                  end
                end

              end 
          if my_params[:q_row].count == 1
            querystring = my_params[:q_row][0]
            if field_name == "lc_callnum"
              query = "_query_:\"{!edismax  qf=$lc_callnum_qf pf=$lc_callnum_pf}\"" + querystring + "\\\" "
            else   
              query = query << "}" + querystring + "\""
            end
            my_params[:q] = query #   "_query_:\"{!edismax  qf=$lc_callnum_qf pf=$lc_callnum_pf}\"1451621175\\\" "#OR (  _query_:\"{!edismax  qf=$title_qf pf=$title_pf}catch-22\")"
          end
    return my_params
  
  end
  def groupBools(q_stringArray, opArray)
     grouped = []
#     rightParens = opArray.length
#     closingparens = ""
#     i = 1
#     Rails.logger.info("OPARRAY = #{opArray}")
#     while i <= rightParens do
#       closingparens = closingparens + ")"
#       i += 1
#     end
 #    Rails.logger.info("FLATTER0 = #{q_stringArray}")
     newString = q_stringArray.flatten
 #    Rails.logger.info("FLATTER = #{newString}")
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

#  def parse_for_stemming(params)
#    query_string = params[:q]
#    search_field = params[:search_field]
##    unless query_string.nil?
#     if query_string =~ /^\".*\"$/ or query_string.include?('"')
#       Rails.logger.info("STEMfullstringquoted = #{query_string}")
#       params[:search_field] = params[:search_field] + '_quote'
#       return query_string
#     else 
#       unless query_string.nil?
#         params[:q_row] = parse_stem(query_string)
#         Rails.logger.info("PARSER Returned = #{params[:q_row]}")
#       end
#       return query_string       
#     end
##    end
#  end
  
#  def parse_stem(query_string)
#    string_chars = query_string.chars
#    Rails.logger.info("PARSER = #{string_chars}")
#    quoteFlag = 0
#    wordArray = []
##   if !query_string == /^\".*\"$/ # query_string.include?('"')
#   if !(query_string.start_with?('"') and query_string.end_with?('"')) #.*\"$/ # query_string.include?('"')
#    Rails.logger.info("POOP #{query_string}")
#    search_field = params[:search_field]
#    params[:q_row] = []
#    params[:search_field_row] = []
#    params[:op_row] = []
#    params[:op] = []
#    params[:boolean_row] = {}
#    params[:q] = ""
#    string_chars.each do |i|
#      if i == '"'
#        if quoteFlag == 1  #left hand quote already encountered this must be right hand quote
#          wordArray << i
#          params[:q] << i
#          params[:q_row] << wordArray.join.strip  #right hand quote means end of section add to params[:q_row]
#          params[:op_row] << "phrase"
#          params[:search_field_row] << search_field + "_quote"
#          quoteFlag = 0 #reset quote flag
#          wordArray = [] #clear out wordArray
#        else # must be left hand quote
#          if !wordArray.empty?
#            params[:q_row] << wordArray.join.strip
#            params[:op_row] << "AND"
#            params[:search_field_row] << search_field
#            wordArray = []
#          end
#          quoteFlag = 1
#          wordArray << i
#          params[:q] << i
#        end
#      else
#        wordArray << i
#        params[:q] << i
#      end
#    end
#    if !wordArray.empty?
#      if quoteFlag == 1
#        wordArray << '"'
#        params[:q]<< '"'
#        Rails.logger.info("GLADYS = #{wordArray}")
#        params[:q_row] << wordArray.join.strip
#        params[:op_row] << "phrase"
#        params[:search_field_row] << search_field + "_quote"
#        wordArray = []
#        quoteFlag = 0
#      else 
#        if quoteFlag == 0
#        Rails.logger.info("GLADYS1 = #{wordArray}")
#          params[:q_row] << wordArray.join.strip
#           params[:op_row] << "AND"
#          params[:search_field_row] << search_field 
#         wordArray = []
#        end
#      end
#    end 
#    times = params[:q_row].count
#    for j in 1..times -1
#      x = j
#      n = x.to_s
#      params[:boolean_row]["#{j}"] = "AND"
#      params[:op][j - 1] = "AND"
#    end
#    Rails.logger.info("PUTREFLIP = #{params}")
#    return params
#   else
#     return query_string
#   end
#  end
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
