# Helper methods for the advanced search form
module AdvancedHelper
  
  # Fill in default from existing search, if present
  # -- if you are using same search fields for basic
  # search and advanced, will even fill in properly if existing
  # search used basic search on same field present in advanced.
  def label_tag_default_for(key)
    if (! params[key].blank?)
      return params[key]
    elsif params["search_field"] == key
      return params["q"]
    else
      return nil
    end
  end

  # Is facet value in adv facet search results?
  def facet_value_checked?(field, value)
    params[:f_inclusive] && params[:f_inclusive][field] && params[:f_inclusive][field][value]
  end

  # Current params without fields that will be over-written by adv. search,
  # or other fields we don't want.
  def advanced_search_context
    my_params = params.dup
    [:page, :commit, :f_inclusive, :q, :search_field, :op, :action, :index, :sort, :controller].each do |bad_key|
      my_params.delete(bad_key)
    end
    search_fields_for_advanced_search.each do |key, field_def|
      my_params.delete( field_def[:key] )
    end
    my_params
  end

  def search_fields_for_advanced_search
    # If we could count on 1.9.3 with ordered hashes and
    # Hash#select that worked reasonably, this would be trivial.
    # instead, a way compat with 1.8.7 and 1.9.x both.
    @search_fields_for_advanced_search ||= begin
      # make it an ActiveSupport::OrderedHash if it needs to be
      hash = blacklight_config.search_fields.class.new
      blacklight_config.search_fields.each_pair do |key, value|
        hash[key] = value unless value.include_in_advanced_search == false
      end

      hash
    end
  end
  
  def render_edited_advanced_search_new(params)
    if params[:boolean_row].nil?
      params[:boolean_row] = []
      params[:boolean_row] << "AND"
    end
  end

  def render_edited_advanced_search(params)
    query = ""
    if params[:boolean_row].nil?
      params[:boolean_row] = [] #{"1"=>"AND"}
      params[:boolean_row] << "AND"
    end
    
    if params[:q_row].nil?
      params[:q_row] = []
      params[:q_row][0] = ''
    end
    if params[:op_row].nil?
      params[:op_row] = []
      params[:op_row][0] = "all"
    end
    if params[:search_field_row].nil?
      params[:search_field_row] = []
      params[:search_field_row][0] = 'all_fields'
    end
      
    subject_values = [["all_fields", "All Fields"],["title", "Title"], ["journal title", "Journal Title"], ["author/creator", "Author, etc."], ["subject", "Subject"],
                      ["call number", "Call Number"], ["series", "Series"], ["publisher", "Publisher"], ["place of publication", "Place Of Publication"],
                      ["publisher number/other identifier", "Publisher Number/Other Identifier"], ["isbn/issn", "ISBN/ISSN"], ["notes", "Notes"],
                      ["donor name", "Donor Name"]]
    boolean_values = [["AND", "all"], ["OR", "any"], ["phrase", "phrase"],["begins_with", "begins with"]]
    boolean_row_values = [["AND", "and"], ["OR", "or"], ["NOT", "not"]]
    word = ""
    row1 = ""
    if params[:q_row][0].include? ' ' and !(params[:q_row][0].start_with? '"' and params[:q_row][0].end_with? '"')
      query = "\'" + params[:q_row][0] + "\'"
    #  query = params[:q_row][0]
    else
      query = params[:q_row][0]
    end
#    params[:q_row][0].gsub!('\\\"','')
    row1 << "<input autocapitalize=\"off\" id=\"q_row\" class=\"form-control\" name=\"q_row[]\" placeholder=\"Search....\" type=\"text\"" 
    row1 << " value="  
    row1 << query #params[:q_row][0] 
    row1 << " /> "
    row1 << "<label for=\"op_row\" class=\"sr-only\">" << t('blacklight.search.form.op_row') << "</label>"
    row1 << "<select class=\"form-control\" id=\"op_row\" name=\"op_row[]\">"
    boolean_values.each do |key, value|
      if key == params[:op_row][0]
        row1 << "<option value=\"" << key << "\" selected>" << value << "</option>"
      else
        row1 << "<option value=\"" << key << "\">" << value << "</option>"
      end
    end
    row1 << "</select> in "
    row1 << "<label for=\"search_field_row\" class=\"sr-only\">" << t('blacklight.search.form.search_field_row') << "</label>"
    row1 << "<select class=\"advanced-search-field form-control\" id=\"search_field_row\" name=\"search_field_row[]\">"
    subject_values.each do |key, value|
      if key == params[:search_field_row][0]
        row1 << "<option value=\"" << key << "\" selected>" << value << "</option>"
      else
        row1 << "<option value=\"" << key << "\">" << value << "</option>"
      end
    end
    row1 << "</select>"
    unless params[:q_row].count <= 1
      next2rows = ""
      for i in 1..params[:q_row].count - 1
        if params[:q_row][i].include? ' '
          params[:q_row][i] = "\'" + params[:q_row][i] + "\'"
        #  query = params[:q_row][0]
        else
          params[:q_row][i] = params[:q_row][i]
        end

         next2rows << "<div class=\"input_row\"><div class=\"boolean_row radio\">"
         boolean_row_values.each do |key, value|
           n = i - 1 #= i.to_s
           if key == params[:boolean_row][n]
             next2rows << "<label class=\"radio-inline\">"
             next2rows << "<input type=\"radio\" name=\"boolean_row[" << "#{i}" << "]\" value=\"" << key << "\" checked=\"checked\">" <<  value << " "
             next2rows << "</label>"
           else
             next2rows << "<label class=\"radio-inline\">"
             next2rows << "<input type=\"radio\" name=\"boolean_row[" << "#{i}" << "]\" value=\"" << key << "\">" <<  value << " "
             next2rows << "</label>"
           end
         end
         next2rows << "</div>"
         next2rows << "<div class=\"form-group\">"
         next2rows << "<label for=\"q_row" << "#{i}\"" << " class=\"sr-only\">" << t('blacklight.search.form.q_row') << "</label>"
         next2rows << "<input autocapitalize=\"off\" class=\"form-control\" id=\"q_row" << "#{i}" << "\" name=\"q_row[]\" type=\"text\" value="  << params[:q_row][i] << " /> "
         next2rows << "<label for=\"op_row" << "#{i}\" class=\"sr-only\">" << t('blacklight.search.form.op_row') << "</label>"
         next2rows << "<select class=\"form-control\" id=\"op_row" << "#{i}" << "\" name=\"op_row[]\">"
         boolean_values.each do |key, value|
            if key == params[:op_row][i]
             next2rows << "<option value=\"" << key << "\" selected>" << value << "</option>"
            else
             next2rows << "<option value=\"" << key << "\">" << value << "</option>"
            end
         end
         next2rows << "</select> in "
         next2rows << "<label for=\"search_field_row" << "#{i}\" class=\"sr-only\">" << t('blacklight.search.form.search_field_row') << "</label>"
         next2rows << "<select class=\"advanced-search-field form-control\" id=\"search_field_row" << "#{i}" << "\" name=\"search_field_row[]\">"
         subject_values.each do |key, value|
           if key == params[:search_field_row][i]
            next2rows << "<option value=\"" << key << "\" selected>" << value << "</option>"
           else
             next2rows << "<option value=\"" << key << "\">" << value << "</option>"
           end
         end
          next2rows << "</select></div></div>"
      end
    else
      next2rows = ""
      next2rows << "<div class=\"input_row\"><div class=\"boolean_row radio\">"
      boolean_row_values.each do |key, value|
           if params[:boolean_row][1].blank?
             params[:boolean_row][1] = "AND"
           end
           n = 1.to_s
           if key == params[:boolean_row][1]
             next2rows << "<label class=\"radio-inline\">"
             next2rows << "<input type=\"radio\" name=\"boolean_row[" << "#{1}" << "]\" value=\"" << key << "\" checked=\"checked\">" <<  value << " "
             next2rows << "</label>"
           else
             next2rows << "<label class=\"radio-inline\">"
             next2rows << "<input type=\"radio\" name=\"boolean_row[" << "#{1}" << "]\" value=\"" << key << "\">" <<  value << " "
             next2rows << "</label>"
           end
      end
      next2rows << "</select></div></div>"
      next2rows << "<input autocapitalize=\"off\" id=\"q_row\" class=\"form-control\" name=\"q_row[]\" placeholder=\"Search....\" type=\"text\" value=\""  <<  "\" /> "
      next2rows << "<label for=\"op_row" << "#{i}\" class=\"sr-only\">" << t('blacklight.search.form.op_row') << "</label>"
      next2rows << "<select class=\"form-control\" id=\"op_row\" name=\"op_row[]\">"
      boolean_values.each do |key, value|
         if key == params[:op_row][0]
           next2rows << "<option value=\"" << key << "\" selected>" << value << "</option>"
         else
           next2rows << "<option value=\"" << key << "\">" << value << "</option>"
         end
      end
    next2rows << "</select> in "
    next2rows << "<label for=\"search_field_row\" class=\"sr-only\">" << t('blacklight.search.form.search_field_row') << "</label>"
    next2rows << "<select class=\"advanced-search-field form-control\" id=\"search_field_row\" name=\"search_field_row[]\">"
    subject_values.each do |key, value|
      if key == params[:search_field_row][0]
        next2rows << "<option value=\"" << key << "\" selected>" << value << "</option>"
      else
        next2rows << "<option value=\"" << key << "\">" << value << "</option>"
      end
    end
    
    next2rows << "</select>"
    end

    fparams = ""
    unless params[:f].nil?
       params[:f].each do |key, value|
         value.each do |name|
          fparams << "<input type=\"hidden\" name=\"f[" << key << "][]\" value=\"" << name << "\"/>"
         end
      end
    end
    word << row1 << next2rows << fparams
    return word.html_safe
  end
  
  
  def search_as_hidden_fields(options={})
    my_params = cornell_params_for_search({:omit_keys => [:page]}.merge(options))

    # hash_as_hidden_fields in hash_as_hidden_fields.rb
    return hash_as_hidden_fields(my_params)
  end

  def hash_as_hidden_fields(hash)

    hidden_fields = []
    flatten_hash(hash).each do |name, value|
      value = [value] if !value.is_a?(Array)
      value.each do |v|
        hidden_fields << hidden_field_tag(name, v.to_s, :id => nil)
      end
    end

    hidden_fields.join("\n").html_safe
  end

  def flatten_hash(hash = params, ancestor_names = [])
    flat_hash = {}
    hash.each do |k, v|
      names = Array.new(ancestor_names)
      names << k
      if v.is_a?(Hash)
        flat_hash.merge!(flatten_hash(v, names))
      else
        key = flat_hash_key(names)
        key += "[]" if v.is_a?(Array)
        flat_hash[key] = v
      end
    end

    flat_hash
  end

  def flat_hash_key(names)
    names = Array.new(names)
    name = names.shift.to_s.dup
    names.each do |n|
      name << "[#{n}]"
    end
    name
  end
  
    

end
