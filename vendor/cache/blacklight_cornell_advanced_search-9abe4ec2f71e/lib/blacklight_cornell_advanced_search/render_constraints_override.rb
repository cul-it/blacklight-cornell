# Meant to be applied on top of Blacklight view helpers, to over-ride
# certain methods from RenderConstraintsHelper (newish in BL),
# to effect constraints rendering and search history rendering,
module BlacklightCornellAdvancedSearch::RenderConstraintsOverride

  def query_has_constraints?(localized_params = params)
    !(localized_params[:q].blank? and localized_params[:f].blank? and localized_params[:f_inclusive].blank?)
  end



  def deep_copy(o)
    Marshal.load(Marshal.dump(o))
  end
  #Over-ride of Blacklight method, provide advanced constraints if needed,
  # otherwise call super. Existence of an @advanced_query instance variable
  # is our trigger that we're in advanced mode.
  def render_advanced_constraints_query(params)
    labels = []
    values = []
    q_string = params["q"]
    q_parts = q_string.split('&')
    if (@advanced_query.nil? || @advanced_query.keyword_queries.empty? )
      return render_constraints(params)
    else      
      content = ""
##      if (@advanced_query.keyword_queries.count == 2)
      if (q_parts.count == 3)
         
         params.delete("advanced_query")
         0.step(2, 2) do |x|
           label = ""
           parts = q_parts[x].split('=')
           if x == 0
             hold = q_parts[2].split('=')
           else
             hold = q_parts[0].split('=')
           end
           if x%2 == 0
             if x - 1 > 0
               opval = q_parts[x - 1].split('=')
               label = opval[1] << " "            
               label << search_field_def_for_key(parts[0])[:label]
             else
               label = search_field_def_for_key(parts[0])[:label]
             end
             facetparams = ""
             if (params[:f].present?)
               start1 = "f["
               next1 = ""
               count = 0
               Rails.logger.debug("Facet params = #{params[:f]}")
               params[:f].each do |key, value|
                   next1 = ""
                   start2 = start1 + key + "][]="
                 value.each do |v|
                   next1 =  next1 + start2 + v + "&"
                 end
                 facetparams = facetparams + next1
               end
             else
               facetparams = ""
             end
             removeString = "catalog?q=" + hold[1] + "&search_field=" + hold[0] + "&" + facetparams + "action=index&commit=Search"
             content << render_constraint_element(
               label, parts[1],
#               :remove => "catalog?q=" + hold[1] + "&search_field=" + hold[0] + "&action=index&commit=Search"
               :remove => removeString
             )
           else
             content << " " << parts[1] << " "
           end  
         end       
      else
          if (q_parts.count < 2)
            label = search_field_def_for_key(params["search_field"])          
            content << render_constraint_element(
               "Should not be here", params["q"],
               :remove => "?"
            )
          else          
           0.step(q_parts.count - 1, 2) do |x|
             label = ""
             parts = q_parts[x].split('=')
             if x <= q_parts.count - 1
               hold = q_parts[x].split('=')
             else
               hold = q_parts[x].split('=')
             end
               Rails.logger.debug("Wookieparams = #{params}")
             if x%2 == 0
               if x - 1 > 0
                 opval = q_parts[x - 1].split('=')
                 label = opval[1] << " "            
                 label << search_field_def_for_key(parts[0])[:label]
               else
                 label = search_field_def_for_key(parts[0])[:label]
               end
               remove_indexes = []
               icount = 0
               temp_search_field_row = []
               temp_q_row = []
               temp_op_row = []
               temp_boolean_rows = deep_copy(params)
               temp_boolean_row = []
               for i in 1..temp_boolean_rows[:search_field_row].count
                 n = i.to_s
                 temp_boolean_row << temp_boolean_rows[:boolean_row][n.to_sym]
               end 
               deleted = 0
               params[:search_field_row].each do |val, indx|
                 if val == parts[0]
                  remove_indexes << icount
                  if icount <= 1
                      temp_boolean_row.delete_at(0)
                      deleted = deleted +1
                  else
                     if icount == params[:search_field_row].count - 1 
                      temp_boolean_row.delete_at(temp_boolean_row.count - 1)
                      deleted = deleted +1
                     else
                       temp_boolean_row.delete_at(icount - 1)
                       deleted = deleted +1 
                     end 
                  end
                 else
                  temp_search_field_row << params[:search_field_row][icount]
                  temp_q_row << params[:q_row][icount]
                  temp_op_row << params[:op_row][icount]
                 end
                 icount = icount + 1
               end               
               autoparam = "" 
               for i in 0..temp_q_row.count - 1
                 autoparam << "q_row[]=" << temp_q_row[i] << "&op_row[]=" << temp_op_row[i] << "&search_field_row[]=" << temp_search_field_row[i] 
                 if i < temp_q_row.count - 1
                    Rails.logger.debug("ChooChoo = #{temp_boolean_row}")
                    autoparam << "&boolean_row[#{i + 1}]=" << temp_boolean_row[i] << "&"
                 end 
               end
               Rails.logger.debug("CONSTRAINTsPARAMS4 = #{params}")
             facetparams = ""
             if (params[:f].present?)
               start1 = "f["
               next1 = ""
               count = 0
               Rails.logger.debug("Facet params = #{params[:f]}")
               params[:f].each do |key, value|
                   next1 = ""
                   start2 = start1 + key + "][]="
                 value.each do |v|
                   next1 =  next1 + start2 + v + "&"
                 end
                 facetparams = facetparams + next1
               end
             else
               facetparams = ""
             end
             removeString = "catalog?" + autoparam + "&" + facetparams + "action=index&commit=Search&advanced_query=yes"

               content << render_constraint_element(
                 label, parts[1],
#                 :remove => "catalog?" + autoparam + "&action=index&commit=Search&advanced_query=yes"
                 :remove => removeString
#                 :remove => "catalog?" + autoparam +"&q=" + hold[1] + "&search_field=" + hold[0] + "&action=index&commit=Search"
#                 :remove => catalog_index_path(remove_advanced_keyword_query(parts[0],params))
               )
             else
               content << " " << parts[1] << " "
             end  
         end       

           
           
          end
      end
#      end  
        Rails.logger.debug("AdvancedQueryKeywordOp = #{@advanced_query.keyword_op}")
      #  if (@advanced_query.keyword_op == "OR" &&
      #      @advanced_query.keyword_queries.length > 1)
      #    content = '<span class="inclusive_or appliedFilter">' + '<span class="operator">Any of:</span>' + content + '</span>'
      #  end
      return content
    end
  end




  #Over-ride of Blacklight method, provide advanced constraints if needed,
  # otherwise call super. Existence of an @advanced_query instance variable
  # is our trigger that we're in advanced mode.
  def render_constraints_query(my_params = params)
    if (@advanced_query.nil? || @advanced_query.keyword_queries.empty? )
      return super(my_params)
    else
      content = ""
      @advanced_query.keyword_queries.each_pair do |field, query|
        label = search_field_def_for_key(field)[:label]
        content << render_constraint_element(
          label, query,
          :remove =>
            catalog_index_path(remove_advanced_keyword_query(field,my_params))
        )
      end
      if (@advanced_query.keyword_op == "OR" &&
          @advanced_query.keyword_queries.length > 1)
        content = '<span class="inclusive_or appliedFilter">' + '<span class="operator">Any of:</span>' + content + '</span>'
      end

      return content
    end
  end

  #Over-ride of Blacklight method, provide advanced constraints if needed,
  # otherwise call super. Existence of an @advanced_query instance variable
  # is our trigger that we're in advanced mode.
  def render_constraints_filters(my_params = params)
    content = super(my_params)

    if (@advanced_query)
      @advanced_query.filters.each_pair do |field, value_list|
        label = facet_field_labels[field]
        content << render_constraint_element(label,
          value_list.join(" OR "),
          :remove => catalog_index_path( remove_advanced_filter_group(field, my_params) )
          )
      end
    end

    return content
  end

  def render_search_to_s_filters(my_params)
    content = super(my_params)

    advanced_query = BlacklightCornellAdvancedSearch::QueryParser.new(my_params, blacklight_config )

    if (advanced_query.filters.length > 0)
      advanced_query.filters.each_pair do |field, values|
        label = facet_field_labels[field]

        content << render_search_to_s_element(
          label,
          values.join(" OR ")
        )
      end
    end
    return content
  end

  def render_search_to_s_q(my_params)
    content = super(my_params)

    advanced_query = BlacklightCornellAdvancedSearch::QueryParser.new(my_params, blacklight_config )

    if (advanced_query.keyword_queries.length > 1 &&
        advanced_query.keyword_op == "OR")
        # Need to do something to make the inclusive-or search clear

        display_as = advanced_query.keyword_queries.collect do |field, query|
          h( search_field_def_for_key(field)[:label] + ": " + query )
        end.join(" ; ")

        content << render_search_to_s_element("Any of",
          display_as,
          :escape_value => false
        )
    elsif (advanced_query.keyword_queries.length > 0)
      advanced_query.keyword_queries.each_pair do |field, query|
        label = search_field_def_for_key(field)[:label]

        content << render_search_to_s_element(label, query)
      end
    end

    return content
  end

end
