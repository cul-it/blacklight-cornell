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
     templocs.gsub!(/^  /, ' || ')
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
        Rails.logger.info("Cline122 = #{doc.inspect}")
        Rails.logger.info("MishaBarton = #{create_condensed_full(doc)}")
        breakerlength = doc[:holdings_record_display].length
   #     Rails.logger.info("BeetleJooz = #{tmploc["display"]}")
        i = 0
        doc[:holdings_record_display].each do |hrd|  
          Rails.logger.info("Beetlejuice = #{hrd}")        
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

end
