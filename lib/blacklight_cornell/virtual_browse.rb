#encoding: UTF-8
module BlacklightCornell::VirtualBrowse extend Blacklight::Catalog
#  extend ActiveSupport::Concern
#
#  include Blacklight::Configurable
#  include Blacklight::SolrHelper
#  include CornellCatalogHelper
#  include ActionView::Helpers::NumberHelper
#  include CornellParamsHelper
#  include Blacklight::SearchContext
#  include Blacklight::TokenBasedUser
#  include ActsAsTinyURL
  @@browse_index_callnumber = ENV['BROWSE_INDEX_CALLNUMBER'].nil? ? 'callnum' : ENV['BROWSE_INDEX_CALLNUMBER']

  # gets the documents on either "side" of the selected one. Direction determines whether
  # to get the previous or next group of docs.
  def get_surrounding_docs(callnumber,direction,start,rows, location="")
    @location = location.gsub('&','%26')
    base_solr_url = Blacklight.connection_config[:url].gsub(/\/solr\/.*/,'/solr')
    dbclnt = HTTPClient.new
    solrResponseFull = []
    return_array = []
    callno = callnumber.gsub("\\"," ").gsub('"',' ')
    params = {
      :wt => 'json',
      :fq => location,
      :fl => '*',
      :start => start.to_s,
      :rows => rows.to_s
    }
    uri = ''
    if direction == "reverse"
      # q =  {"q" => '[* TO "' + callnumber.gsub("\\"," ").gsub('"',' ') +'"]' }
      params[:q] = '[* TO "' + callno + '"]'
      # url = base_solr_url + "/" + @@browse_index_callnumber + "/reverse?wt=json&" + q.to_param + '&fq=' + location.gsub(" ", "+").gsub("&", "%26") + '&fl=*&start=' + start.to_s + '&rows=' + rows.to_s
      uri = URI(base_solr_url + "/" + @@browse_index_callnumber + "/reverse")
    else
      # q =  {"q" => '["' + callnumber.gsub("\\"," ").gsub('"',' ') +'" TO *]' }
      params[:q] = '["' + callno +'" TO *]'
      # url = base_solr_url + "/" + @@browse_index_callnumber + "/browse?wt=json&" + q.to_param + '&fq=' + location.gsub(" ", "+").gsub("&", "%26") + '&fl=*&start=' + start.to_s + '&rows=' + rows.to_s
      uri = URI(base_solr_url + "/" + @@browse_index_callnumber + "/browse")
    end
    uri.query = URI.encode_www_form(params)
#******************
save_level = Rails.logger.level; Rails.logger.level = Logger::WARN
jgr25_context = "#{__FILE__}:#{__LINE__}"
Rails.logger.warn "jgr25_log\n#{jgr25_context}:"
msg = [" #{__method__} ".center(60,'Z')]
msg << jgr25_context
msg << "uri: " + uri.inspect
msg << 'Z' * 60
msg.each { |x| puts 'ZZZ ' + x.to_yaml }
Rails.logger.level = save_level
#binding.pry
#*******************
    # solrResultString = dbclnt.get_content( url )
    solrResultString = dbclnt.get_content( uri )
    if !solrResultString.nil?
      y = solrResultString
      solrResponseFull = JSON.parse(y)
      solrResponseFull["response"]["docs"].each do |doc|
        tmp_hash = get_document_details(doc)
        return_array.push(tmp_hash)
      end
    else
      return_array = nil
    end
    return return_array
  end

  # pulls values from the solr document and returns them in a hash
  def get_document_details(doc)
    tmp_hash = {}
    tmp_hash["id"] = doc["bibid"]
    tmp_hash["location"] = doc["location"].present? ? doc["location"] : ""
    tmp_hash["title"] = doc["fulltitle_display"].present? ? doc["fulltitle_display"] : ""
    if doc["format"].present?
      if doc["format"][1].present? and doc["format"][1] == "Microform"
        the_format = doc["format"][1]
      else
        the_format = doc["format"][0]
      end
    else
      the_format = ""
    end
    # oclc_id and isbn are used to get the images from googlebooks
    oclc_id = doc["oclc_id_display"].present? ? doc["oclc_id_display"][0] : ""
    isbn = doc["isbn_display"].present? ? doc["isbn_display"][0].split(" ")[0] : ""
    tmp_hash["format"] = the_format
    tmp_hash["pub_date"] = doc["pub_date_display"].present? ? doc["pub_date_display"] : ""
    tmp_hash["publisher"] = doc["publisher_display"].present? ? doc["publisher_display"] : ""
    tmp_hash["author"] = doc["author_display"].present? ? doc["author_display"] : ""
    tmp_hash["availability"] = doc["availability_json"].present? ? doc["availability_json"] : ""
    tmp_hash["locations"] = doc["availability_json"].present? ? process_locations(doc["availability_json"]) : []
    tmp_hash["citation"] = doc["cite_preescaped_display"].present? ? doc["cite_preescaped_display"] : ""
    tmp_hash["callnumber"] = doc["callnum_display"].present? ? doc["callnum_display"] : ""
    # the difference between these next two: "internal_class_label" gets used in the data attribute
    # of some elements, while the "display_class_label" gets displayed in the UI and has the added
    # font awesomne html
    classification = doc["classification_display"].present? ? doc["classification_display"] : ""
    tmp_hash["internal_class_label"] = build_class_label(classification)
    tmp_hash["display_class_label"] = tmp_hash["internal_class_label"].gsub(' : ','<i class="fa fa-caret-right class-caret"></i>').html_safe
    # tmp_hash["img_url"] = get_googlebooks_image(oclc_isbn[0], oclc_isbn[1], the_format)
    tmp_hash["img_url"] = get_googlebooks_image(oclc_id, isbn, the_format)

    return tmp_hash
  end

  # Returns a string using the availability information
  def process_availability(avail_json)
    browseable_libraries = ENV['BROWSEABLE_LIBRARIES'] || ""
    availability = JSON.parse(avail_json)
    return "Online" if availability["online"].present?
    #return "Available" if availability["availAt"].present?
    #return "Not Available" if availability["unavailAt"].present?
    # Temporary for covid-19: don't show the availability for non-online items. Since the call number index
    # doesn't include holding info, we can't determine the actual availability.
    return "" if availability["availAt"].present? || availability["unavailAt"].present?
  end

  # Builds an array of the availability information
  def process_locations(avail_json)
    availability = JSON.parse(avail_json)
    tmp_array = []
    if availability["online"].present? && availability["online"]
      tmp_array << "Online"
    end
    if availability["availAt"].present?
      availability["availAt"].each do |k, v|
        if k.include?("(")
          i = k.index("(")
          tmp_str = k[0..i - 2]
          tmp_array << tmp_str
        else
          tmp_array << k
        end
      end
    end

    return tmp_array
  end

  def build_class_label(classlabel)
    final_array = []
    if classlabel == ""
      return ""
    end
    tmp_array = classlabel.split(">")
    count = 0
    add = true
    skipped_first = false
    tmp_array.delete_if do |t|
      count += 1
      if count == 1 and tmp_array[1].present? and tmp_array[1].downcase.include?(t[4..-1].downcase)
        add = false
        skipped_first = true
      end
      add = false if count == 2 and tmp_array[0].downcase.include?(t[t.index(" - ")+2..-1].downcase) and skipped_first == false
      #add = false if count == 3 and t.include?(tmp_array[2][tmp_array[2].index(" - ")+2..-1])
      #add = false if t.include?("(General)") && count != tmp_array.size
      add = false if t.include?("By region:")
      add = false if t.include?("By period:")
      final_array << t if add == true
      add = true
    end
    return final_array.join(" : ")
  end

  # /get_previous
  def previous_callnumber
    start = (params["start"].to_i * 8)
    location = ""
    location = params["fq"] if params["fq"].present?
    @previous_doc =  get_surrounding_docs(params["callnum"],"reverse",start,8,location)
    respond_to do |format|
      format.js
    end
  end

  # /get_next
  def next_callnumber
    start = (params["start"].to_i * 8) + 1
    location = ""
    location = params["fq"] if params["fq"].present?
    @next_doc =  get_surrounding_docs(params["callnum"],"forward",start,8,location)
    respond_to do |format|
      format.js
    end
  end

  # /get_carousel
  def build_carousel
    @callnumber = params["callnum"]
    previous_eight = get_surrounding_docs(params["callnum"],"reverse",0,8)
    next_eight = get_surrounding_docs(params["callnum"],"forward",0,9)
    @new_carousel = previous_eight.reverse() + next_eight
    respond_to do |format|
      format.js
    end
  end

  def callnumber_cleanup(callnumber)
    callnumber.gsub("Oversize ","").gsub("Rare Books ","").gsub("ONLINE ","").gsub("Human Sexuality ","").gsub("Ellis ","").gsub("New & Noteworthy Books ","").gsub("A.D. White Oversize ","").sub("+ ","")
  end

  def get_googlebooks_image(oclc, isbn, format)
    uri = URI("https://books.google.com/books")
    if oclc.present? and !oclc.include?("not found")
      params = { :bibkeys => "OCLC:#{oclc}", :jscmd => "viewapi", "callback" => "?"}
      uri.query = URI.encode_www_form(params)
      result = Net::HTTP.get(uri)
      result = eval(result.gsub("var _GBSBookInfo = ",""))
      if result.present? && result.values[0].present? && result.values[0][:thumbnail_url].present?
        return result.values[0][:thumbnail_url]
      end
    end
    if isbn.present? and !isbn.include?("not found")
      params = { :bibkeys => "OCLC:#{isbn}", :jscmd => "viewapi", "callback" => "?"}
      uri.query = URI.encode_www_form(params)
      result = Net::HTTP.get(uri)
      result = eval(result.gsub("var _GBSBookInfo = ",""))
      if result.present? && result.values[0].present? && result.values[0][:thumbnail_url].present?
        return result.values[0][:thumbnail_url]
      end
    end
    return set_cover_image(format)
  end

  # When there's no image from google books
  def set_cover_image(format)
    case format
    when "Book"
      return "cornell/virtual-browse/book_cvr.png"
    when "Journal/Periodical"
      return "cornell/virtual-browse/journal_cvr.png"
    when "Manuscript/Archive"
      return "cornell/virtual-browse/manuscript_cvr.png"
    when "Map"
      return "cornell/virtual-browse/map_cvr.png"
    when "Musical Recording"
      return "cornell/virtual-browse/musical_recording_cvr.png"
    when "Musical Score"
      return "cornell/virtual-browse/musical_score_cvr.png"
    when "Non-musical Recording"
      return "cornell/virtual-browse/non_musical_cvr.png"
    when "Thesis"
      return "cornell/virtual-browse/thesis_cvr.png"
    when "Video"
      return "cornell/virtual-browse/video_cvr.png"
    when "Microform"
      return "cornell/virtual-browse/microform_cvr.png"
    else
      return "cornell/virtual-browse/generic_cvr.png"
    end

  end

end
