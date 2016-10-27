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
             params["sort"] = "score desc, pub_date_sort desc, title_sort asc";
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

  def parse_for_stemming(params)
    query_string = params[:q]
    search_field = params[:search_field]
#    unless query_string.nil?
     if query_string =~ /^\".*\"$/ or query_string.include?('"')
       Rails.logger.info("STEMfullstringquoted = #{query_string}")
       params[:search_field] = params[:search_field] + '_quote'
       return query_string
     else 
       unless query_string.nil?
         params[:q_row] = parse_stem(query_string)
         Rails.logger.info("PARSER Returned = #{params[:q_row]}")
       end
       return query_string       
     end
#    end
  end
 
  def parse_stem(query_string)
    string_chars = query_string.chars
    Rails.logger.info("PARSER = #{string_chars}")
    quoteFlag = 0
    wordArray = []
#   if !query_string == /^\".*\"$/ # query_string.include?('"')
   if !(query_string.start_with?('"') and query_string.end_with?('"')) #.*\"$/ # query_string.include?('"')
    Rails.logger.info("POOP #{query_string}")
    search_field = params[:search_field]
    params[:q_row] = []
    params[:search_field_row] = []
    params[:op_row] = []
    params[:op] = []
    params[:boolean_row] = {}
    params[:q] = ""
    string_chars.each do |i|
      if i == '"'
        if quoteFlag == 1  #left hand quote already encountered this must be right hand quote
          wordArray << i
          params[:q] << i
          params[:q_row] << wordArray.join.strip  #right hand quote means end of section add to params[:q_row]
          params[:op_row] << "phrase"
          params[:search_field_row] << search_field + "_quote"
          quoteFlag = 0 #reset quote flag
          wordArray = [] #clear out wordArray
        else # must be left hand quote
          if !wordArray.empty?
            params[:q_row] << wordArray.join.strip
            params[:op_row] << "AND"
            params[:search_field_row] << search_field
            wordArray = []
          end
          quoteFlag = 1
          wordArray << i
          params[:q] << i
        end
      else
        wordArray << i
        params[:q] << i
      end
    end
    if !wordArray.empty?
      if quoteFlag == 1
        wordArray << '"'
        params[:q]<< '"'
        Rails.logger.info("GLADYS = #{wordArray}")
        params[:q_row] << wordArray.join.strip
        params[:op_row] << "phrase"
        params[:search_field_row] << search_field + "_quote"
        wordArray = []
        quoteFlag = 0
      else 
        if quoteFlag == 0
        Rails.logger.info("GLADYS1 = #{wordArray}")
          params[:q_row] << wordArray.join.strip
           params[:op_row] << "AND"
          params[:search_field_row] << search_field 
         wordArray = []
        end
      end
    end 
    times = params[:q_row].count
    for j in 1..times -1
      x = j
      n = x.to_s
      params[:boolean_row]["#{j}"] = "AND"
      params[:op][j - 1] = "AND"
    end
    Rails.logger.info("PUTREFLIP = #{params}")
    return params
   else
     return query_string
   end
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
      Rails.logger.info("CHECKPARSESINGLE = #{query_string}")
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
     queryRowArray = [] #params[:q_row]
     booleanRowArray = [] #params[:boolean_row]
     subjectFieldArray = [] #params[:search_field_row]
     opRowArray = [] #params[:op_row]
     qrowSize = params[:q_row].count
     booleanRowCount = 1
     qrowIndexes = []
     boolHoldHash = {}
     Rails.logger.info("PHIN = #{params[:boolean_row]}")
     Rails.logger.info("QROWSIZE = #{qrowSize}")
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
#     params[:boolean_row] = {"1"=>"OR", "2"=>"OR"}
#     finalcheck = params[:q_row].count.to_s
#     if !params[:boolean_row].nil? and params[:boolean_row].has_key?(finalcheck.to_sym)
#       params[:boolean_row].delete(finalcheck.to_sym)
#     end
     Rails.logger.info("REMOVINGPH = #{params}")
     return params
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
        breakerlength = doc[:holdings_record_display].length
        i = 0
        doc[:holdings_record_display].each do |hrd|
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
        @hideArray = create_condensed_full(doc)
        @hideArray.each do |hidee|
        myhash = {}
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

  def render_constraints_xxcts(my_params = params)
    Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__} my_params =  #{my_params.inspect}")
    my_params[:q]  = my_params[:y]
    content = ""
    content << render_advanced_constraints_filters(my_params)
    return content.html_safe
  end

  def render_constraints_cts(my_params = params)
    Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__} my_params =  #{my_params.inspect}")
    field = params[:search_field]
    label = search_field_def_for_key(field)[:label]
    query = params[:y]
    content = ""
    content << render_constraint_element(label, query,
          :remove => "?#{field}") 
    Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__} content =  #{content.inspect}")
    content.html_safe
  end

  def render_constraints_query(my_params = params)
  Rails.logger.info("es287_debug ---> #{__FILE__}:#{__LINE__} my_params =  #{my_params.inspect}")
  if (@advanced_query.nil? || @advanced_query.keyword_queries.empty? )
    Rails.logger.info("es287_debug---> #{__FILE__}:#{__LINE__} super =  #{super.inspect}")
    return  super(my_params)
  else
    Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__} my_params =  #{my_params.inspect}")
    content = ""
    @advanced_query.keyword_queries.each_pair do |field, query|
      label = search_field_def_for_key(field)[:label]
      if query.include?('%26')
        query.gsub!('%26','&')
      end
      content << render_constraint_element(
        label, query,
        :remove =>
          search_facet_catalog_path(remove_advanced_keyword_query(field,my_params))
      )
    end
    if (@advanced_query.keyword_op == "OR" &&
        @advanced_query.keyword_queries.length > 1)
      content = '<span class="inclusive_or appliedFilter">' + '<span class="operator">Any of:</span>' + content + '</span>'
    end
    return content.html_safe
  end
 
end

def deep_copy(o)
  Marshal.load(Marshal.dump(o))
end


def render_advanced_constraints_query(my_params = params)
#    if (@advanced_query.nil? || @advanced_query.keyword_queries.empty? )
  Rails.logger.info("ROCKOZ =  #{my_params}")
  my_params = removeBlanks(my_params)
  Rails.logger.info("ROCKOZ1 = #{my_params}")
  if my_params[:search_field] == 'advanced'
    my_params.delete(:q)
  end
# my_params[:q] = ''
#  my_params[:show_query] = ''
  if ( my_params["q_row"].nil? and ( my_params["q"].nil? || my_params["q"].blank?))
    Rails.logger.info("ROCKO2 =  #{my_params.inspect}")
    content = ""
    content << render_advanced_constraints_filters(my_params)
    return content.html_safe
  else
    if my_params[:q_row].nil?
      content = ""
      content << render_constraints(my_params)
      return content.html_safe
    end
    if my_params[:q_row].count == 1
      Rails.logger.info("ROCKOVA = #{my_params}")
      my_params[:search_field] = my_params[:search_field_row][0]
      my_params[:q] = my_params[:q_row][0]
      hold_q_row = my_params[:q_row][0]
      hold_search_field_row = my_params[:search_field_row][0]
      hold_oprow = my_params[:op_row][0]
      my_params.delete("advanced_query")
      my_params.delete("q_row")
      my_params.delete("op_row")
      my_params.delete(:search_field_row)
      my_params.delete(:show_query)
      my_params.delete(:y)
      my_params.delete(:sort)
      my_params.delete(:search_field)
      my_params.delete(:boolean_row)
      my_params[:search_field] = hold_search_field_row
      content = ""
      Rails.logger.info("ROCKOVA22 = #{my_params}")
      content << render_constraints(my_params)
      my_params[:q_row] = []
      my_params[:search_field_row] = []
      my_params[:op_row] = []
      my_params[:q_row][0] = hold_q_row
      my_params[:search_field_row][0] = hold_search_field_row
      my_params[:op_row][0] = hold_oprow
      my_params[:boolean_row] = {"1" => "AND"}
      return content.html_safe
    end
    Rails.logger.info("MY_PARAMS =  #{my_params.inspect}")
    if my_params[:boolean_row] == {}
     my_params[:boolean_row] = {"1" => "AND"}
    end
    labels = []
    values = []
    q_parts = []
    new_q_parts = []
    equalsign = []
    ampersand = []
    q_string = my_params["q"]
    content = ""
    test = ""
#      if (@advanced_query.keyword_queries.count == 2)
    facetparams = ""
    if (my_params[:f].present?)
      if(my_params[:f].count > 1)
      end
      start1 = "f["
      next1 = ""
      count = 0
      my_params[:f].each do |key, value|
         next1 = ""
         next2 = ""
         start2 = start1 + key + "][]="
         value.each do |v|
           next1 =  next1 + start2 + v + "&"
     #      next2 =  next2 + start2 + v.gsub!('&','%26')
         end
         facetparams = facetparams + next1
      end
    else
      facetparams = ""
    end
    if !facetparams.nil?
    test = facetparams.sub!('Kroch Library Rare & Manuscripts', 'Kroch Library Rare %26 Manuscripts')
    if !test.nil?
      facetparams = test
    end
    end
    j = 1
    if (!my_params[:search_field_row].nil? and my_params[:search_field] == 'advanced')
          Rails.logger.info("SEARCHFIELDLABEL = #{my_params}")

     sfr = my_params[:search_field_row][0]
#     if my_params[:op_row][0] == "begins_with"
#       sfr = sfr << "_starts"
#     end
     new_q_parts[0] = sfr  + "=" + my_params[:q_row][0]
      for i in 1..my_params[:q_row].count - 1
        sfr = my_params[:search_field_row][i] #<< "=" << my_params[:q_row][i]
#        if my_params[:search_field_row][i] == "begins_with"
#          sfr = sfr << "_starts"
#        end
        n = i.to_s
        if !my_params[:boolean_row].nil?
          if !my_params[:boolean_row][n.to_sym].nil?
            new_q_parts[j] = "op[]=" << my_params[:boolean_row][n.to_sym]
            new_q_parts[j+1] =  sfr + "=" + my_params[:q_row][i]
          end
        end
        j = j + 2
      end
#        q_parts = q_string.split('&')
    elsif !my_params[:q].nil? and !my_params[:q].blank? and !my_params[:search_field].nil?
     new_q_parts[0] = "q=" << my_params[:q]
     new_q_parts[1] = "search_field=" << my_params[:search_field]
          Rails.logger.info("SEARCHFIELDLABEL = #{my_params}")
    end
    if (new_q_parts.count == 3 )
     #  params.delete("advanced_query")
     Rails.logger.info("QPARTS = #{new_q_parts}")
       0.step(2, 2) do |x|
         label = ""
         parts = new_q_parts[x].split('=')
         if x == 0
           hold = new_q_parts[2].split('=')
         else
           hold = new_q_parts[0].split('=')
         end
           if parts[1].nil?
             parts[1] = ""
           end
           querybuttontext = parts[1]
           if querybuttontext.include?('%26')
             querybuttontext = querybuttontext.gsub!('%26','&')
           end
         if x%2 == 0
           if x - 1 > 0
             opval = new_q_parts[x - 1].split('=')
             label = opval[1] << " "
             label << search_field_def_for_key(parts[0])[:label]
           else
             label = search_field_def_for_key(parts[0])[:label]
           end
           if hold[1].nil?
             hold[1] = ""
           end
           if hold[1].include?('&')
             hold[1] = hold[1].gsub!('&','%26')
          end
           removeString = "catalog?&q=" + hold[1] + "&search_field=" + hold[0] + "&" + facetparams + "action=index&commit=Search"
           content << render_constraint_element(label, querybuttontext, :remove => removeString)
         else
          content << " " << querybuttontext << " "
         end
         #content #<< "".html_safe
       end
      unless !my_params[:q].nil?
         content << render_simple_constraints_filters(params)
      else
         content << render_advanced_constraints_filters(params)
      end
      return content.html_safe
    else
     if (new_q_parts.count <= 2)
#            parts = q_parts[0].split('=')
         if !my_params[:q].nil? and !my_params[:q].blank? and !my_params[:search_field].nil?
          remove_string = my_params["q"]
          Rails.logger.info("SEARCHFIELDLABEL = #{my_params}")
          label = search_field_def_for_key(my_params[:search_field])[:label]
          if(params[:f].nil?)
            removeString = "?"
          else
            removeString = "?" + facetparams
          end
          querybuttontext = my_params["q"]
          if querybuttontext.include?('%26')
            querybuttontext = querybuttontext.gsub!('%26','&')
          end
          if !test.nil?
            facetparams = test
          end
             if querybuttontext.include?('%26')
               querybuttontext = querybuttontext.gsub!('%26','&')
             end
          content << render_constraint_element(
             label, querybuttontext,
             :remove => removeString
          )
          end
          if !my_params[:q].nil?
            content << render_simple_constraints_filters(my_params)
          else
            content << render_constraints_filters(my_params)
          end
          return content.html_safe
     else
        temp_boolean_rows = deep_copy(my_params)
        0.step(my_params[:q_row].count - 1, 1) do |x|
          label = ""
          opval = ""
          remove_indexes = []
          icount = 0
          temp_search_field_row = []
          temp_q_row = []
          temp_op_row = []
          temp_boolean_row = []
          deleted = 0
          0.step(my_params[:q_row].count - 1, 1) do |y|
             if y != x
                 temp_q_row << my_params[:q_row][y]
                 temp_op_row << my_params[:op_row][y]
                 temp_search_field_row << my_params[:search_field_row][y]
              end

              end
              if x == 0
                2.step(temp_boolean_rows[:boolean_row].count, 1) do |br|
                  ss = br.to_s
                  temp_boolean_row << temp_boolean_rows[:boolean_row][ss.to_sym]
                end
              else
                1.step(temp_boolean_rows[:boolean_row].count, 1) do |br|
                  if x != br
                   ss = br.to_s
                   temp_boolean_row << temp_boolean_rows[:boolean_row][ss.to_sym]
                  end
                end
              end
          Rails.logger.info("SEARCHFIELDLABEL = #{my_params}")
                
               if x >= 1 and x <= temp_boolean_rows.count
                   opval = temp_boolean_row[x]
                   label << search_field_def_for_key(my_params[:search_field_row][x])[:label]
               else
                 Rails.logger.info("WINKY")
                   label = search_field_def_for_key(my_params[:search_field_row][x])[:label]
               end

               autoparam = ""
               
                   
               autoparam = ""
               for qp in 0..temp_q_row.length - 1
                  
                  autoparam << "q_row[]=" << temp_q_row[qp] << "&op_row[]=" << temp_op_row[qp] << "&search_field_row[]=" << temp_search_field_row[qp]
                  if qp < temp_q_row.length - 1
                    autoparam << "&boolean_row[#{qp + 1}]=" << temp_boolean_row[qp] << "&"
                  end

                 
                 
               end
               querybuttontext = my_params[:q_row][x] #parts[1]
               if querybuttontext.include?('%26')
                 querybuttontext = querybuttontext.gsub!('%26','&')
               end
               removeString = "catalog?utf8=%E2%9C%93&" + autoparam + "&" + facetparams + "search_field=advanced&action=index&commit=Search&advanced_query=yes"
               if x > 0
                 s = x.to_s
                 label = temp_boolean_rows[:boolean_row][s.to_sym] + " " + label
               end
               content << render_constraint_element(
                 label, querybuttontext,
#                 :remove => "catalog?utf8=%E2%9C%93&" + autoparam + "&" + facetparams + "&action=index&commit=Search&advanced_query=yes"
                 :remove => removeString #"catalog?utf8=%E2%9C%93&" + autoparam + "&" + facetparams + "&action=index&commit=Search&advanced_query=yes"
                 )

       end
       
       if !my_params[:q].nil?
         content << render_simple_constraints_filters(my_params)
       else
         content << render_advanced_constraints_filters(my_params)
       end
       return content.html_safe
     end

  end
 end
end

def render_simple_constraints_filters(my_params = params)
  return_content = ""
  if(my_params[:f].present?)
    my_params[:f].each do |key, value|
      removeString = makeRemoveString(my_params,key)
      label =facet_field_labels[key]
      if value[0].include?('%26')
        value[0].gsub!('%26','&')
      end
      return_content << render_constraint_element(label,
        value.join(" AND "),
        :remove => "?" + removeString
        )
    end
  end
  return return_content.html_safe
end


def render_advanced_constraints_filters(my_params = params)
  return_content = "" #super(my_params)
#   if (@advanced_query)
   if(my_params[:f].present?)
   # @advanced_query.filters.each_pair do |field, value_list|
     my_params[:f].each do |key, value|
#        label = facet_field_labels[field]
      removeString = makeRemoveString(my_params, key)
      label = facet_field_labels[key]
      if value[0].include?('%26')
        value[0].gsub!('%26','&')
      end
      return_content << render_constraint_element(label,
        value.join(" AND "),
#          :remove => search_facet_catalog_path( remove_advanced_filter_group(field, my_params) )
        :remove => "?" + removeString
#          :remove => "catalog?"
        )
    end
  end

  return return_content.html_safe
end


def makeSimpleRemoveString(my_params, facet_key)
  removeString = ""
  fkey = facet_key
  show_query_string = ""
  facets = my_params[:f]
  facets_string = ""
  if !facets.nil?
    facets.each do |key, value|
      if key != fkey
        for i in 0..value.count - 1 do
          if value[i].include? 'Kroch Library Rare'
            value[i] = 'Kroch Library Rare %26 Manuscripts'
          end
          facets_string << "f[" << key << "][]=" << value[i] << "&"
        end
      end
    end
  end
  if !facets_string.blank?
    facets_string << "&"
  end
  q = my_params[:q]
  q_string = ""
  if !q.nil?
    if q.include?('=')
     q = q.gsub!('=','%3D')
    end
    if q.include?('&')
     q = q.gsub!('&', '%26')
    end
    if q.include?('#')
      q = q.gsub!('#','%23')
    end
    q_string = "q=" << q << "&"
  else
    q = ""
  end
  search_field = my_params["search_field"]
  search_field_string = ""
  if !search_field.nil?
    search_field_string = "search_field=" << search_field << "&"
  end
  search_field_row = my_params["search_field_row"]
  search_field_row_string = ""
  if !search_field_row.nil?
    for i in 0..search_field_row.count - 1
      search_field_row_string << "search_field_row[]=" << search_field_row[i] << "&"
    end
  end
  unless q.nil?
    removeString = "q=" + q + "&" +search_field_string + facets_string + "action=index&commit=Search"
  else
    removeString = "BULLHOCKEY"
  end
  return removeString

end

def makeRemoveString(my_params, facet_key)
  removeString = ""
  fkey = facet_key
  advanced_query = my_params["advanced_query"]
  advanced_search = my_params["advanced_search"]
  show_query_string = ""
  if !advanced_search.nil?
    advanced_search = "true"
  else
    advanced_search = "false"
  end
  boolean_row = my_params["boolean_row"]
  boolean_row_string = ""
  if !boolean_row.nil?
   boolean_row.each do |key, value|
     boolean_row_string << "boolean_row[" + key + "]=" + value + "&"
   end
  end
  if !boolean_row_string.blank?
    boolean_row_string << "&"
  end
  facets = my_params[:f]
  facets_string = ""
  if !facets.nil?
    facets.each do |key, value|
      if key != fkey
        for i in 0..value.count - 1 do
          if value[i].include? 'Kroch Library Rare'
            value[i] = 'Kroch Library Rare %26 Manuscripts'
          end
          facets_string << "f[" << key << "][]=" << value[i] << "&"
        end
      end
    end
  end
  if !facets_string.blank?
    facets_string << "&"
  end
  op = my_params["op"]
  op_string = ""
  if !op.nil?
    for i in 0..op.count - 1 do
      op_string << "op[]=" << op[i] << "&"
    end
  end
  op_row = my_params["op_row"]
  op_row_string = ""
  if !op_row.nil?
    for i in 0..op_row.count - 1 do
      op_row_string << "op_row[]=" << op_row[i] << "&"
    end
  end
  q = my_params[:q]
  q_string = ""
  if !q.nil?
    if q.include?('=')
     q = q.gsub!('=','%3D')
    end
    if q.include?('&')
     q = q.gsub!('&', '%26')
    end
    q_string = "q=" << q << "&"
  else
    q = ""
  end
  q_row = my_params["q_row"]
  q_row_string = ""
  if !q_row.nil?
    for i in 0..q_row.count - 1
      q_row_string << "q_row[]=" << q_row[i] << "&"
    end
  end
  search_field = my_params["search_field"]
  search_field_string = ""
  if !search_field.nil?
    search_field_string = "search_field=" << search_field << "&"
  end
  search_field_row = my_params["search_field_row"]
  search_field_row_string = ""
  if !search_field_row.nil?
    for i in 0..search_field_row.count - 1
      search_field_row_string << "search_field_row[]=" << search_field_row[i] << "&"
    end
  end
  if ((q_row.nil? || q_row.count < 2) && !q.nil?)
    removeString = "q=" + q + "&" +search_field_string + "action=index&commit=Search"
  else
    if advanced_query.nil?
      advanced_query = "yes"
    end
    removeString << "advanced_query=" + advanced_query + "&advanced_search=" + advanced_search + "&" + boolean_row_string +
                  facets_string + op_string + op_row_string + q_string.html_safe +
                  q_row_string + search_field_string + search_field_row_string
  end
  return removeString
end

def make_show_query(params)

#  params[:show_query] = 'title = water AND subject = ice'
  for i in 0..params[:search_field_row].count - 1
    showquery = params[:search_field_row][i] + " = " + params[:q_row][i] 
    if !params[:boolean_row].nil? and !params[:boolean_row][i+1].nil?
      showquery = showquery + " " + params[:boolean_row][i+1] + " "
    end
  end
  params[:show_query] = showquery
end

 ##
  # Check if the query has any constraints defined (a query, facet, etc)
  #
  # @param [Hash] query parameters
  # @return [Boolean]
  def query_has_constraints?(localized_params = params)
    Rails.logger.info("es287_debug #{__FILE__} #{__LINE__} #{__method__} params = #{localized_params.inspect}")
    #y = !(localized_params[:q].blank? and localized_params[:f].blank?)
    y = !(localized_params[:q].blank? and localized_params[:f].blank? and localized_params[:click_to_search].blank?) || (!localized_params[:search_field].blank? and (localized_params[:search_field] != 'all_fields'))
    Rails.logger.info("es287_debug #{__FILE__} #{__LINE__} #{__method__} y  = #{y.inspect}")
    y
  end

end
