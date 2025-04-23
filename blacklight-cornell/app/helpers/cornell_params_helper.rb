module CornellParamsHelper
  DEFAULT_BOOLEAN = 'AND'
  DEFAULT_OP = 'AND'
  DEFAULT_SEARCH_FIELD = 'all_fields'

  # TODO: Similar to SearchBuilder#remove_blank_rows - can this be DRY-ed up?
  def remove_blank_rows(my_params = params || {})
    cleaned_params = { q_row: [], op_row: [], search_field_row: [], boolean_row: {} }
    row_count = my_params[:q_row].count
    row_count.times do |i|
      if my_params[:q_row][i].strip.present?
        cleaned_params[:q_row] << my_params[:q_row][i]
        cleaned_params[:op_row] << (my_params.fetch(:op_row, [])[i] || DEFAULT_OP)
        cleaned_params[:search_field_row] << (my_params.fetch(:search_field_row, [])[i] || DEFAULT_SEARCH_FIELD)
      end

      # Don't add last bool in boolean_row
      if cleaned_params[:q_row].present? && my_params[:q_row][i + 1].present?
        old_boolean_row_key = (i + 1).to_s
        cleaned_boolean_row_key = cleaned_params[:q_row].count.to_s
        cleaned_params[:boolean_row][cleaned_boolean_row_key] = (my_params.dig(:boolean_row, old_boolean_row_key) || DEFAULT_BOOLEAN)
      end
    end

    my_params.merge(cleaned_params)
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

def deep_copy(o)
  Marshal.load(Marshal.dump(o))
end

def render_advanced_constraints_query(params)
  return render_constraints(params) if params[:q_row].blank?

  # Create deep copy of params to not alter original search params hash
  my_params = params.present? ? params.deep_dup : {}
  my_params = remove_blank_rows(my_params)

  # Treat single row as a simple search
  if my_params[:q_row].count == 1
    # Set simple search params
    my_params[:search_field] = my_params[:search_field_row][0]
    my_params[:q] = my_params[:q_row][0]

    # Delete advanced search params
    my_params.delete(:q_row)
    my_params.delete(:search_field_row)
    my_params.delete(:op_row)
    my_params.delete(:boolean_row)
    my_params.delete(:show_query)

    return render_constraints(my_params)
  end

  content = ''
  my_params[:q_row].each_with_index do |query, i|
    # Constraint label
    label = search_field_def_for_key(my_params[:search_field_row][i])[:label]
    # Constraint label with boolean
    boolean_index = [i - 1, 0].max
    bool_arr = my_params[:boolean_row].values
    label = "#{bool_arr[boolean_index]} #{label}" if i > 0

    # Get search path minus the current row
    removed_params = my_params.deep_dup
    removed_params[:q_row].delete_at(i)
    removed_params[:search_field_row].delete_at(i)
    removed_params[:op_row].delete_at(i)
    # Reset number keys in boolean_row
    bool_arr.delete_at(boolean_index)
    removed_params[:boolean_row] = Hash[("1"..bool_arr.size.to_s).zip bool_arr]
    remove_path = search_catalog_path(removed_params)

    content << render_constraint_element(label, query, :remove => remove_path)
  end

  content << render_constraints_filters(params)
  content.html_safe
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
