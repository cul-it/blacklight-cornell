module CornellParamsHelper

   def set_advanced_search_params(params)
         # Use :advanced_search param as trustworthy indicator of search type
         counter = test_size_param_array(params[:q_row])
         if counter > 1
            query_string = massage_params(params)
            params[:advanced_search] = true
            params["advanced_query"] = "yes"
             holdparams = []
             terms = []
             ops = 0
             params["op"] = []
             holdparams = query_string.split("&")
             for i in 0..holdparams.count - 1
                terms = holdparams[i].split("=")
                if (terms[0] == "op[]")
                  params["op"][ops] = terms[1]
                  ops = ops + 1
                else
                  params[terms[0]] = terms[1]
                  search_session[terms[0]] = terms[1]
                end
             end
             if holdparams.count > 2
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
#            search_session = {}
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
#             params[:search_field] = 
#             params["search_field"] = "Sippy"
       end
     return query_string
  end

    def solr_search_params(my_params = params || {})
    solr_parameters = {}
  if !my_params[:q_row].nil?
    solr_search_params_logic.each do |method_name|
      send(method_name, solr_parameters, my_params)
    end
    q_string = ""
    q_string2 = ""
    q_string_hold = ""
    q_stringArray = []
    q_string2Array = []
    opArray = []
    if !my_params[:boolean_row].nil?    
      for k in 0..my_params[:boolean_row].count - 1
         realsub = k + 1;
         n = realsub.to_s
         opArray[k] = my_params[:boolean_row][n.to_sym]
      end
      for i in 0..my_params[:q_row].count - 1
         if my_params[:op_row][i] == "phrase"
           newpass = '"' + my_params[:q_row][i] + '"' 
         else
           newpass = my_params[:q_row][i]
         end 
         pass_param = { my_params[:search_field_row][i] => my_params[:q_row][i]}
         returned_query = ParsingNesting::Tree.parse(newpass)
         newstring = returned_query.to_query(pass_param)
         holdarray = newstring.split('}')
         queryStart = " _query_:\"{!dismax"
         q_string << " _query_:\"{!dismax" # spellcheck.dictionary=" + blacklight_config.search_field['#{field_queryArray[0]}'] + " qf=$" + blacklight_config.search_field['#{field_queryArray[0]}'] + "_qf pf=$" + blacklight_config.search_field['#{field_queryArray[0]}'] + "_pf}" + blacklight_config.search_field['#{field_queryArray[1]}'] + "\""
         q_string2 << ""
         q_string_hold << " _query_:\"{!dismax" # spellcheck.dictionary=" + blacklight_config.search_field['#{field_queryArray[0]}'] + " qf=$" + blacklight_config.search_field['#{field_queryArray[0]}'] + "_qf pf=$" + blacklight_config.search_field['#{field_queryArray[0]}'] + "_pf}" + blacklight_config.search_field['#{field_queryArray[1]}'] + "\""
         fieldNames = blacklight_config.search_fields["#{my_params[:search_field_row][i]}"]
         if !fieldNames["solr_parameters"].nil?
            solr_stuff = fieldNames["solr_parameters"]
            field_name = solr_stuff[:"spellcheck.dictionary"]
            q_string << " spellcheck.dictionary=" << field_name << " qf=$" << field_name << "_qf pf=$" << field_name << "_pf"
            q_string2 << field_name << " = "
            q_string_hold << " spellcheck.dictionary=" + field_name + " qf=$" + field_name + "_qf pf=$" + field_name + "_pf"
         end
         if holdarray.count > 1
          if field_name.nil?
            field_name = 'all_fields'
          end

          for j in 1..holdarray.count - 1
              holdarray_parse = holdarray[j].split('_query_')
              holdarray[1] = holdarray_parse[0]
              if(j < holdarray.count - 1)
                    q_string_hold << "}" << holdarray[1] << " _query_:\\\"{!dismax spellcheck.dictionary=" << field_name << " qf=$" << field_name << "_qf pf=$" << field_name << "_pf"
                    q_string << "}" << holdarray[1] << " _query_:\\\"{!dismax spellcheck.dictionary=" << field_name << " qf=$" << field_name << "_qf pf=$" << field_name << "_pf" #}" << holdarray[1].chomp("\"") << "\""
                    q_string2 << holdarray[1]
              else
                    q_string_hold << "}" << holdarray[1] << "\\\""
                    q_string << "}" << holdarray[1] << "\\\""
                    q_string2 << holdarray[1] << " "
              end
          end
         else
                 q_string_hold << "}" << holdarray[1] << "\\\""
                 q_string << "}" << holdarray[1] << "\\\""
                 q_string2 << holdarray[1]
         end
         if i < my_params[:q_row].count - 1
           q_string_hold << " "
           q_string << " " <<  opArray[i] << " "
           q_string2 << " "
        end 
        q_stringArray << q_string_hold
        q_string2Array << q_string2
        q_string_hold = "";
        q_string2 = "";
      end
     
      test_q_string = groupBools(q_stringArray, opArray)
      test_q_string2 = groupBools(q_string2Array, opArray)
      if test_q_string == ""
#        solr_parameters[:sort] = "score desc, title_sort asc"
      end
       solr_parameters[:q] = test_q_string
      params[:show_query] = test_q_string2
  end
  else
    solr_search_params_logic.each do |method_name|
      send(method_name, solr_parameters, my_params)
    end
    session[:search][:q] = my_params[:q]
    session[:search][:counter] = my_params[:counter]
    session[:search][:search_field] = my_params[:search_field]
    session[:search].delete(:q_row)
    params.delete(:q_row)
    params.delete(:boolean_row)
    session[:search].delete(:boolean_row)
    session[:search]["search_field"] = my_params["search_field"]
    solr_parameters[:q] = my_params[:q]
#    solr_parameters[:sort] = "score desc, title_sort asc"
    params[:search_field] = my_params["search_field"]
  end
  Rails.logger.info("Lafayette2")
  return solr_parameters
 end

  def groupBools(q_stringArray, opArray)
     grouped = []
     newString = ""
     if !q_stringArray.nil?
       newString = q_stringArray[0];
       for i in 0..opArray.count - 1
  #        q_stringArray[i +1].gsub('"',"")
  #        newString = "(" + newString + " " + opArray[i] + " "+ q_stringArray[i + 1] + ") "
          newString = newString + " " + opArray[i] + " "+ q_stringArray[i + 1]
  #        else
  #           if opArray[i] == "OR"
  #            newString = newString + " OR " + q_stringArray[i + 1]
  #           else
  #            newString = newString + " NOT " + q_stringArray[i + 1]
  #           end
  #       end
       end
     else
   #    params[:sort] = ""
     end
     #newString = newString.gsub('"',"")
#     newString =  "_query_:{!dismax}bauhaus  AND ( _query_:{!dismax spellcheck.dictionary=subject qf=$subject_qf pf=$subject_pf}architecture  NOT  _query_:{!dismax spellcheck.dictionary=subject qf=$subject_qf pf=$subject_pf}graphic design )"
     return newString
  end


  def massage_params(params)
    rowHash = {}
    opArray = []
    query_string = ""
    new_query_string = ""
    query_rowArray = params[:q_row]
    op_rowArray = params[:op_row]
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
              new_query = " " << current_query << " " << params[:boolean_row][n.to_sym] << " " << new_query_string << " "
              rowHash[search_field_rowArray[i]] = new_query
           else
              rowHash[search_field_rowArray[i]] = new_query_string
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
          query_string_two << newArray[i*2] << "=" << newArray[(i*2)+1] << "&op[]=" << opArray[i] << "&"
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
    if op == "phrase"
      query.gsub!("\"", "\'")
#      returnstring << '"' << query << '"'
      returnstring = query
    else
      splitArray = query.split(" ")
      if splitArray.count > 1
         returnstring = splitArray.join(' ' + op + ' ')
      else
         returnstring = query
      end
    end
    return returnstring
  end


  def parse_single(params)
    query_string = ""
    query_rowArray = params[:q_row]
    op_rowArray = params[:op_row]
    search_field_rowArray = params[:search_field_row]
      for i in 0..query_rowArray.count - 1
         if query_rowArray[i] != ""
           query_string << "q="
           query_rowSplitArray = query_rowArray[i].split(" ")
           if(query_rowSplitArray.count > 1 && op_rowArray[i] != "phrase")
             query_string << query_rowSplitArray[0] << " " << op_rowArray[i] << " "
             for j in 1..query_rowSplitArray.count - 2
               query_string << query_rowSplitArray[j] << " " << op_rowArray[i] << " "
             end
             query_string << query_rowSplitArray[query_rowSplitArray.count - 1] << "&search_field=" << search_field_rowArray[i]
           elsif(query_rowSplitArray.count > 1 && op_rowArray[i] == "phrase")
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
       unless param_array[i] == ""
        countit = countit + 1
       end
    end
    return countit
  end


end
