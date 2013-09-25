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

  def render_edited_advanced_search(params)    
    subject_values = [["all_fields", "All Fields"],["title", "Title"], ["journal title", "Journal Title"], ["author/creator", "Author/Creator"], ["subject", "Subject"],
                      ["call number", "Call Number"], ["series", "Series"], ["publisher", "Publisher"], ["place of publication", "Place Of Publication"],
                      ["publisher number/other identifier", "Publisher Number/Other Identifier"], ["isbn/issn", "ISBN/ISSN"], ["notes", "Notes"],
                      ["donor name", "Donor Name"]]
    boolean_values = [["AND", "all"], ["OR", "any"], ["phrase", "phrase"]]
    boolean_row_values = [["AND", "and"], ["OR", "or"], ["NOT", "not"]]
    word = ""
    row1 = ""
    row1 << "<input autocapitalize=\"off\" id=\"q_row\" name=\"q_row[]\" placeholder=\"Search....\" type=\"text\" value=\""  << params[:q_row][0] << "\" /> "
    row1 << "<select class=\"input-small\" id=\"op_row\" name=\"op_row[]\">"
    boolean_values.each do |key, value|
      if key == params[:op_row][0]
        row1 << "<option value=\"" << key << "\" selected>" << value << "</option>"
      else
        row1 << "<option value=\"" << key << "\">" << value << "</option>"
      end
    end
    row1 << "</select> in "
    row1 << "<select class=\"advanced-search-field\" id=\"search_field_row\" name=\"search_field_row[]\">"
    subject_values.each do |key, value|
      if key == params[:search_field_row][0]
        row1 << "<option value=\"" << key << "\" selected>" << value << "</option>"
      else
        row1 << "<option value=\"" << key << "\">" << value << "</option>"
      end 
    end
    row1 << "</select></div>"
    unless params[:q_row].count < 2
      next2rows = ""
      for i in 1..params[:q_row].count - 1
         next2rows << "<div class=\"input_row\"><div class=\"boolean_row\">"
         boolean_row_values.each do |key, value|
           n = i.to_s
           Rails.logger.info("LASTGASP=#{params[:boolean_row][n.to_sym]}")
           if key == params[:boolean_row][n.to_sym]
             next2rows << "<label class=\"radio inline\">"
             next2rows << "<input type=\"radio\" name=\"boolean_row[" << "#{i}" << "]\" value=\"" << key << "\" checked=\"checked\">" <<  value << " " 
             next2rows << "</label>"
           else
             next2rows << "<label class=\"radio inline\">"
             next2rows << "<input type=\"radio\" name=\"boolean_row[" << "#{i}" << "]\" value=\"" << key << "\">" <<  value << " " 
             next2rows << "</label>"
           end 
         end  
         next2rows << "</div>"
         next2rows << " <label for=\"q_row" << "#{i}" << " class=\"hide-text\"></label>"
         next2rows << "<input autocapitalize=\"off\" id=\"q_row\" name=\"q_row[]\" type=\"text\" value=\""  << params[:q_row][i] << "\" /> "
         next2rows << "<select class=\"input-small\" id=\"op_row\" name=\"op_row[]\">"
         boolean_values.each do |key, value|
           Rails.logger.info("HELP=#{params[:op_row][i]}")
           Rails.logger.info("HELP2=#{key}")
            if key == params[:op_row][i]
             next2rows << "<option value=\"" << key << "\" selected>" << value << "</option>"
            else
             next2rows << "<option value=\"" << key << "\">" << value << "</option>"
            end
         end
         next2rows << "</select> in " 
         next2rows << "<select class=\"advanced-search-field\" id=\"search_field_row\" name=\"search_field_row[]\">"
         subject_values.each do |key, value|
           if key == params[:search_field_row][i]
            next2rows << "<option value=\"" << key << "\" selected>" << value << "</option>"
           else
             next2rows << "<option value=\"" << key << "\">" << value << "</option>"
           end 
         end
          next2rows << "</select></div>"
      end
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

end
