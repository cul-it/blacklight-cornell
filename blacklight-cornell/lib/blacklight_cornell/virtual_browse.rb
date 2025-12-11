#encoding: UTF-8
module BlacklightCornell::VirtualBrowse extend Blacklight::Catalog
  include Browse

  # gets the documents on either "side" of the selected one. Direction determines whether
  # to get the previous or next group of docs.
  def get_surrounding_docs(callnumber,direction,start,rows, location="")
    return nil if callnumber.nil?

    @location = location.gsub('&','%26')
    callno = callnumber.gsub('\\', ' ').gsub('"',' ')

    solr_response_full = browse_solr(query: callno,
                                     order: direction,
                                     start: start,
                                     rows: rows,
                                     fq: location,
                                     browse_type: 'Call-Number')
    @browse_locations = call_number_locations
    solr_response_full['response']['docs'].map do |doc|
      get_document_details(doc)
    end
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
    # font awesome html
    classification = doc["classification_display"].present? ? doc["classification_display"] : ""
    tmp_hash["internal_class_label"] = build_class_label(classification)
    tmp_hash["display_class_label"] = tmp_hash["internal_class_label"].gsub(' : ','<i class="fa fa-caret-right class-caret"></i>').html_safe
    # tmp_hash["img_url"] = get_googlebooks_image(oclc_isbn[0], oclc_isbn[1], the_format)
    if doc["no_google_img_b"].present?
      tmp_hash["img_url"] = set_cover_image(the_format)
    else
      tmp_hash["img_url"] = get_googlebooks_image(oclc_id, isbn, the_format)
    end

    tmp_hash
  end

  # Returns a string using the availability information
  def process_availability(avail_json)
    # browseable_libraries = ENV['BROWSEABLE_LIBRARIES'] || ""
    availability = JSON.parse(avail_json)
    return "Online" if availability["online"].present?
    #return "Available" if availability["availAt"].present?
    #return "Not Available" if availability["unavailAt"].present?
    # Temporary for covid-19: don't show the availability for non-online items. Since the call number index
    # doesn't include holding info, we can't determine the actual availability.
    "" if availability["availAt"].present? || availability["unavailAt"].present?
  end

  # Builds an array of the availability information
  def process_locations(avail_json)
    availability = JSON.parse(avail_json)
    tmp_array = []
    if availability["online"].present? && availability["online"]
      tmp_array << "Online"
    end
    if availability["availAt"].present?
      availability["availAt"].each do |k, _|
        if k.include?("(")
          i = k.index("(")
          tmp_str = k[0..i - 2]
          tmp_array << tmp_str
        else
          tmp_array << k
        end
      end
    end

    tmp_array
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
      add = false if count == 2 and tmp_array[0].downcase.include?(t[t.index(" - ")+2..-1].downcase) and !skipped_first
      #add = false if count == 3 and t.include?(tmp_array[2][tmp_array[2].index(" - ")+2..-1])
      #add = false if t.include?("(General)") && count != tmp_array.size
      add = false if t.include?("By region:")
      add = false if t.include?("By period:")
      final_array << t if add
      add = true
    end
    final_array.join(" : ")
  end

  # /get_previous
  def previous_callnumber
    params.require([:callnum, :start])  # sometimes bots are calling this without required parameters - 400
    start = (params["start"].to_i * 8)
    location = ""
    location = params["fq"] if params["fq"].present?
    @previous_doc =  get_surrounding_docs(params["callnum"],"reverse",start,8,location)
    unless @previous_doc.nil?
      respond_to do |format|
        format.js
      end
    end
  end

  # /get_next
  def next_callnumber
    params.require([:callnum, :start])  # sometimes bots are calling this without required parameters - 400
    start = (params["start"].to_i * 8) + 1
    location = ""
    location = params["fq"] if params["fq"].present?
    @next_doc =  get_surrounding_docs(params["callnum"],"forward",start,8,location)
    unless @next_doc.nil?
      respond_to do |format|
        format.js
      end
    end
  end

  # /get_carousel
  def build_carousel
    params.require(:callnum) # sometimes bots are calling this without required parameters - 400
    @callnumber = params["callnum"]
    previous_eight = get_surrounding_docs(params["callnum"],"reverse",0,8)
    next_eight = get_surrounding_docs(params["callnum"],"forward",0,9)
    unless previous_eight.nil? && next_eight.nil?
      if previous_eight.nil?
        @new_carousel = next_eight
      elsif next_eight.nil?
        @new_carousel = previous_eight.reverse
      else
        @new_carousel = previous_eight.reverse + next_eight
      end
      respond_to do |format|
        format.js
      end
    end
  end

  def callnumber_cleanup(callnumber)
    callnumber.gsub("Oversize ","").gsub("Rare Books ","").gsub("ONLINE ","").gsub("Human Sexuality ","").gsub("Ellis ","").gsub("New & Noteworthy Books ","").gsub("A.D. White Oversize ","").sub("+ ","")
  end

def get_googlebooks_image(oclc, isbn, format)
  # use oclc if present, otherwise use isbn
  book_id = "OCLC:#{oclc}" if oclc.present? && !oclc.include?("not found")
  # note: this can be an ISBN 10 or 13
  book_id = "ISBN:#{isbn}" if book_id.nil? && isbn.present? && !isbn.include?("not found")
  unless book_id.nil?
    params = { :bibkeys => book_id, :jscmd => "viewapi", "callback" => "?"}
    uri = URI("https://books.google.com/books")
    uri.query = URI.encode_www_form(params)
    response = Net::HTTP.get_response(uri)
    # sometimes googlebooks returns a 502 bad gateway, so we need to check for that
    if response.kind_of? Net::HTTPSuccess
      # extract the json payload from the jsonp response (outermost brackets):
      #
      # var _GBSBookInfo = {"ISBN:9780387978444":{"bib_key":"ISBN:9780387978444",
      # "info_url":"https://books.google.com/books?id=dqNFAQAAIAAJ\u0026source=gbs_ViewAPI",
      # "preview_url":"https://books.google.com/books?id=dqNFAQAAIAAJ\u0026source=gbs_ViewAPI","
      # thumbnail_url":"https://books.google.com/books/content?id=dqNFAQAAIAAJ\u0026printsec=frontcover\u0026img=1\u0026zoom=5",
      # "preview":"noview", "embeddable":false, "can_download_pdf":false, "can_download_epub":false,
      # "is_pdf_drm_enabled":false, "is_epub_drm_enabled":false}};
      payload = response.body[/{.+}/]
      unless payload.nil?
        result = JSON.parse(payload)
        # if there's a thumbnail_url, return it
        if result.present? && result.values[0].present? && result.values[0]['thumbnail_url'].present?
          return result.values[0]['thumbnail_url']
        end
      end
    end
  end
  set_cover_image(format)
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
