module CornellParamsHelper
    def removeBlanks(my_params = params || {} )
       testQRow = [] #my_params[:q_row]
       testOpRow = []
       testSFRow = []
       testBRow = []
       for i in 0..my_params[:q_row].count - 1
          if my_params[:q_row][i] != '' and !my_params[:q_row][i].nil?
             testQRow << my_params[:q_row][i]
             testOpRow << my_params[:op_row][i]
             testSFRow << my_params[:search_field_row][i]
          end
       end
       hasNonBlankcount = 0
       for i in 0..my_params[:q_row].count - 1
          if my_params[:q_row][i].blank? or my_params[:q_row][i].nil?
          #  if i == 0
          #    next
          #  end
          #  if i == my_params[:q_row].count - 1
            next
          #  end
          else
            hasNonBlankcount = hasNonBlankcount + 1
            if i == my_params[:q_row].count - 1 and  hasNonBlankcount > 1
                if !my_params[:boolean_row][i.to_s.to_sym].nil?
                testBRow << my_params[:boolean_row][i.to_s.to_sym]
                end
            end
            if i < my_params[:q_row].count - 1 #and (hasNonBlankcount > 1 and my_params[:q_row][i + 1].blank?)
              if my_params[:boolean_row].nil?
                my_params[:boolean_row] = {"1" => "AND"}
              else
                if !my_params[:boolean_row][i.to_s.to_sym].nil?
                testBRow << my_params[:boolean_row][i.to_s.to_sym]
                end
              end
            end
          end
       end
        my_params[:q_row] = testQRow
        my_params[:op_row] = testOpRow
        my_params[:search_field_row] = testSFRow
        my_params[:boolean_row] = testBRow
       return my_params
     end

 def getCallNos(doc)
   require 'json'
   @recordCallNumArray = []
   myhash = {}

   if doc[:holdings_json].present?
     thisHash = JSON.parse(doc[:holdings_json])
     hash_size = thisHash.size
     loop_count = 0
     thisHash.each do |k, v|
       loop_count += 1
       if v.present?
         newHash = {}
         newHash = v
         if newHash["online"].present? and newHash["online"] == true
           tmpStr = "*Networked resource, No Call Number"
           tmpStr += " || " if loop_count < hash_size
           tmpStr += " | " if loop_count == hash_size
           @recordCallNumArray << tmpStr
         elsif newHash['call'].present?
           tmpStr = newHash['call']
           tmpStr += " || " if loop_count < hash_size
           tmpStr += " | " if loop_count == hash_size
           @recordCallNumArray << tmpStr
         else
           @recordCallNumArray << "No Call Number, possibly still on order. Please contact the Circulation Desk at (607) 255-4245 or email okucirc@cornell.edu"
         end
       end
     end
   end
   return @recordCallNumArray
 end

# Similar to getItemStatus but without the available/unavailable. Is this really needed?
def getLocations(doc)
  require 'json'
  require 'pp'
  @recordLocsNameArray = []
  myhash = {}

  if doc[:holdings_json].present?
    thisHash = JSON.parse(doc[:holdings_json])
    hash_size = thisHash.size
    loop_count = 0
    thisHash.each do |k, v|
      loop_count += 1
      if v.present?
        newHash = {}
        newHash = v
        if newHash["online"].present? and newHash["online"] == true
          tmpStr = "*Networked resource"
          tmpStr += " || " if loop_count < hash_size
          tmpStr += " | " if loop_count == hash_size
          @recordLocsNameArray << tmpStr
        elsif newHash['location']["name"].present?
          tmpStr = newHash['location']["name"]
          tmpStr += " || " if loop_count < hash_size
          tmpStr += " | " if loop_count == hash_size
          @recordLocsNameArray << tmpStr
        else
          @recordLocsNameArray << ""
        end
      end
    end
  end
  return @recordLocsNameArray
end

def getTempLocations(doc)
  require 'json'
  require 'pp'
       @itemLocationArray = []
       myhash = {}
       if doc[:holdings_record_display].present?
          breakerlength = doc[:holdings_record_display].length
          i = 0
          doc[:holdings_record_display].each do |hrd|
           myhash = JSON.parse(hrd)
            unless !myhash["locations"][0]["name"].nil?
             if i == breakerlength - 1
               @itemLocationArray << myhash["locations"][0]["name"] + " || "
             else
               @itemLocationArray << myhash["locations"][0]["name"] + " | "
             end
            end
           i = i + 1
          end
       end
  return @itemLocationArray
end

def getItemStatus(doc)
  require 'json'
  require 'pp'

  @itemStatusArray = []
  @hideArray = []
  thisHash = {}
  if doc[:holdings_json].present?
    thisHash = JSON.parse(doc[:holdings_json])
    hash_size = thisHash.size
    loop_count = 0
    thisHash.each do |k, v|
      loop_count += 1
      if v.present?
        newHash = {}
        newHash = v
        if newHash["online"].present? and newHash["online"] == true
          tmpStr = "*Networked resource"
          tmpStr += " || " if loop_count < hash_size
          tmpStr += " | " if loop_count == hash_size
          @itemStatusArray << tmpStr
        elsif newHash['items'].present? and newHash['items']["avail"].present?
          tmpStr = "Available"
          tmpStr += " at " + newHash['location']["name"] if newHash['location'].present?
          tmpStr += " || " if loop_count < hash_size
          tmpStr += " | " if loop_count == hash_size
          @itemStatusArray << tmpStr
        elsif newHash['items'].present? and newHash['items']["unavail"].present?
          tmpStr = "Unavailable"
          tmpStr += " at " + newHash['location']["name"] if newHash['location'].present?
          tmpStr += " || " if loop_count < hash_size
          tmpStr += " | " if loop_count == hash_size
          @itemStatusArray << tmpStr
        else
          @itemStatusArray << ""
        end
      end
    end
  end
  return @itemStatusArray
end

  def render_constraints_cts(my_params = params)
    field = params[:search_field]
    if field == ''
      field = "all_fields"
    end
    label = search_field_def_for_key(field)[:label]
    query = params[:y]
    content = ""
    content << render_constraint_element(label, query,
          :remove => "?#{field}")
    content.html_safe
  end

  def render_constraints_query(my_params = params)
  if (@advanced_query.nil? || @advanced_query.keyword_queries.empty? )
    return  super(my_params)
  else
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


def render_advanced_constraints_query(params)
  # Create deep copy of params to not alter original search params hash
  my_params = params.present? ? params.deep_dup : {}
  if !my_params[:q_row].nil?
     my_params = removeBlanks(my_params)

  end
  if my_params[:search_field] == 'advanced'
 #   my_params.delete(:q)
  end
# my_params[:q] = ''
#  my_params[:show_query] = ''
  if ( my_params["q_row"].nil? and ( my_params["q"].nil? || my_params["q"].blank?))
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
 #     my_params.delete(:boolean_row)

      my_params[:search_field] = hold_search_field_row
      content = ""
      content << render_constraints(my_params)
      my_params[:q_row] = []
      my_params[:search_field_row] = []
      my_params[:op_row] = []
      my_params[:q_row][0] = hold_q_row
      my_params[:search_field_row][0] = hold_search_field_row
      my_params[:op_row][0] = hold_oprow
 #     my_params[:boolean_row] = {"1" => "AND"}
      return content.html_safe
    end
    if my_params[:boolean_row] == {}
  #   my_params[:boolean_row] = {"1" => "AND"}
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
      # With Rails 5 my_params[:f].count throws an error because the paras are now an object.
      # Commenting the block out since it doesn't  appear to do anything. If needed, the error
      # can be fixed this way: my_params.to_h[:f].count > 1
      # if(my_params[:f].count > 1)
      # end
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

     sfr = my_params[:search_field_row][0]
#     if my_params[:op_row][0] == "begins_with"
#       sfr = sfr << "_starts"
#     end
      new_q_parts[0] = sfr  + "=" + my_params[:q_row][0]
      for i in 1..my_params[:q_row].count - 1
        sfr = my_params[:search_field_row][i] #<< "=" << my_params[:q_row][i]
#        if my_params[:search_field_row][i] == "begins_with"
#          sfr = sfr << "_starts"
#
        n = i - 1
       # n = n.to_s
        if !my_params[:boolean_row].nil?
          if !my_params[:boolean_row][n].nil?
            new_q_parts[j] = "op[]=" << my_params[:boolean_row][n]
            new_q_parts[j+1] =  sfr + "=" + my_params[:q_row][i]
          end
        end
        j = j + 2
      end
#        q_parts = q_string.split('&')
    elsif !my_params[:q].nil? and !my_params[:q].blank? and !my_params[:search_field].nil?
     new_q_parts[0] = "q=" << CGI.escape(my_params[:q])
     new_q_parts[1] = "search_field=" << my_params[:search_field]
    end
    if (new_q_parts.count == 3 )
       andorcount = 0
     #  params.delete("advanced_query")
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

           if my_params[:op_row][andorcount] == "OR"
             lastq = qtoken(hold[1])
             if lastq.size > 1
             #  hold[1] = lastq.product([' OR ']).flatten(1)[0...-1].join()
             end
           end
           boolcount = andorcount + 1
           boolcount = boolcount.to_s
           removeString = "catalog?&q_row[]=" + CGI.escape(hold[1]) + "&boolean_row[" + boolcount + "]=AND" + "&op_row[]=" + my_params[:op_row][andorcount] + "&search_field_row[]=" + hold[0] + "&search_field=advanced&" + facetparams + "action=index&commit=Search"
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
        temp_boolean_rows = my_params[:boolean_row]
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
   #           if x == 0
   #             2.step(temp_boolean_rows[:boolean_row].count, 1) do |br|
   #               ss = br.to_s
   #               temp_boolean_row << temp_boolean_rows[:boolean_row][ss.to_sym]
   #             end
   #           else
   #             1.step(temp_boolean_rows[:boolean_row].count, 1) do |br|
   #               if x != br
   #                ss = br.to_s
   #                temp_boolean_row << temp_boolean_rows[:boolean_row][ss.to_sym]
   #               end
   #             end
   #           end

               if x >= 0 and x <= temp_boolean_rows.count
                   opval = temp_boolean_rows[x]
                   label << search_field_def_for_key(my_params[:search_field_row][x])[:label]
               else
                   label = search_field_def_for_key(my_params[:search_field_row][x])[:label]
               end

               autoparam = ""


               autoparam = ""
               for qp in 0..temp_q_row.length - 1

                  autoparam << "q_row[]=" << CGI.escape(temp_q_row[qp]) << "&op_row[]=" << temp_op_row[qp] << "&search_field_row[]=" << temp_search_field_row[qp]
                  if qp < temp_q_row.length - 1
                    autoparam << "&boolean_row[#{qp + 1}]=" << temp_boolean_rows[qp] << "&"
                  end



               end
               querybuttontext = my_params[:q_row][x] #parts[1]
               if querybuttontext.include?('%26')
                 querybuttontext = querybuttontext.gsub!('%26','&')
               end
               removeString = "catalog?utf8=%E2%9C%93&" + autoparam + "&" + facetparams + "search_field=advanced&action=index&commit=Search&advanced_query=yes"
               if x > 0
                 s = x.to_s
                 label = temp_boolean_rows[x - 1].to_s + " " + label
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
      removeString = make_remove_string(my_params,key)
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


def render_advanced_constraints_filters(params)
  # Create deep copy of params to not alter original search params hash
  my_params = params.present? ? params.deep_dup : {}

  return_content = ''
  if my_params[:f].present?
    my_params[:f].each do |key, value|
      label = facet_field_labels[key]
      value[0].gsub!('%26', '&')
      remove_string = make_remove_string(my_params, key)

      return_content << render_constraint_element(label,
                                                  value.join(' AND '),
                                                  :remove => '?' + remove_string)
    end
  end

  return return_content.html_safe
end

def render_edit_advanced_constraints_filters(my_params = params)
  return_content = "" #super(my_params)
#   if (@advanced_query)
   if(my_params[:f].present?)
   # @advanced_query.filters.each_pair do |field, value_list|
     my_params[:f].each do |key, value|
#        label = facet_field_labels[field]
      removeString = makeEditRemoveString(my_params, key)
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
 # return removeString.html_safe
  return return_content.html_safe
end

def make_remove_string(my_params, facet_key)
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
  if !boolean_row.nil? #and boolean_row.count >= 1
   boolean_row.each do |key, value|
     if !key.nil? and !value.nil?
     boolean_row_string << "boolean_row[" + key + "]=" + value + "&"
     else
      boolean_row_string << "boolean_row[1]=" + my_params["boolean_row"][0] + "&"
     end
   end

  else
    boolean_row_string = "boolean_row[1]=" #+ my_params["boolean_row"]
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
    q_string = "q=" << CGI.escape(q) << "&"
  else
    q = ""
  end
  q_row = my_params["q_row"]
  q_row_string = ""
  if !q_row.nil?
    for i in 0..q_row.count - 1
      q_row_string << "q_row[]=" << CGI.escape(q_row[i]) << "&"
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
    if CGI.escape(q) == ''
      if facets_string != ''
        removeString = facets_string + "action=index&commit=Search"
      end
    else
       removeString = "q=" + CGI.escape(q) + "&" +search_field_string + "action=index&commit=Search"
    end
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

def makeEditRemoveString(my_params, facet_key)
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
  if !boolean_row.nil? #and boolean_row.count >= 1
   boolean_row.each do |key, value|
     if !value.nil?
     boolean_row_string << "boolean_row[1]=" + value.to_s + "&"
#     else
#      boolean_row_string << "boolean_row[1]=" + my_params["boolean_row"][] + "&"
     end
   end

  else
    boolean_row_string = "boolean_row[1]=" #+ my_params["boolean_row"]
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
  op_row = Array(my_params["op_row"])
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
    q_string = "q=" << CGI.escape(q) << "&"
  else
    q = ""
  end
  q_row = Array(my_params["q_row"])
  q_row_string = ""
  if !q_row.nil?
    for i in 0..q_row.count - 1
      q_row_string << "q_row[]=" << CGI.escape(q_row[i]) << "&"
    end
  end
  search_field = my_params["search_field"]
  search_field_string = ""
  if !search_field.nil?
    search_field_string = "search_field=" << search_field << "&"
  end
  search_field_row = Array(my_params["search_field_row"])
  search_field_row_string = ""
  if !search_field_row.nil?
    for i in 0..search_field_row.count - 1
      search_field_row_string << "search_field_row[]=" << search_field_row[i] << "&"
    end
  end
  if ((q_row.nil? || q_row.count < 2) && !q.blank?)
    removeString = "bert=" + CGI.escape(q) + "&" +search_field_string + "action=index&commit=Search"
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
    #y = !(localized_params[:q].blank? and localized_params[:f].blank?)
    y = !(localized_params[:q].blank? and localized_params[:f].blank? and localized_params[:click_to_search].blank?) || (!localized_params[:search_field].blank? and (localized_params[:search_field] != 'all_fields'))
    y
  end

  def qtoken(q_string)
    qnum = q_string.count('"')
    if qnum % 2 == 1
      qstring = qstring + '"'
    end
      p = q_string.split(/\s(?=(?:[^"]|"[^"]*")*$)/)
    return p

  end

  # DACCESS-215
  def query_has_pub_date_facet?
    return params[:range].present? && params[:range].keys.include?('pub_date_facet')
  end

end
