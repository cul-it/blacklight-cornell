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

#    make_adv_query(blacklight_params)
    query_string = ""
 #    user_params =  {"utf8"=>"✓", "omit_keys"=>["page"], "params"=>{"advanced_query"=>"yes"},
 #   "q_row"=>["wink", "pink"], "op_row"=>["AND", "AND"], "search_field_row"=>["all_fields", "all_fields"], 
 #"boolean_row"=>{"1"=>"OR"}, "sort"=>"score desc, pub_date_sort desc, title_sort asc", "search_field"=>"advanced", 
 #"commit"=>"Search", "controller"=>"catalog", "action"=>"index", "advanced_search"=>true, "advanced_query"=>"yes", "op"=>["OR"], "all_fields"=>"pink",
 # "defType"=>"lucene", 
 #"q"=>"_query_:\"{!edismax qf=$title_qf pf=$title_pf}wink\" OR _query_:\"{!edismax qf=$all_fields_qf pf=$all_fields_pf}pink &search_field=all_fields"}
#    user_parameters[:defType] = "lucene"
#    user_parameters[:q] = '_query_:"{!edismax qf=$title_qf pf=$title_pf}hot" AND _query_:"{!edismax qf=$title_qf pf=$title_pf}pink"'
#    user_parameters[:search_field] = "all_fields"
    qparam_display = ""
    my_params = {}
    # secondary parsing of advanced search params.  Code will be moved to external functions for clarity
    if blacklight_params[:q_row].present?
      my_params = make_adv_query(blacklight_params)
 
      user_parameters[:q] = my_params[:q]
#      user_parameters[:show_query] = 'title = water AND subject = ice' #my_params[:show_query]
#      params[:q] = my_params[:q]
#      params = my_params
#      user_parameters[:q] = '_query_:"{!edismax spellcheck.dictionary=all_fields qf=$all_fields_qf pf=$all_fields_pf}mark"  AND  _query_:"{!edismax spellcheck.dictionary=author qf=$author_qf pf=$author_pf}twain"'
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

 def removeBlanks(params)
     queryRowArray = params[:q_row]
     booleanRowArray = params[:boolean_row]
     subjectFieldArray = params[:search_field_row]
     opRowArray = params[:op_row]
     qrowSize = params[:q_row].count
     for i in 1..qrowSize - 1
       n = i.to_s
       if queryRowArray[i] == ""
         params[:q_row].delete_at(i)
         params[:op_row].delete_at(i)
         params[:search_field_row].delete_at(i)
         j = i+1
         nextKey = j.to_s
         onemore = ""
         if params[:boolean_row].has_key?(nextKey.to_sym)
           for k in i..qrowSize - 2
             l = k.to_s
             m = k + 1
             onemore = m.to_s
             params[:boolean_row][l.to_sym] = params[:boolean_row][onemore.to_sym]
           end
           params[:boolean_row].delete(onemore.to_sym)
         else
           params[:boolean_row].delete(n.to_sym)
         end
       end
     end
     finalcheck = params[:q_row].count.to_s
     if params[:boolean_row].has_key?(finalcheck.to_sym)
       params[:boolean_row].delete(finalcheck.to_sym)
     end
 end

    def make_adv_query(my_params = params || {})
#      Blacklight::Solr::Request.new.tap do |solr_parameters|

    if !my_params[:q_row].nil?
#    solr_search_params_logic.each do |method_name|
#      send(method_name, solr_parameters, my_params)
#    end
    q_string = ""
    q_string2 = ""
    q_string_hold = ""
    q_stringArray = []
    q_string2Array = []
    opArray = []
    if !my_params[:boolean_row].nil? && !my_params[:search_field_row].nil?
      for k in 0..my_params[:boolean_row].count - 1
         realsub = k + 1;
         n = realsub.to_s
         opArray[k] = my_params[:boolean_row][n.to_sym]
      end
      for i in 0..my_params[:search_field_row].count - 1
         my_params[:q_row][i].gsub!('”', '"')

         numquotes = my_params[:q_row][i].count '"'
         if numquotes == 1
           my_params[:q_row][i].gsub!('"', '')
         end
         if my_params[:op_row][i] == "phrase" or my_params[:search_field_row][i] == 'call number'
           if my_params[:q_row][i] == ""
             my_params[:q_row][i] = "blank"
           end
           newpass = '"' + my_params[:q_row][i] + '"'
         else
           if my_params[:q_row][i] == ""
             my_params[:q_row][i] = "blank"
           end
          newpass = my_params[:q_row][i]
         end
         if my_params[:search_field_row][i] == 'journal title'
           params['format'] = "Journal"
         end
    #     if my_params[:op_row][i] == "begins_with"
    #       my_params[:search_field_row][i] = my_params[:search_field_row][i] + "_starts"
    #     end
         pass_param = { my_params[:search_field_row][i] => my_params[:q_row][i]}
         returned_query = ParsingNesting::Tree.parse(newpass)
         newstring = returned_query.to_query(pass_param)
         holdarray = newstring.split('}')
         if my_params[:op_row][i] == "OR"
          holdarray[1] = parse_query_row(holdarray[1], "OR")
         end
     #    if my_params[:op_row][i] == 'begins_with'
     #     holdarray[1] = parse_query_row(holdarray[1], "OR")
     #    end
         queryStart = " _query_:\"{!edismax"
         q_string << " _query_:\"{!edismax" # spellcheck.dictionary=" + blacklight_config.search_field['#{field_queryArray[0]}'] + " qf=$" + blacklight_config.search_field['#{field_queryArray[0]}'] + "_qf pf=$" + blacklight_config.search_field['#{field_queryArray[0]}'] + "_pf}" + blacklight_config.search_field['#{field_queryArray[1]}'] + "\""
         q_string2 << ""
         q_string_hold << " _query_:\"{!edismax" # spellcheck.dictionary=" + blacklight_config.search_field['#{field_queryArray[0]}'] + " qf=$" + blacklight_config.search_field['#{field_queryArray[0]}'] + "_qf pf=$" + blacklight_config.search_field['#{field_queryArray[0]}'] + "_pf}" + blacklight_config.search_field['#{field_queryArray[1]}'] + "\""

         fieldNames = blacklight_config.search_fields["#{my_params[:search_field_row][i]}"]

         if !fieldNames.nil?
            solr_stuff = fieldNames["key"]
            if solr_stuff == "call number"
              solr_stuff = "lc_callnum"
            end
            if solr_stuff == "place of publication"
              solr_stuff = "pubplace"
            end
            if solr_stuff == "publisher number/other identifier"
              solr_stuff = "number"
            end
            if solr_stuff == "ISBN/ISSN"
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
              q_string << " spellcheck.dictionary=" << field_name << " qf=$" << field_name << "_qf pf=$" << field_name << "_pf format=Journal"
              q_string2 << field_name << " = "
              q_string_hold << " spellcheck.dictionary=" + field_name + " qf=$" + field_name + "_qf pf=$" + field_name + "_pf format=Journal"

            else
              if my_params[:op_row][i] == 'begins_with'
                  q_string << " spellcheck.dictionary=" << field_name << "_starts qf=$" << field_name << "_starts_qf pf=$" << field_name << "_starts_pf"
                 q_string2 << field_name << "_starts"<< " = "
                 q_string_hold << " spellcheck.dictionary=" + field_name + "_starts qf=$" + field_name + "_starts_qf pf=$" + field_name + "_starts_pf"
              else
                 q_string << " spellcheck.dictionary=" << field_name << " qf=$" << field_name << "_qf pf=$" << field_name << "_pf"
                 q_string2 << field_name << " = "
                 q_string_hold << " spellcheck.dictionary=" + field_name + " qf=$" + field_name + "_qf pf=$" + field_name + "_pf"
              end
            end
         end
         if holdarray.count > 1
          if field_name.nil?
            field_name = 'all_fields'
          end

          for j in 1..holdarray.count - 1
              holdarray_parse = holdarray[j].split('_query_')
              holdarray[1] = holdarray_parse[0]

              if(j < holdarray.count - 1)
           #         if my_params[:op_row][i] == 'begins_with'
           #           Rails.logger.info("WEEKEND2 = #{q_string_hold}")
           #           q_string_hold << "}" << holdarray[1] << " _query_:\\\"{!edismax spellcheck.dictionary=" << field_name << " qf=$" << field_name << "_qf pf=$" << field_name << "_pf"
           #           q_string << "}" << holdarray[1] << " _query_:\\\"{!edismax spellcheck.dictionary=" << field_name << " qf=$" << field_name << "_qf pf=$" << field_name << "_pf" #}" << holdarray[1].chomp("\"") << "\""
           #           q_string2 << holdarray[1]
            #         else
                      q_string_hold << "}" << holdarray[1] << " _query_:\\\"{!edismax spellcheck.dictionary=" << field_name << " qf=$" << field_name << "_qf pf=$" << field_name << "_pf"
                      q_string << "}" << holdarray[1] << " _query_:\\\"{!edismax spellcheck.dictionary=" << field_name << " qf=$" << field_name << "_qf pf=$" << field_name << "_pf" #}" << holdarray[1].chomp("\"") << "\""
                      q_string2 << holdarray[1]
           #         end
              else
                    q_string_hold << "}" << holdarray[1] #<< "\""
                    q_string << "}" << holdarray[1] #<< "\""
                    q_string2 << holdarray[1] << " "

              end
          end
         else
                 q_string_hold << "}" << holdarray[1] #<< "\""
                 q_string << "}" << holdarray[1] #<< "\""
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
       my_params[:q] = test_q_string
       if my_params[:q_row].present?
 #     solr_parameters[:'spellcheck.q'] = params[:q_row].join(" ")
    end
      my_params[:show_query] = test_q_string2
  end
  else
#     solr_parameters[:q] = my_params[:q]
    if params[:search_field] == "call number" and !my_params[:q].nil? and !my_params[:q].include?('"')
      params[:q] = '"' + my_params[:q] + '"'
    end
 #   solr_search_params_logic.each do |method_name|
 #     send(method_name, solr_parameters, my_params)
 #   end
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

  end
  if my_params[:advanced_query] == 'yes'
#   solr_parameters[:defType] = "lucene"
  end
  #solr_parameters['spellcheck.q'] = "title_start=cat&op[]=AND&subject_start=animal"
#  Rails.logger.info("CHECKSSOLRSEARCHPARAMS1 = #{solr_parameters['spellcheck.q']}")
  return my_params
end

  def groupBools(q_stringArray, opArray)
     grouped = []
     newString = ""
     if !q_stringArray.nil?
       newString = q_stringArray[0];
       for i in 0..opArray.count - 1

          newString = newString + " " + opArray[i] + " "+ q_stringArray[i + 1]
       end
     else
     end
     if !newString.nil?
       newString = newString.gsub('author/creator','author')
     end
     #newString = newString.gsub('"',"")
#     newString =  "_query_:{!edismax}bauhaus  AND ( _query_:{!edismax spellcheck.dictionary=subject qf=$subject_qf pf=$subject_pf}architecture  NOT  _query_:{!edismax spellcheck.dictionary=subject qf=$subject_qf pf=$subject_pf}graphic design )"
#     newString =  "_query_:{!edismax qf=$lc_callnum_qf pf=$lc_callnum_pf}\"PQ7798.416.A43\"\" AND  _query_:{!edismax spellcheck.dictionary=title qf=$title_qf pf=$title_pf}\"00\""
#     newString =  "_query_:{!edismax qf=$lc_callnum_qf pf=$lc_callnum_pf}\"PR2983 .I61\"\""
#     newString =  "_query_:{!edismax qf=$author_qf pf=$author_pf}Shakespeare"
     #NEWSTRING = \"PQ7798.416.A43 H6\""   AND title = hora"
     if newString.include?('%26')
       newString.gsub!('%26','&')
     end
    # newString = "_query_:{!edismax spellcheck.dictionary=title_starts qf=$title_starts_qf pf=$title_starts_pf}rat\"\"  OR  _query_:{!edismax spellcheck.dictionary=subject_starts qf=$subject_starts_qf pf=$subject_starts_pf}war\"\""
     return newString
  end
  
  
end
