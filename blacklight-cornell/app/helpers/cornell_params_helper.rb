module CornellParamsHelper
  DEFAULT_BOOLEAN = 'AND'
  DEFAULT_OP = 'AND'
  DEFAULT_SEARCH_FIELD = 'all_fields'

  # Convert simple and browse search params to params suitable for prefilling advanced search form
  def convert_to_advanced_params(params)
    relevant_params = params.slice(:f, :range, :f_inclusive, :q, :search_field, :authq, :browse_type)
    return {} if relevant_params.blank?

    advanced_params = relevant_params.slice(:f, :range, :f_inclusive).merge(q_row: [params[:q] || params[:authq] || ''])
    if relevant_params[:search_field] == 'title_starts'
      # Set op_row and search_field_row
      advanced_params.merge(
        op_row: ['begins_with'],
        search_field_row: ['title']
      )
    else
      # Set search_field_row
      if relevant_params[:browse_type].present?
        # Set search_field_row based on browse_type
        browse_type_to_search_field_map = {
          'Author' => 'author',
          'Author-Title' => 'author',
          'Subject' => 'subject',
          'Call-Number' => 'lc_callnum'
        }
        search_field = browse_type_to_search_field_map[relevant_params[:browse_type]]
      else
        # Set search_field_row based on search_field
        search_field = relevant_params[:search_field] || DEFAULT_SEARCH_FIELD
      end
      advanced_params.merge(search_field_row: [search_field])
    end
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

def deep_copy(o)
  Marshal.load(Marshal.dump(o))
end

  # DACCESS-215
  def query_has_pub_date_facet?
    return params[:range].present? && params[:range].keys.include?('pub_date_facet')
  end

end
