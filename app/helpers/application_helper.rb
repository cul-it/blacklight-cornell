module ApplicationHelper

  def alternating_line(id="default")
    @alternating_line ||= Hash.new("odd")
    @alternating_line[id] = @alternating_line[id] == "even" ? "odd" : "even"
  end

    # get search results from the solr index
    def index

      extra_head_content << view_context.auto_discovery_link_tag(:rss, url_for(params.merge(:format => 'rss')), :title => t('blacklight.search.rss_feed') )
      extra_head_content << view_context.auto_discovery_link_tag(:atom, url_for(params.merge(:format => 'atom')), :title => t('blacklight.search.atom_feed') )
      
      @bookmarks = current_or_guest_user.bookmarks


# secondary parsing of advanced search params.  Code will be moved to external functions for clarity      
      if params[:q_row].present?
        query_string = set_advanced_search_params(params)
      end                  
 #     end
# End of secondary parsing

#  Journal title search hack.

      if params[:search_field] == "journal title"
        if params[:f].nil?
          params[:f] = {}
        end
          params[:f] = {"format" => ["Journal"]}
#          unless(!params[:q])
          params[:q] = params[:q]
          params[:search_field] = "journal title"
      end
# end of Journal title search hack

      (@response, @document_list) = get_search_results
 
      
      if params.nil? || params[:f].nil?
        @filters = []
      else
        @filters = params[:f] || []
      end
 
# clean up search_field and q params.  May be able to remove this
 
      if params[:search_field] == "journal title" 
         if params[:q].nil?     
           params[:search_field] = ""
         end
      end

      if params[:q_row].present?              
         if params[:q].nil?
          params[:q] = query_string
         end
      else
          if params[:q].nil?
            params[:q] = query_string
          end   
      end

# end of cleanup of search_field and q params      
      
      respond_to do |format|
        format.html { save_current_search_params }
        format.rss  { render :layout => false }
        format.atom { render :layout => false }
      end
#    params.delete("q_row")
      
    end


  def solr_search_params(user_params = params || {})
    solr_parameters = {}

    solr_search_params_logic.each do |method_name|
      send(method_name, solr_parameters, user_params)
    end
    if user_params[:search_field] == 'advanced'
#       blacklight_config.search_fields.each do |key, value|
#       end
       if !user_params[:search_field_row].nil?
         q_string = ""
         rowArray = []
         shrink_rows = []
         opArray = []
         for i in 0..user_params[:search_field_row].count - 1
           if shrink_rows.include?(user_params[:search_field_row][i])
           else
                shrink_rows << user_params[:search_field_row][i]
                rowArray << i 
                if i > 0
                 n = i.to_s
                 opArray << user_params[:boolean_row][n.to_sym]
                end
            end
          end
 
         for i in 0..shrink_rows.count - 1
               returned_query = {}
               field_query = shrink_rows[i]
               if user_params[:q_row][1] == ""
                 user_params[field_query] = user_params[:q_row][0]
#                 search_session[:counter] = 1
                  session[:search][:"#{field_query}"] =  user_params[:q_row][0]
               end
     
               pass_param = {field_query => user_params[field_query]}
               returned_query = ParsingNesting::Tree.parse(user_params[field_query])
               newstring = returned_query.to_query(pass_param)
               holdarray = newstring.split('}')
               q_string << "_query_:\"{!dismax" # spellcheck.dictionary=" + blacklight_config.search_field['#{field_queryArray[0]}'] + " qf=$" + blacklight_config.search_field['#{field_queryArray[0]}'] + "_qf pf=$" + blacklight_config.search_field['#{field_queryArray[0]}'] + "_pf}" + blacklight_config.search_field['#{field_queryArray[1]}'] + "\""
               fieldNames = blacklight_config.search_fields["#{field_query}"]
               if !fieldNames["solr_parameters"].nil?
                  solr_stuff = fieldNames["solr_parameters"]
                  field_name = solr_stuff[:"spellcheck.dictionary"]
                  q_string << " spellcheck.dictionary=" << field_name << " qf=$" << field_name << "_qf pf=$" << field_name << "_pf"
                  q_string_hold = q_string
               end
#              q_string << "}" << user_params[shrink_rows[i]] << '\\'
               if holdarray.count > 2
                 if field_name.nil?
                    field_name = 'all_fields'
                 end
                 for i in 1..holdarray.count - 1
                   holdarray_parse = holdarray[i].split('_query_')
                   holdarray[1] = holdarray_parse[0].chomp("\"")
                   if(i < holdarray.count - 1)
                    q_string << "}" << holdarray[1] << " _query_:\"{!dismax spellcheck.dictionary=" << field_name << " qf=$" << field_name << "_qf pf=$" << field_name << "_pf" #}" << holdarray[1].chomp("\"") << "\""
                   else
                    q_string << "}" << holdarray[1].chomp("\"") << "\""
                   end
                 end 
               else
                 q_string << "}" << holdarray[1].chomp("\"") << "\""
               end
              if i < shrink_rows.count - 1
                 q_string << " " << opArray[i] << " "
              end
         end
       end
        #{:qt=>nil, :rows=>20, :fl=>"*,score", :"facet.field"=>["online", "format", "author_facet", "pub_date_facet", "language_facet", "subject_topic_facet", "subject_geo_facet", "subject_era_facet", "subject_content_facet", "lc_1letter_facet", "location_facet", "hierarchy_facet"], "spellcheck.q"=>nil, :"f.online.facet.limit"=>3, :"f.format.facet.limit"=>6, :"f.author_facet.facet.limit"=>6, :"f.language_facet.facet.limit"=>6, :"f.subject_topic_facet.facet.limit"=>6, :"f.subject_geo_facet.facet.limit"=>6, :"f.subject_era_facet.facet.limit"=>6, :"f.subject_content_facet.facet.limit"=>6, :"f.lc_1letter_facet.facet.limit"=>6, :"f.location_facet.facet.limit"=>6, :sort=>"score desc, pub_date_sort desc, title_sort asc", "stats"=>"true", "stats.field"=>["pub_date_facet"],
      #  :q=>"_query_:\"{!dismax spellcheck.dictionary=subject qf=$subject_qf pf=$subject_pf}+turin +shroud\" NOT _query_:\"{!dismax spellcheck.dictionary=author qf=$author_qf pf=$author_pf}Nickell\"", :fq=>[], :defType=>"lucene"}
      solr_parameters[:q] = q_string
      Rails.logger.debug("THEQUERY = #{solr_parameters}")
 #     solr_parameters[:q] = "_query_:\"{!dismax spellcheck.dictionary=subject qf=$subject_qf pf=$subject_pf}+turin +shroud\" NOT _query_:\"{!dismax spellcheck.dictionary=author qf=$author_qf pf=$author_pf}Nickell\""
    end
   return solr_parameters
  end

  def set_advanced_search_params(params)
         params["advanced_query"] = "yes"
         counter = test_size_param_array(params[:q_row])
         if counter > 1
            query_string = massage_params(params)
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
            search_session = {}
            params.delete("advanced_query")
            query_string = parse_single(params)
            Rails.logger.debug("DrippitySplit = #{query_string}")
            holdparams = query_string.split("&")
            for i in 0..holdparams.count - 1
              terms = holdparams[i].split("=")
              params[terms[0]] = terms[1]
              search_session[terms[0]] = terms[1]
              session[:search][:"#{terms[0]}"] = terms[1]
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
              new_query = "(" << current_query << ") " << params[:boolean_row][n.to_sym] << " (" << new_query_string << ")"
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
          query_string_two << newArray[i*2] << "=(" << newArray[(i*2)+1] << ")&op[]=" << opArray[i] << "&"
         else
          query_string_two << newArray[i*2] << "=(" << newArray[(i*2)+1] << ")"
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
