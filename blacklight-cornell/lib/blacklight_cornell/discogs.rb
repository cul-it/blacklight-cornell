#encoding: UTF-8
require_relative "../../app/helpers/logging_helper"

module BlacklightCornell::Discogs extend Blacklight::Catalog
  include LoggingHelper
  def get_discogs
  id = params[:id] if params[:id].present?
  @discogs_data = make_discogs_show_call(id) if id.present? && !id.empty?
  unless @discogs_data.nil?
    build_discogs_components
    respond_to do |format|
      format.js { render layout: false }
    end
  end
end

  def process_discogs(doc)
    fields = {}
    fields["title_responsibility"] = doc["title_responsibility_display"].present? ? doc["title_responsibility_display"][0] : ""
    fields["title"] = doc["title_display"].present? ? doc["title_display"] : ""
    fields["subtitle"] = doc["subtitle_display"].present? ? doc["subtitle_display"] : ""
    fields["pub_date"] = doc["pub_date_facet"].present? ? doc["pub_date_facet"].to_s : ""
    fields["publisher"] = doc["publisher_display"].present? ? doc["publisher_display"][0] : ""
    fields["publisher_number"] = doc["publisher_number_display"].present? ? doc["publisher_number_display"][0] : ""
    # parse author_json to handle cases where there are multiple versions of the author's name 
    single_author = false
    author_json_parsed = doc["author_json"].present? ? JSON.parse(doc["author_json"][0]) : ""
    author = author_json_parsed["search1"].present? ? author_json_parsed["search1"] : ""
    fields["author"] = author_cleanup(author)
    fields["single_author"] = single_author
    # discogs queries must include a title and author/responsibility info to avoid mismatches
    if fields["title"].present? && (fields["author"].present? || fields["title_responsibility"].present?)
      query_string = build_discogs_query_string(fields)
      search_result = make_discogs_search_call(query_string)
  if (!search_result.nil? && !search_result.empty?) && (!search_result["results"].nil? && !search_result["results"].empty?)
        @discogs_image_url = search_result["results"][0]["cover_image"].present? ? search_result["results"][0]["cover_image"] : ""
        @discogs_id = search_result["results"][0]["id"].present? ? search_result["results"][0]["id"].to_s : ""
      end
    end
  end

  def build_discogs_components
  # check present? or empty? for these
  @author_addl = process_discogs_contributors(@discogs_data["extraartists"]) if @discogs_data["extraartists"].present? && @discogs_data["extraartists"].size > 0
  @notes = process_discogs_notes(@discogs_data["notes"]) if @discogs_data["notes"].present? && @discogs_data["notes"].length > 0
  @contents = process_discogs_contents(@discogs_data["tracklist"]) if @discogs_data["tracklist"].present? && @discogs_data["tracklist"].length > 0
  @pub_info = process_discogs_published(@discogs_data)
  genres = @discogs_data["genres"].present? ? @discogs_data["genres"] : []
  styles = @discogs_data["styles"].present? ? @discogs_data["styles"] : []
  @genres = process_discogs_genres(genres, styles) if !genres.empty? || !styles.empty?
end
  def get_discogs_image(id)
  data = make_discogs_show_call(id)
  image_url = data["images"].present? ? data["images"][0]["resource_url"] : ""
  return image_url
end
  def author_cleanup(author)
  if author.length > 0 && (author[-1] == "-" || author[-6] == "-")
    x = author.rindex(",")
    author = author[0..x - 1]
    single_author = true
    # or if we only have one author but no date range
  elsif author.length > 0 && (author.scan(",").length == 1 && author[-1] == ".")
    author = author.gsub(/.\s*$/, "")
    single_author = true
  else
    # removes closing period
    author = author.gsub(/\.$/, "")
  end
  if author[-1] == ")"
    y = author.rindex("(")
    author = author[0..y - 1]
  end
  return author
end
  def process_discogs_published(discogs)
  country = discogs["country"].present? ? discogs["country"] : ""
  year = discogs["year"].present? ? discogs["year"].to_s : ""
  labels = discogs["labels"].present? ? discogs["labels"] : []
  results = []
  tmp_string = ""
  if !country.empty?
    tmp_string += country + " : "
  end
  if !labels.empty?
    prev_label = ""
    labels.each do |l|
      if l["name"] != prev_label
        tmp_string += l["name"] + ", "
        prev_label = l["name"]
      end
    end
  end
  if !year.empty?
    tmp_string += year + "."
  else
    tmp_string = tmp_string.sub(/.*\K,/, ".")
  end
  return results << tmp_string
end
  def process_discogs_contents(contents)
  results = []
  contents.each do |c|
    duration = c["duration"].present? ? " (" + c["duration"] + ")" : ""
    tmp_string = "" + c["title"] + duration
    results << tmp_string
  end
  return results
end
  def process_discogs_contributors(artists)
  combined = artists.group_by { |h1| h1["name"] }.map do |k, v|
    { "name" => k, "contributions" => v.map { |h2| h2["role"] }.join(", ") }
  end
  results = []
  combined.each do |a|
    tmp_string = a["name"] + ": " + a["contributions"].gsub("Composed By", "composer") + "."
    results << tmp_string
  end
  return results
end
  def process_discogs_notes(notes)
  tmp_string = notes.gsub("\r", "").gsub("\n\n", "@@").gsub("\n", "")
  return tmp_string.split("@@")
end
  def process_discogs_genres(genres, styles)
  genres_array = []
  genres.each do |g|
    genres_array << g
  end
  styles.each do |s|
    genres_array << s
  end
  return genres_array
end
  def build_discogs_query_string(fields)
  # fields = [title_resp, title, subtitle, pub_date, publisher, publisher_nbr, author, single_author]
  author = fields["author"]
  if author.length > 0
    # if the author name is in the title, we only need the latter but only in the case of a single author
    # reverse last name, first name Mingus, Charles
    if fields["single_author"]
      first_last = author[author.index(", ") + 2..-1] + " " + author[0..author.index(",") - 1]
      if !fields["title"].include?(first_last) && !fields["subtitle"].include?(first_last)
        query_string = first_last + "+" + fields["title"]
      else
        query_string = fields["title"]
      end
    elsif !fields["title"].include?(author)
      query_string = author + "+" + fields["title"]
    else
      query_string = fields["title"]
    end
  else
    query_string = fields["title_responsibility"] + "+" + fields["title"]
  end
  if fields["subtitle"].length > 0
    query_string += "+" + fields["subtitle"]
  end

  if fields["publisher_number"].length > 0
    query_string += "+" + fields["publisher_number"]
  else
    query_string += "+" + fields["publisher"].gsub(",", "").gsub(":", "") + "+" + fields["pub_date"]
  end
  query_string = query_string.gsub(" ", "+").gsub("&", "and").gsub("++", "+")

  return query_string
end
  def make_discogs_search_call(query_string)
  key = ENV["DISCOGS_KEY"].present? ? ENV["DISCOGS_KEY"] : ""
  secret = ENV["DISCOGS_SECRET"].present? ? ENV["DISCOGS_SECRET"] : ""
  uri = URI("https://api.discogs.com/database/search")
  params = { q: query_string, type: "release", key: key, secret: secret }
  uri.query = URI.encode_www_form(params)
  resp = Net::HTTP.get_response(uri)
  data = resp.body
  result = JSON.parse(data)
  return result if resp.kind_of? Net::HTTPSuccess
  log_debug_info("#{__FILE__}:#{__LINE__}",
                 "case: Not Net::HTTPSuccess",
                 ["query_string:", query_string],
                 ["params:", params],
                 ["result:", result])

  return [] if resp.kind_of? Net::HTTPError
rescue StandardError
  log_debug_info("#{__FILE__}:#{__LINE__}",
                 "case: StandardError",
                 ["query_string:", query_string],
                 ["params:", params],
                 ["result:", result])

  return []
end
  def make_discogs_show_call(id)
  key = ENV["DISCOGS_KEY"].present? ? ENV["DISCOGS_KEY"] : ""
  secret = ENV["DISCOGS_SECRET"].present? ? ENV["DISCOGS_SECRET"] : ""
  uri = URI("https://api.discogs.com/releases/" + id)
  params = { key: key, secret: secret }
  uri.query = URI.encode_www_form(params)
  resp = Net::HTTP.get_response(uri)
  data = resp.body
  result = JSON.parse(data)
  return result if resp.kind_of? Net::HTTPSuccess
  log_debug_info("#{__FILE__}:#{__LINE__}",
                 "case: Not Net::HTTPSuccess",
                 ["params:", params],
                 ["result:", result])
  return {} if resp.kind_of? Net::HTTPError
rescue StandardError
  log_debug_info("#{__FILE__}:#{__LINE__}",
                 "case: StandardError",
                 ["params:", params],
                 ["result:", result])
  return {}
end
  def deep_clone(object)
  return @deep_cloning_obj if @deep_cloning
  @deep_cloning_obj = object.clone
  @deep_cloning_obj.instance_variables.each do |var|
    val = @deep_cloning_obj.instance_variable_get(var)
    begin
      @deep_cloning = true
      val = val.deep_copy
    rescue TypeError
      next
    ensure
      @deep_cloning = false
    end
    @deep_cloning_obj.instance_variable_set(var, val)
  end
  deep_cloning_obj = @deep_cloning_obj
  @deep_cloning_obj = nil
  deep_cloning_obj
end end
