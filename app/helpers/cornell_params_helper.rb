module CornellParamsHelper



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

    def solr_search_params(my_params = params || {})
    Blacklight::Solr::Request.new.tap do |solr_parameters|

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
    if !my_params[:boolean_row].nil? && !my_params[:search_field_row].nil?
      for k in 0..my_params[:boolean_row].count - 1
         realsub = k + 1;
         n = realsub.to_s
         opArray[k] = my_params[:boolean_row][n.to_sym]
      end
      for i in 0..my_params[:search_field_row].count - 1
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
         pass_param = { my_params[:search_field_row][i] => my_params[:q_row][i]}
         returned_query = ParsingNesting::Tree.parse(newpass)
         newstring = returned_query.to_query(pass_param)
         holdarray = newstring.split('}')
         if my_params[:op_row][i] == "OR"
          holdarray[1] = parse_query_row(holdarray[1], "OR")
         end
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
              field_name = "title"
              q_string << " spellcheck.dictionary=" << field_name << " qf=$" << field_name << "_qf pf=$" << field_name << "_pf format=Journal"
              q_string2 << field_name << " = "
              q_string_hold << " spellcheck.dictionary=" + field_name + " qf=$" + field_name + "_qf pf=$" + field_name + "_pf format=Journal"

            else
              q_string << " spellcheck.dictionary=" << field_name << " qf=$" << field_name << "_qf pf=$" << field_name << "_pf"
              q_string2 << field_name << " = "
              q_string_hold << " spellcheck.dictionary=" + field_name + " qf=$" + field_name + "_qf pf=$" + field_name + "_pf"
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
                    q_string_hold << "}" << holdarray[1] << " _query_:\\\"{!edismax spellcheck.dictionary=" << field_name << " qf=$" << field_name << "_qf pf=$" << field_name << "_pf"
                    q_string << "}" << holdarray[1] << " _query_:\\\"{!edismax spellcheck.dictionary=" << field_name << " qf=$" << field_name << "_qf pf=$" << field_name << "_pf" #}" << holdarray[1].chomp("\"") << "\""
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
#     solr_parameters[:q] = my_params[:q]
    if params[:search_field] == "call number" and !my_params[:q].nil? and !my_params[:q].include?('"')
      params[:q] = '"' + my_params[:q] + '"'
    end
    solr_search_params_logic.each do |method_name|
      send(method_name, solr_parameters, my_params)
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

  end
  return solr_parameters
 end
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
    if query.include?('%26')
      query.gsub!('%26','&')
    end
    query.gsub!("&","%26")
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

 def getTempLocations(doc)
   require 'json'
   require 'pp'
   @tempLocsNameArray = []
   temp_loc_Full = []
   temp_loc_text = []
   temp_loc_Full = create_condensed_full(doc)
   if !temp_loc_Full[0]["copies"][0]["temp_locations"].nil? and temp_loc_Full[0]["copies"][0]["temp_locations"].length > 0
     temp_loc_text = temp_loc_Full[0]["copies"][0]["temp_locations"]
   end
   temp_loc_text.each do |templocs|
     templocs.gsub!(/$/, ' || ')
   end
   if temp_loc_text.blank?
     @tempLocsNameArray << [" || "]
   else
     @tempLocsNameArray <<  temp_loc_text
   end
   return @tempLocsNameArray
 end

 def getLocations(doc)
   require 'json'
   require 'pp'
        @recordLocsNameArray = []
        myhash = {}
#        Rails.logger.info("Cline122 = #{doc.inspect}")
#        Rails.logger.info("MishaBarton = #{create_condensed_full(doc)}")
        breakerlength = doc[:holdings_record_display].length
   #     Rails.logger.info("BeetleJooz = #{tmploc["display"]}")
        i = 0
        doc[:holdings_record_display].each do |hrd|
#          Rails.logger.info("Beetlejuice = #{hrd}")
         myhash = JSON.parse(hrd)
         if i == breakerlength - 1
           @recordLocsNameArray << myhash["locations"][0]["name"] + " || "
         else
           @recordLocsNameArray << myhash["locations"][0]["name"] + " | "
         end
         i = i + 1
      end
   return @recordLocsNameArray
 end
 def getCallNos(doc)
   require 'json'
         @recordCallNumArray = []
        myhash = {}
        breakerlength = doc[:holdings_record_display].length
        i = 0
        doc[:holdings_record_display].each do |hrd|
         myhash = JSON.parse(hrd)
         if myhash["callnos"].nil?
           testString = "No Call Number"
         else
           testString = myhash["callnos"][0]
           if testString == '' or testString.nil?
             testString = "No Call Number, possibly still on order. Please contact the Circulation Desk at (607) 255-4245 or email okucirc@cornell.edu"
           end
         end
         if i == breakerlength - 1
           @recordCallNumArray << testString + " || "
         else
           @recordCallNumArray << testString + " | "
         end
         i = i + 1
      end
   return @recordCallNumArray
 end



 def getItemStatus(doc)
   require 'json'
   require 'pp'
        @itemStatusArray = []

        @hideArray = []
 #       Rails.logger.info("ClineJohn3 = #{doc[:url_access_display]}")
 #       Rails.logger.info("ClineJohn2 = #{create_condensed_full(doc)}")
        @hideArray = create_condensed_full(doc)
        @hideArray.each do |hidee|
        myhash = {}
 #      Rails.logger.info("ClineJohn53 = #{hidee}")
          myhash = hidee
          if myhash["copies"][0]["items"].size > 0 and myhash["copies"][0]["items"]["Available"].nil? and myhash["location_name"] != "*Networked Resource"
            i = 0
            myhash["copies"][0]["items"].each do |item|
               @itemStatusArray << item[0] + " || "
            end
          else
              if myhash["location_name"] == '*Networked Resource'
                @link = doc[:url_access_display][0].split('|')
                @itemStatusArray << @link[0] + " || "
              else
                @itemStatusArray << myhash["copies"][0]["items"]["Available"]["status"] + " || "
              end
          end
        end
   return @itemStatusArray
 end

end
