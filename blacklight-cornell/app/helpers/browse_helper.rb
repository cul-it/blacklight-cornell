module BrowseHelper

  def browse_url(authq, browse_type, start=0, order=nil)
    url = "/browse?authq=#{CGI.escape authq}&browse_type=#{browse_type}&start=#{start}"
    if order.present?
      url += "&order=#{order}"
    end
    return url
  end
  
  def cleanup_bio_data(bd)
    bd.reject { |k, v| k == 'Field' if bd.key?('Occupation') }
  end

  def render_bio_data(bd)
    html = ''
    bd.each do |t,d|
      unless t == 'Gender'
        if t == 'Group/Organization'
          t = 'Affiliation'
        end
        html += "<dt>#{t}:</dt><dd>"
        if t == 'Occupation'
          d.each do |data|
            if !data.equal?(d.last)
              html += data.gsub(/s$/, '') + ', '
            else
              html += data.gsub(/s$/, '')
            end
          end
        else
          html += d if !d.kind_of?(Array)
          html += d.join(', ') if d.kind_of?(Array)
        end
        html += '</dd>'
      end
    end
    return html.html_safe
  end

  def render_reference_info(h_response, loc_localname)
    alt_form_count = h_response['alternateForm'].present? ? h_response['alternateForm'].size : 0
    html = ''
    if h_response['headingTypeDesc'].present? 
      html += build_heading_type(h_response['headingTypeDesc']) 
    end 
    if alt_form_count > 0 
      html += build_alt_forms(h_response['alternateForm'])
    end
    if !loc_localname.blank?
      if loc_localname[1..2] == 'sh'
        html += build_lcsh_link(loc_localname.gsub('"',''))
      else
        html += build_lcnaf_link(loc_localname.gsub('"',''))
      end
    end
    return html.html_safe
  end

def build_heading_type(heading_type)
   html = '<dl class="dl-horizontal"><dt>Heading Type:</dt><dd>' + heading_type + '</dd></dt></dl>'
   return html.html_safe
 end

 def build_lcnaf_link(localname)
   html = '<div id="lcnaf-link" class="mt-2 mb-4"><span><a href="https://id.loc.gov/authorities/names/' + localname
   html += '.html">Library of Congress Name Authority File (LCNAF)<i class="fa fa-external-link" aria-hidden="true"></i></a></span></div>'
   return html.html_safe
 end

 def build_lcsh_link(localname)
   html = '<div id="lcnaf-link" class="mt-2 mb-4"><span><a href="https://id.loc.gov/authorities/subjects/' + localname
   html += '.html">Library of Congress Subject Headings (LCSH)<i class="fa fa-external-link" aria-hidden="true"></i></a></span></div>'
   return html.html_safe
 end

 def build_alt_forms(alt_forms)
   alt_form_count = alt_forms.size
   html = ""
   if alt_form_count > 0 && alt_form_count < 13
     html = '<dl class="dl-horizontal"><dt>Alternate Form(s):</dt>'
     alt_forms.each do |af|
       html += '<dd>' + af + '</dd>'
  	 end
     html += "</dl>"
   elsif alt_form_count >= 13
     html = '<div>Alternate Form(s)
     : </div><div class="row" style="margin: 0;padding-top: 10px;"><div class="col-md-6">'
     count = 0
     alt_form_count = alt_form_count + 1 unless alt_form_count.even?
     split_at = alt_form_count / 2
     list = ""
     alt_forms.each do |af|
       if count <= split_at
         list += "<p>" + af + "</p>"
         count = count + 1
       elsif
         list += '</div> <!-- elsif div--><div class="col-md-6">'
         count = 0
         list += '<p>' + af + '</p>'
         count = count + 1
       end
     end
     html += list + "</div><!-- first closing div--></div><!-- second closing div-->"
   end
    return html.html_safe   
 end

  def build_search_link(format, f_count)
    browse_field_count = @heading_document.browse_fields.count
    boolean_row = {}
    (browse_field_count - 1).times { |i| boolean_row[i + 1] = 'OR' }
    search_params = {
      advanced_query: 'yes',
      search_field: 'advanced',
      search_field_row: @heading_document.browse_fields,
      boolean_row: boolean_row,
      op_row: ['AND'] * browse_field_count,
      q_row: [@heading_document['heading']] * browse_field_count,
      "f[format]": [format]
    }
    
    format_with_count = "#{pluralize_format(format)} (#{number_with_delimiter(f_count)})"
    link_id = "facet_link_#{format.downcase.gsub(/[\/\-\s]/, '_')}"
    link_to format_with_count, search_catalog_path(search_params).html_safe, id: link_id
  end

  def pluralize_format(format)
    format.split('/').map(&:pluralize).join('/')
  end
end
