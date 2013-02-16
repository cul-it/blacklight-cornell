module ApplicationHelper

  def alternating_line(id="default")
    @alternating_line ||= Hash.new("odd")
    @alternating_line[id] = @alternating_line[id] == "even" ? "odd" : "even"
  end

  def massage_params(params)
    logger.debug("fogsworth #{params}")
    query_string = ""
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
          query_string << search_field_rowArray[i] << "=("
          query_rowSplitArray = query_rowArray[i].split(" ")
          if(query_rowSplitArray.count > 1 && op_rowArray[i] != "phrase")
           query_string << query_rowSplitArray[0] << " " << op_rowArray[i] << " "
           for j in 1..query_rowSplitArray.count - 2
             query_string << query_rowSplitArray[j] << " " << op_rowArray[i] << " "
           end
           query_string << query_rowSplitArray[query_rowSplitArray.count - 1] << ")"
           if params["as_boolean_row#{i+2}"].nil?
            query_string << "&"
           else
            query_string << "&op=" << params["as_boolean_row#{i+2}"] << "&"
           end
          elsif(query_rowSplitArray.count > 1 && op_rowArray[i] == "phrase")
           query_string << "'" << query_rowArray[i] << "')"
           if params["as_boolean_row#{i+2}"].nil?
            query_string << "&"
           else
            query_string << "&op=" << params["as_boolean_row#{i+2}"] << "&"
           end
            
          else
           query_string  << query_rowArray[i] << ")"
           if params["as_boolean_row#{i+2}"].nil?
            query_string << "&"
           else
            query_string << "&op=" << params["as_boolean_row#{i+2}"] << "&"
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
           query_string << query_rowSplitArray[query_rowSplitArray.count - 1]
         elsif(query_rowSplitArray.count > 1 && op_rowArray[i] == "phrase")
           query_string << "'" << query_rowArray[i] << "')"
         else
           query_string << query_rowArray[i] << ")"
	       end
       end
      end
    end
    logger.debug("Madisoncheese = #{query_string}")
    return query_string
  end
end
