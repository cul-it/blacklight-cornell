module ApplicationHelper

  def alternating_line(id="default")
    @alternating_line ||= Hash.new("odd")
    @alternating_line[id] = @alternating_line[id] == "even" ? "odd" : "even"
  end

  def massage_params_two(params)
    massage_params_two(params)
    logger.debug("fogsworth #{params}")
#    rowHash = {}
    query_string = ""
#    new_query_string = ""
    query_rowSplitArray = []
    usedSearchTermArray = []
    query_rowArray = params[:q_row]
    op_rowArray = params[:op_row]
    search_field_rowArray = params[:search_field_row]
    if query_rowArray.count > 1
      for i in 0..query_rowArray.count - 2
         unless usedSearchTermArray.include? search_field_rowArray[i]
            usedSearchTermArray.push(search_field_rowArray[i])
         end
         if query_rowArray[i] != ""
          logger.debug("usedTerms = #{usedSearchTermArray}")
#          new_query_string = parse_query_row(query_rowArray[i], op_rowArray[i])
#          if rowHash.hasKey(search_field_rowArray[i])?
          query_string << search_field_rowArray[i] << "=("
          query_rowSplitArray = query_rowArray[i].split(" ")
          if(query_rowSplitArray.count > 1 && op_rowArray[i] != "phrase")
           query_string << query_rowSplitArray[0] << " " << op_rowArray[i] << " "
           for j in 1..query_rowSplitArray.count - 2
             query_string << query_rowSplitArray[j] << " " << op_rowArray[i] << " "
           end
           query_string << query_rowSplitArray[query_rowSplitArray.count - 1] << ")"
           if params["as_boolean_row#{i+2}"].nil?
            query_string << "&op[]=AND"
           else
            query_string << "&op[]=" << params["as_boolean_row#{i+2}"] << "&"
           end
          elsif(query_rowSplitArray.count > 1 && op_rowArray[i] == "phrase")
           query_string << '"' << query_rowArray[i] << '")'
           if params["as_boolean_row#{i+2}"].nil?
            query_string << "&op[]=AND"
           else
            query_string << "&op[]=" << params["as_boolean_row#{i+2}"] << "&"
           end   
          else
           query_string  << query_rowArray[i] << ")"
           if params["as_boolean_row#{i+2}"].nil?
            query_string << "&op[]=AND"
           else
            query_string << "&op[]=" << params["as_boolean_row#{i+2}"] << "&"
           end
	        end
         end
      end
      for i in query_rowArray.count - 1..query_rowArray.count - 1

         if query_rowArray[i] != ""
           query_string << search_field_rowArray[i] << "=("
           query_rowSplitArray = query_rowArray[i].split(" ")
           if(query_rowSplitArray.count > 1 && op_rowArray[i] != "phrase")
             query_string << query_rowSplitArray[0] << " " << op_rowArray[i] << " "
             for j in 1..query_rowSplitArray.count - 2
               query_string << query_rowSplitArray[j] << " " << op_rowArray[i] << " "
             end
             query_string << query_rowSplitArray[query_rowSplitArray.count - 1] << ")"
           elsif(query_rowSplitArray.count > 1 && op_rowArray[i] == "phrase")
             query_string << '"' << query_rowArray[i] << '")'
           else
             query_string << query_rowArray[i] << ")"
      	   end
         end
      end
    end
    logger.debug("Madisoncheese = #{query_string}")
    return query_string
  end

  def massage_params(params)
    logger.debug("fogsworth_two #{params}")
    rowHash = {}
    opArray = []
    query_string = ""
    new_query_string = ""
    query_rowArray = params[:q_row]
    op_rowArray = params[:op_row]
    search_field_rowArray = params[:search_field_row]
    Rails.logger.debug("ashketchum= #{query_rowArray}")
    if query_rowArray.count > 1
#first row
       if query_rowArray[0] != ""
         new_query_string = parse_query_row(query_rowArray[0], op_rowArray[0])
         rowHash[search_field_rowArray[0]] = new_query_string
         new_query_string = ""
       end

       for i in 1..query_rowArray.count - 1
         if query_rowArray[i] != ""
           new_query_string = parse_query_row(query_rowArray[i], op_rowArray[i])
           if rowHash.has_key?(search_field_rowArray[i])
              current_query = rowHash[search_field_rowArray[i]]
              new_query = "(" << current_query << ") " << params["as_boolean_row#{i+1}"] << " (" << new_query_string << ")"
              logger.debug("fogsworthLoop = #{params['as_boolean_row#{i+1}']}")
              rowHash[search_field_rowArray[i]] = new_query
           else
              rowHash[search_field_rowArray[i]] = new_query_string
              opArray << params["as_boolean_row#{i+1}"]
           end
         end
       end
       opcount = 0;
       query_string_two = ""
       newArray = rowHash.flatten
       Rails.logger.debug("Flathead = #{newArray}")
       Rails.logger.debug("FlatheadSize = #{newArray.count}")
       keywordscount = newArray.count / 2
       for i in 0..keywordscount -1
         if i < keywordscount - 1
          if opArray[i].nil?
            opArray[i] = 'AND'
          end
          query_string_two << newArray[i*2] << "=(" << newArray[(i*2)+1] << ")&op[]=" << opArray[i] << "&"
         else
          query_string_two << newArray[i*2] << "=(" << newArray[(i*2)+1] << ")"
         end
       end
       #account for some bozo not selecting different search_fields
       bozocheck = query_string_two.split("=")
       if bozocheck.count < 3
         query_string_two = "q=" + bozocheck[1] + "&search_field=" + bozocheck[0]
           logger.debug("Madisoncheese_two = #{query_string_two}")
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
      returnstring << '"' << query << '"'
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
           query_string << "q=("
           query_rowSplitArray = query_rowArray[i].split(" ")
           if(query_rowSplitArray.count > 1 && op_rowArray[i] != "phrase")
             query_string << query_rowSplitArray[0] << " " << op_rowArray[i] << " "
             for j in 1..query_rowSplitArray.count - 2
               query_string << query_rowSplitArray[j] << " " << op_rowArray[i] << " "
             end
             query_string << query_rowSplitArray[query_rowSplitArray.count - 1] << ")&search_field=" << search_field_rowArray[i]
           elsif(query_rowSplitArray.count > 1 && op_rowArray[i] == "phrase")
             query_string << '"' << query_rowArray[i] << '")&search_field=' << search_field_rowArray[i]
           else
             query_string << query_rowArray[i] << ")&search_field=" << search_field_rowArray[i]
           end
         end
      end
    logger.debug("Madisoncheesier = #{query_string}")      
     return query_string
  end
  
  def test_size_param_array(param_array)
    count = 0
    for i in 0..param_array.count - 1
       unless param_array[i] == ""
        count = count + 1
       end
    end
    return count
  end
end
