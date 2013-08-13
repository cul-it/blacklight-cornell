module BlacklightAdvancedSearch::CatalogHelperOverride

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


  
end
