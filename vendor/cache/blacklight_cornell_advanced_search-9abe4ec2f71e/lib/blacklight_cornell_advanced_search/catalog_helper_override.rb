module BlacklightCornellAdvancedSearch::CatalogHelperOverride

  
  
#  def remove_advanced_keyword_query(field, my_params = params)
#    my_params = my_params.dup
#    my_params.delete(field)
#    return my_params
#  end


  def deep_copy(o)
    Marshal.load(Marshal.dump(o))
  end  
  
  def remove_advanced_keyword_query(field, my_params)
 #   my_params = deep_copy(params)
    my_params.delete(field)
    my_params.delete('sort')
    if my_params["search_field_row"].count > 2
      if params["search_field_row"].include?(field)
        my_index = params["search_field_row"].index(field)
        if my_index == 0
           for i in 0..params["search_field_row"].count - 1
              my_params["boolean_row[#{i + 1}]"] = my_params["boolean_row[#{i + 1}]"]
           end
           my_params.delete("boolean_row[#{my_params['search_field_row'].count}]")
        end
        if my_index > 0 
           for j in my_index..params["search_field_row"].count - 1
              my_params["boolean_row[#{j}]"] = my_params["boolean_row[#{j + 1}]"]
           end
           my_params.delete("boolean_row[#{my_params['search_field_row'].count}]")              
        end
      end
      my_params["search_field_row"].delete_at(my_index)
      my_params["q_row"].delete_at(my_index)
      my_params["op_row"].delete_at(my_index)
      my_params.delete("op")
 #     my_params.delete("q")      
    end
    return my_params
  end

  def remove_advanced_filter_group(field, my_params = params)
    if (my_params[:f_inclusive])
      my_params = my_params.dup
      my_params[:f_inclusive] = my_params[:f_inclusive].dup
      my_params[:f_inclusive].delete(field)
    end
    my_params
  end

  # Special display for facet limits that include adv search inclusive
  # or limits.
  def facet_partial_name(display_facet = nil)
    return "blacklight_cornell_advanced_search/facet_limit" if @advanced_query && @advanced_query.filters.keys.include?( display_facet.name )
    super 
  end

  def remove_advanced_facet_param(field, value, my_params = params)
    my_params = my_params.dup
    if (my_params[:f_inclusive] && 
        my_params[:f_inclusive][field] &&
        my_params[:f_inclusive][field].include?(value))
        
      my_params[:f_inclusive] = my_params[:f_inclusive].dup
      my_params[:f_inclusive][field] = my_params[:f_inclusive][field].dup
      my_params[:f_inclusive][field].delete(value)
      
      my_params[:f_inclusive].delete(field) if my_params[:f_inclusive][field].length == 0
      
      my_params.delete(:f_inclusive) if my_params[:f_inclusive].length == 0      
    end

    my_params.delete_if do |key, value| 
      [:page, :id, :counter, :commit].include?(key)
    end
    
    my_params
  end
  
end
