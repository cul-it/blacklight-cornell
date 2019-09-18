module DisplayHelper
include ActionView::Helpers::NumberHelper

  def render_first_available_partial(partials, options)
    partials.each do |partial|
      begin
        return render(:partial => partial, :locals => options)
      rescue ActionView::MissingTemplate
        next
      end
    end

    raise "No partials found from #{partials.inspect}"
  end

  def field_value_separator
    '<br>'
  end


  def contents_list field
    content_tag(:ul) do
      field[:value].each do |v|
        concat content_tag(:li, v)
    end
  end
end

  # for display of | delimited fields
  # only displays the string before the first |
  # otherwise, it does same as render_index_field_value
  def render_delimited_index_field_value args

    # NOTE: this is only used for title_uniform_display at the moment, so
    # no need to check other things. Probably this should be rewritten as
    # a presenter method
    uniform_title = args[:document][:title_uniform_display]
    uniform_title ? uniform_title[0].split('|')[0] : ''
  #
  #   require 'pp'
  #   value = args[:value]
  #
  #   if args[:field] and blacklight_config.index_fields[args[:field]]
  #     field_config = blacklight_config.index_fields[args[:field]]
  #     value ||= send(blacklight_config.index_fields[args[:field]][:helper_method], args) if field_config.helper_method
  #     value ||= args[:document].highlight_field(args[:field]) if field_config.highlight
  #   end
  #
  # #  value ||= args[:document].fetch(args[:field], :sep => 'nil') if args[:document] and args[:field]
  #
  #   newval = nil
  #   unless value.nil?
  #     if value.class == Array
  #       newval = Array.new
  #       value.each do |v|
  #         newval.push (v.split('|'))[0] unless v.blank?
  #       end
  #     else
  #       ## string?
  #       newval = (value.split('|'))[0] unless value.blank?
  #     end
  #   end
  #
  #   dp = Blacklight::DocumentPresenter.new(nil, nil, nil)
  #   #Rails.logger.debug "\n*************es287_debug self = #{__FILE__} #{__LINE__}  #{self.pretty_inspect}\n"
  #   #Rails.logger.debug "\n*************es287_debug blacklight_config = #{__FILE__} #{__LINE__}  #{blacklight_config.pretty_inspect}\n"
  #   #Rails.logger.debug "\n*************es287_debug args =#{__FILE__} #{__LINE__}  #{args.pretty_inspect}\n"
  #   fp = Blacklight::FieldPresenter.new( self, args[:document], blacklight_config.show_fields[args[:field]], :value => newval)
  #   #Rails.logger.debug "\n*************es287_debug fp = #{__FILE__} #{__LINE__}  #{fp.pretty_inspect}\n"
  #   #dp.render_field_value newval
  #   fp.render
  end

  # for display of | delimited fields
  # only displays the string before the first |
  # otherwise, it does same as render_index_field_value
  def render_pair_delimited_index_field_value args
    Rails.logger.info("RENDER_PAIR_...")
    value = args[:value]

    if args[:field] and blacklight_config.index_fields[args[:field]]
      field_config = blacklight_config.index_fields[args[:field]]
      value ||= send(blacklight_config.index_fields[args[:field]][:helper_method], args) if field_config.helper_method
      value ||= args[:document].highlight_field(args[:field]) if field_config.highlight
    end

    value ||= args[:document].fetch(args[:field], :sep => nil) if args[:document] and args[:field]

    newval = nil
    unless value.nil?
      value_array = value.split('|')
      vals = []
      i = 0
      value_array.each do |v|
        vals.push v if i % 2 == 0
        i = i + 1
      end
      newval = vals.join(' / ')
    end

    dp = Blacklight::DocumentPresenter.new(nil, nil, nil)
    dp.render_field_value newval
  end

  # :format arg specifies what should be returned
  # * the raw array (url_access_display in availability on item page)
  # * url only (search results)
  # * link_to's with trailing <br>'s -- the default -- (url_other_display &
  # url_toc_display in field listing on item page)

  def render_display_link args
    label = blacklight_config.display_link[args[:field]][:label]
    links = args[:value]
    #Rails.logger.debug("es287_debug #{__FILE__}:#{__LINE__} links =  #{links.inspect}")
    links ||= args[:document].fetch(args[:field], :sep => nil) if args[:document] and args[:field]
    #Rails.logger.debug("es287_debug #{__FILE__}:#{__LINE__} links =  #{links.inspect}")
    render_format = args[:format] ? args[:format] : 'default'

    value = links.map do |link|
      #Check to see whether there is metadata at the end of the link
      url, *metadata = link.split('|')
      if links.size == 1 && render_format == 'url'
        return url.html_safe
      end
      if metadata.present?
        label = metadata[0]
      end
      link_to(process_online_title(label), url.html_safe, {:class => 'online-access', :onclick => "javascript:_paq.push(['trackEvent', 'itemView', 'outlink']);"})
    end

    #Rails.logger.debug("es287_debug #{__FILE__}:#{__LINE__} field =  #{args[:field].inspect}")
    #Rails.logger.debug("es287_debug #{__FILE__}:#{__LINE__} render_format =  #{render_format.inspect}")
    #Rails.logger.debug("es287_debug #{__FILE__}:#{__LINE__} value =  #{value.inspect}")
    if render_format == 'raw'
      return value
    else
      fp = Blacklight::FieldPresenter.new( self, args[:document], blacklight_config.show_fields[args[:field]], :value => label)
      #dp.render_field_value value
      case  args[:field]
        when'url_findingaid_display'
          return value[0]
        when 'url_bookplate_display'
          Rails.logger.debug("es287_debug #{__FILE__}:#{__LINE__} field =  #{args[:field].inspect}")
          return value.uniq.join(',').html_safe
        when 'url_other_display'
          return value.join('<br>').html_safe
        else
          fp.render
        end
    end
  end

  # Build a link to the CUL libraryhours page for the library location in question
  def render_location_link location_code
    loc_url = Location::help_page(location_code)
    link_to('Hours/Map', loc_url, {:title => 'See hours and map'})
  end

  def yy_render_location_link location_code
    base_url = 'https://www.library.cornell.edu/libraries/'
    matched_location = nil
    # Test for substring match of location hash key in location_code
    LOCATION_MAPPINGS.each do |key, value|
      if location_code.include?(key)
        matched_location = value
        break # Break on first match to ensure RMC (followed by Annex) is properly identified
      end
    end
    #location_url = matched_location.present? ? base_url + matched_location : base_url
    location_url =
     case
       when matched_location.present? && matched_location.include?('http:')
         matched_location
       when matched_location.present? && !matched_location.include?('http:')
         base_url + matched_location
       else
         base_url
     end
    link_to('Hours/Map', location_url, {:title => 'See hours and map'})
  end

  def render_special_location_link location_code
    base_url = 'https://www.library.cornell.edu/libraries/'
    matched_location = nil
    # Test for substring match of location hash key in location_code
    LOCATION_MAPPINGS.each do |key, value|
      if location_code.include?(key)
        matched_location = value
        break # Break on first match to ensure RMC (followed by Annex) is properly identified
      end
    end

    location_url = matched_location.present? ? matched_location : base_url

    link_to('Info', location_url, {:title => 'See hours and map'})
  end

 def oclc_number_link
    presenter = Blacklight::ShowPresenter.new(@document, self)
    id_display = presenter.field_value 'other_id_display'
    if id_display.present?
      if id_display.start_with? "(OCoLC)"
        oclc_number = id_display.split(",")[0]
      elsif id_display.include? "(OCoLC)"
        ids = id_display.split(", ")
          ids.each do |id|
            if id.start_with? "(OCoLC)"
              oclc_number = id.split("<")[0]
            end
          end
        end
      end

      if !oclc_number.present?
        wcl_isbn = presenter.field_value 'isbn_display'
        if wcl_isbn.include? ("<")
          wcl_isbn = wcl_isbn.split("<")[0]
        end
        if wcl_isbn.include? (' ')
          wcl_isbn = wcl_isbn.split(" ")[0]
        end
      end

      if wcl_isbn.present? && !oclc_number.present?
        @xisbn = HTTPClient.get_content("http://xisbn.worldcat.org/webservices/xid/isbn/#{wcl_isbn}?method=getMetadata&format=json&fl=oclcnum&")
        @xisbn = JSON.parse(@xisbn)["list"]
        if @xisbn.present? && @xisbn.include?("oclcnum")
        @xisbn.each do |wcl_data|
          oclc_number = wcl_data["oclcnum"][0]
        end
        end
    end
    return oclc_number
  end

  # Hash map for substring of location codes from holding service => loc param
  # values for CUL library hours page
  # Built using lists from:
  # -- https://issues.library.cornell.edu/browse/DISCOVERYACCESS-306 (location codes)
  # -- https://issues.library.cornell.edu/browse/DISCOVERYACCESS-408 (site param values)
  LOCATION_MAPPINGS = {
    'rmc' => 'rmc',
    'anx' => 'annex',
    'afr' => 'africana',
    'engr' => 'engineering',
    'olin' => 'olin',
    'gnva' => 'geneva',
    'ilr' => 'ilr',
    'fine' => 'finearts',
    'hote' => 'hotel',
    'asia' => 'asia',
    'was' => 'asia',
    'ech' => 'asia',
    'law' => 'law',
    'jgsm' => 'jgsm',
    'mann' => 'mann',
    'math' => 'math',
    'Spacecraft Planetary Imaging Facility 317 Space Science Bldg' => "http://spif.astro.cornell.edu/index.php?option=com_content&view=article&id=9&Itemid=9",
    'Spacecraft Planetary Imaging Facility (Non-Circulating)' => "http://spif.astro.cornell.edu/index.php?option=com_content&view=article&id=9&Itemid=9",
    'phys' => "http://spif.astro.cornell.edu/index.php?option=com_content&view=article&id=9&Itemid=9",
    'uris' => 'uris',
    'vet' => 'vet',
    'orni' => 'ornithology',
    'mus' => 'music'
  }

  def render_clickable_document_show_field_value args
    dp = Blacklight::DocumentPresenter.new()
    value = args[:value]
    value ||= args[:document].fetch(args[:field], :sep => nil) if args[:document] and args[:field]
    args[:sep] ||= blacklight_config.multiline_display_fields[args[:field]] || field_value_separator;

    value = [value] unless value.is_a? Array
    value = value.collect { |x| x.respond_to?(:force_encoding) ? x.force_encoding("UTF-8") : x }
    return value.map { |v| render_clickable_item(args, v) }.join(args[:sep]).html_safe
  end

  def render_clickable_item args, value
   # if args[:field] == 'title_series_display'
   #   args[:field] = "title_series_cts"
   #   value = args[:document][:title_series_cts]
   # end
    clickable_setting = blacklight_config.display_clickable[args[:field]]
    case clickable_setting
    when String
      # default single value
      link_to(value, add_search_params(args[:field], '"' + value + '"'))
    when Hash
      # delimited value to be separated out further
      if clickable_setting[:sep] != nil
        # separator defined
        value_array = value.split(clickable_setting[:sep])
        sep_display = clickable_setting[:sep_display] || clickable_setting[:sep] # separator for display field as defined
        sep_index = clickable_setting[:sep_index] || clickable_setting[:sep] #separator for search string as defined
        if clickable_setting[:key_value]
          # field has display value and search value separated by :sep
          displayv_searchv = value.split(clickable_setting[:sep])
          if displayv_searchv.size > 2
            # has optional link attributes
            # e.g. uniform title is searched in conjunction with author for more targeted results
            if !clickable_setting[:related_search_field].blank?
              link_to(displayv_searchv[0], add_advanced_search_params(args[:field], displayv_searchv[1], clickable_setting[:related_search_field], displayv_searchv[2]))
            else
              # misconfiguration... no related search field defined
              # ignore related search value
              link_to(displayv_searchv[0], add_search_params(args[:field], '"' + displayv_searchv[1] + '"'))
            end
          elsif displayv_searchv.size > 1
            # default key value pair separated by :sep
            link_to(displayv_searchv[0], add_search_params(args[:field], '"' + displayv_searchv[1] + '"'))
          else
            # display only
            content_tag('span', displayv_searchv[0])
          end
        elsif clickable_setting[:hierarchical]

          # fields such as subject are hierarchical
          hierarchical_value = ''
          value_array.map do |v|
            if !hierarchical_value.empty?
              hierarchical_value += sep_index + v
            else
              hierarchical_value += v
            end
            link_to(v, add_search_params(args[:field], '"' + hierarchical_value + '"'), class: "hierarchical")
          end.join(sep_display).html_safe

        elsif clickable_setting[:json]
          display_subject_headings(value, sep_index, sep_display, args)

        elsif clickable_setting[:pair_list]
          ## fields such as title are hierarchical
          ## e.g. display value 1 | search value 1 | display value 2 | search value 2 ...
          # debugger
          if  value_array.size() > 1
            # i = 0
            # value_array.map do |v|
              # link_to(v, add_search_params(args[:field], '"' + v + '"'))
            # end.join(sep_display).html_safe
            i = 0
            display_list = []
            while i < value_array.size()
              display_list.push link_to(value_array[i], add_search_params(args[:field], '"' + Maybe(value_array[i+1]).to_s + '"'))
              i = i + 2
            end
            display_list.join(sep_display).html_safe
          else
            value_array.map do |v|
              link_to(v, add_search_params(args[:field], '"' + v + '"'))
            end.join(sep_display).html_safe
          end

        elsif clickable_setting[:pair_list_json]
          ## fields such as title are hierarchical
          ## e.g. display value 1 | search value 1 | display value 2 | search value 2 ...
          # debugger
          authors = JSON.parse(value)
          value_array = []
          if authors["name1"] && authors["search1"]
            value_array <<  authors["name1"]
            value_array << authors["search1"]
          end
          if authors["name2"] && authors["search2"]
            value_array << authors["name2"]
            value_array << authors["search2"]
          end

          if  value_array.size() > 1
            # i = 0
            # value_array.map do |v|
              # link_to(v, add_search_params(args[:field], '"' + v + '"'))
            # end.join(sep_display).html_safe
            i = 0
            display_list = []
            while i < value_array.size()
              display_list.push link_to(value_array[i], add_search_params(args[:field], '"' + Maybe(value_array[i+1]).to_s + '"'))
              i = i + 2
            end
            display_list.join(sep_display).html_safe

          else
            value_array.map do |v|
              link_to(v, add_search_params(args[:field], '"' + v + '"'))
            end.join(sep_display).html_safe
          end

        else
          # default behavior to search the text displayed
          value_array.map do |v|
            link_to(v, add_search_params(args[:field], '"' + v + '"'))
          end.join(sep_display).html_safe
        end
      else
        # separator not defined... use default behavior
        link_to(value, add_search_params(args[:field], '"' + value + '"'))
      end
    else
      # what other form of input to handle?
    end
  end

  ## Hierarchical rendition of subject headings with info box button next to them
  def display_subject_headings(value, sep_index, sep_display, args)
    field = args[:field]
    root_url = args[:root_url]
    json_value=''
    subject = JSON.parse(value)
    style_text = ""
    indent = 0
    type = ""
    subject.map do |sub|
    v = sub["subject"]
      if !json_value.empty?
        indent += 10
        style_text = "margin-left:" + indent.to_s + "px;"
        json_value += sep_index + v
        #type = "Topical Term"
        #What particular type will work in library seems up in the air, so leave empty and get all content ack
        type = ""
      else
        type = sub["type"]
        json_value += v
      end
      info_button = ""
      if sub.key?("authorized") && sub["authorized"] == true
        headingtype = ""
        if !type.empty?
          headingtype = '&amp;headingtype=' + type
        end
        info_button = '<a href="#" role="button" tabindex = "0" base-url="' + request.base_url + 
        '" data-auth-type="subject" heading-type="' + type + '" data-auth="' + json_value + '" datasearch-poload="/browse/info?authq=' + 
        json_value + '&amp;browse_type=Subject' + headingtype + '" id="info" class="info-button hidden-xs"><span class="badge badge-primary">' + 
    'i</span></a>'
      end
      
      "<div style='" + style_text + "'>" + link_to(v, add_search_params(field, '"' + json_value + '"'), class: "hierarchical") + "&nbsp;" + info_button + "</div>"
     end.join(" ").html_safe
  end

  def add_search_params(field, value)
    new_search_params = {
      #:utf8 => '✓',
      :controller => 'catalog',
      :q => value,
      :search_field => get_clickable_search_field(field),
      :click_to_search => true,
      :commit => 'search',
      :action => 'index'
    }
  end

  def add_advanced_search_params(primary_field, pval, related_search_field, rval)
    op = 'op[]'
    q_row = 'q_row'
    op_row = 'op_row'
    search_field_row = 'search_field_row'
    pf = get_clickable_search_field(primary_field)
    rf = get_clickable_search_field(related_search_field)
    rf = related_search_field if rf.nil?
    boolean_row = 'boolean_row[1]'

    new_search_params = {
      #:utf8 => '✓',
      # :utf8 => '%E2%9C%93',
      q_row.to_sym => [pval, rval],
      op_row.to_sym => ['phrase', 'phrase'],
      search_field_row.to_sym => [pf, rf],
      boolean_row.to_sym => 'AND',
      :sort => 'score desc, pub_date_sort desc, title_sort asc',
      :search_field => 'advanced',
      :commit => 'Search',
      :action => 'index'
    }
  end

  def get_clickable_search_field field
    clickable_setting = get_clickable_setting field
    case clickable_setting
    when String
      # default single value
      return clickable_setting
    when Hash
      # delimited value to be separated out further
      return clickable_setting[:search_field]
    end
  end

  def get_clickable_setting field
    return blacklight_config.display_clickable[field]
  end

  def display_icon?(field)
    return blacklight_config.display_icon[field] != nil
  end

  def display_clickable?(field)
    return get_clickable_setting(field) != nil
  end

  def render_single_value(args)
    if args[:value].is_a?(Array)
      return args[:value][0]
    else
      return args[:value]
    end
  end

  def display_link?(field)
    return blacklight_config.display_link[field] != nil
  end

  def is_online? document
   Rails.logger.debug("es287_debug @@@@ #{__FILE__}:#{__LINE__} url =  #{document['url_access_display'].inspect}")
    ( document['url_access_display'].present?  && document['url_access_display'].size > 0) ?
        true
      :
        false
  end
  def is_at_the_library? document
    ( document['online'].present?  && document['online'].include?('At the Library')) ?
        true
      :
        false
  end
  def online_url(document)
    if document['url_access_display'].present?
      if document['url_access_display'].size > 1
        solr_document_path(document)
      else
        render_display_link(:document => document, :field => 'url_access_display', :format => 'url')
      end
    end
  end

  def finding_aid(document)
    if document['url_findingaid_display'].present?
      if document['url_findingaid_display'].size > 1
        facet_catalog_path(document)
      else
        render_display_link(:document => document, :field => 'url_findingaid_display', :format => 'url')
      end
    end
  end

  def other_availability(document)
    if document['other_availability_piped'].present?
      if document['other_availability_piped'].size > 1
        facet_catalog_path(document)
      else
        render_display_link(:document => document, :field => 'other_availability_piped', :format => 'url')
      end
    end
  end

  FORMAT_MAPPINGS = {
    "Book" => "book",
    "Books" => 'book',
    "Computer File" => 'save',
    "Computer Files" => 'save',
    "Digital Collections" => "th-large",
    "Non-musical Recording" => "headphones",
    "Non-musical Recordings" => "headphones",
    "Musical Score" => "musical-score",
    "Musical Scores" => "musical-score",
    "Musical Recording" => "music",
    "Musical Recordings" => "music",
    "Thesis" => "file-text-o",
    "Theses" => "file-text-o",
    "Microform" => "film",
    "Journal/Periodical" => "book-open",
    "Journals/Periodicals" => "book-open",
    "Journal Articles" => "book-open",
    "Articles & Full Text" => "book-open",
    "Conference Proceedings" => "group",
    "Video" => "video-camera",
    "Videos" => "video-camera",
    "Map" => "globe",
    "Maps" => "globe",
    "Manuscript/Archive" => "archive",
    "Manuscripts / Archives" => "archive",
    "Newspaper" => "newspaper",
    "Newspaper Articles" => "newspaper",
    "Database" => "database",
    "Databases" => "database",
    "Image" => "picture-o",
    "Images" => "picture-o",
    "Unknown" => "question-sign",
    "Kit" => "suitcase",
    "Kits" => "suitcase",
    "Research Guide" => "paste",
    "Research Guides" => "paste",
    "Course Guide" => "graduation-cap",
    "Course Guides" => "graduation-cap",
    "Website" => "desktop",
    "Websites" => "desktop",
    "Library Websites" => "desktop",
    "Miscellaneous" => "ellipsis-h",
    "Object" => "trophy",
    "Objects" => "trophy"
  }

  def formats_icon_mapping(format)
    ic = 'default'
    f = format
    if (icon_mapping = FORMAT_MAPPINGS[f])
      ic = icon_mapping
    end
    ic
  end

  def hide_this_field field
    return false
  end

  def render_show_format_value field
    formats = []
    field[:value].map do |f|
    # Convert format to array in case it's a string (it shouldn't be)
        icon = '<i class="fa fa-' + formats_icon_mapping(f) + '"></i> '
        f.prepend(icon) unless f.nil?
        formats << f
      end
      formats.join('<br>').html_safe
  end

  # Renders the format field values with applicable format icons
  def render_format_value args
    format = args[:document][args[:field]]
    # Convert format to array in case it's a string (it shouldn't be)
    format = [format] unless format.is_a? Array
    format.map do |f|
      icon = '<i class="fa fa-' + formats_icon_mapping(f) + '"></i> '
      f.prepend(icon).html_safe unless f.nil?
    end
  end

  def render_documents(documents, options)
    partial = "/_display/#{options[:action]}/#{options[:view_style]}"
    render partial, { :documents => documents.listify}

  end

  def render_document_view(document, options = {})
    template = options.delete(:template) || raise("Must specify template")
    formats = determine_formats(document, options.delete(:format))

    partial_list = formats.collect { |format| "/_formats/#{format}/#{template}"}
    @add_row_style = options[:style]
    view = render_first_available_partial(partial_list, options.merge(:document => document))
    @add_row_style = nil

    return view
  end

  SOLR_FORMAT_LIST = {
    "Music - Recording" => "music_recording",
    "Music - Score" => "music",
    "Journal/Periodical" => "serial",
    #"Journal/Periodical" => "journal",
    "Manuscript/Archive" => "manuscript_archive",
    "Newspaper" => "newspaper",
    "Video" => "video",
    "Map/Globe" => "map_globe",
    "Book" => "book"
  }

  SUMMON_FORMAT_LIST = {
    "Book" => "ebooks",
    "Journal Article" => "article"
  }

# Following line needed for determin_formats method, replace with removed clio array element. See https://issues.library.cornell.edu/browse/DISCOVERYACCESS-310
#  FORMAT_RANKINGS = ["ac", "database", "map_globe", "manuscript_archive", "video", "music_recording", "music", "newspaper", "serial", "book", "clio", "ebooks", "article", "summon", "lweb"]
  FORMAT_RANKINGS = ["ac", "database", "map_globe", "manuscript_archive", "video", "music_recording", "music", "newspaper", "serial", "book", "ebooks", "article", "summon", "lweb"]

  def format_online_results(urls)
    non_circ = image_tag("icons/noncirc.png", :class => :availability)
    urls.collect { |link| non_circ + link_to(process_online_title(link.first).abbreviate(80), link.last) }
  end

  def format_location_results(locations)
    locations.collect do |location|

      loc_display, hold_id = location.split('|DELIM|')

      holdings_id = "holding_" + hold_id.to_s

      image_tag("icons/unknown.png", :class => "availability " + holdings_id) + process_holdings_location(loc_display)
    end
  end

  def determine_formats(document, defaults = [])
    formats = defaults.listify
    formats << "ac" if @active_source == "Academic Commons"
    formats << "database" if @active_source == "Databases"
    case document
    when SolrDocument
# Commenting out following line see https://issues.library.cornell.edu/browse/DISCOVERYACCESS-310
#      formats << "clio"

      document["format"].listify.each do |format|
        formats << SOLR_FORMAT_LIST[format] if SOLR_FORMAT_LIST[format]
      end
    when Summon::Document
      formats << "summon"
      document.content_types.each do |format|
        formats << SUMMON_FORMAT_LIST[format] if SUMMON_FORMAT_LIST[format]
      end
    when SerialSolutions::Link360
      formats << "summon"
    end

    formats.sort { |x,y| FORMAT_RANKINGS.index(x) <=> FORMAT_RANKINGS.index(y) }
  end

  # for segregating search values from display values
  DELIM = "|DELIM|"

  def generate_value_links(values, category)

    # display_value DELIM search_value [DELIM t880_flag]

    out = []

    values.listify.each do |v|
#    values.listify.select { |v| v.respond_to?(:split)}.each do |v|

      s = v.split(DELIM)

      unless s.length >= 2
        out << v
        next
      end

      # if displaying plain text, do not include links

      if @add_row_style == :text
        out << s[0]
      else

         Rails.logger.debug "#{__FILE__}:#{__LINE__}  method = #{__method__}"

        case category
        when :all
          q = '"' + s[1] + '"'
          out << link_to(s[0], url_for(:controller => "catalog", :action => "index", :q => q, :commit => "search"))
        when :author
          # s[2] is not nil when data is from an 880 field (vernacular)
          # temp workaround until we can get 880 authors into the author facet
          if s[2]
            # q = '"' + s[1] + '"'
            # out << link_to(s[0], url_for(:controller => "catalog", :action => "index", :q => q, :search_field => "author", :commit => "search"))
            out << s[0]
          else
            # remove puntuation from s[1] to match entries in author_facet using solrmarc removeTrailingPunc rule
            s[1] = s[1].gsub(/\.$/,'') if s[1] =~ /\w{3}\.$/ || s[1] =~ /[\]\)]\.$/
            out << link_to(s[0], url_for(:controller => "catalog", :action => "index", "f[author_facet][]" => s[1]))
          end
        when :subject
          out << link_to(s[0], url_for(:controller => "catalog", :action => "index", :q => s[1], :search_field => "subject", :commit => "search"))
        when :title
          q = '"' + s[1] + '"'
          out << link_to(s[0], url_for(:controller => "catalog", :action => "index", :q => q, :search_field => "title", :commit => "search"))
        else
          raise "invalid category specified for generate_value_links"
        end
      end
    end
    out
  end

  # def generate_value_links_subject(values)
  #
  #   # search value the same as the display value
  #   # quote first term of the search string and remove ' - '
  #
  #   values.listify.collect do |v|
  #
  #     sub = v.split(" - ")
  #     out = '"' + sub.shift + '"'
  #     out += ' ' + sub.join(" ") unless sub.empty?
  #
  #     link_to(v, url_for(:controller => "catalog", :action => "index", :q => out, :search_field => "subject", :commit => "search"))
  #
  #   end
  # end

  def generate_value_links_subject(values)

    # search value the same as the display value
    # but chained to create a series of searches that is increasingly narrower
    # esample: a - b - c
    # link display   search
    #   a             "a"
    #   b             "a b"
    #   c             "a b c"

    values.listify.collect do |value|
#    values.listify.select { |x| x.respond_to?(:split)}.collect do |value|

      searches = []
      subheads = value.split(" - ")
      first = subheads.shift
      display = first
      search = first
      title = first

      searches << build_subject_url(display, search, title)

      unless subheads.empty?
        subheads.each do |subhead|
          display = subhead
          search += ' ' + subhead
          title += ' - ' + subhead
          searches << build_subject_url(display, search, title)
        end
      end

      if @add_row_style == :text
        searches.join(' - ')
      else
        searches.join(' > ')
      end

    end
  end

  def build_subject_url(display, search, title)
    if @add_row_style == :text
      display
    else
      link_to(display, url_for(:controller => "catalog",
                              :action => "index",
                              :q => '"' + search + '"',
                              :search_field => "subject",
                              :commit => "search"),
                              :title => title)
    end
  end

  def add_row(title, value, options = {})
    options.reverse_merge!( {
      :display_blank => false,
      :display_only_first => false,
      :join => nil,
      :abbreviate => nil,
      :html_safe => true,
      :expand => false,
      :style => @add_row_style || :definition
    })

    value_txt = convert_values_to_text(value, options)


    result = ""
    if options[:display_blank] || !value_txt.empty?
      if options[:style] == :text
        result = (title.to_s + ": " + value_txt.to_s + "\r\n").html_safe
      else

        result = content_tag(:div, :class => "row") do
          if options[:style] == :definition
            content_tag(:div, title.to_s.html_safe, :class => "label") + content_tag(:div, content_tag(:div, value_txt, :class => "value_box"), :class => "value")
          elsif options[:style] == :blockquote
            content_tag(:div, content_tag(:div, value_txt, :class => "value_box"), :class => "blockquote")
          end
        end
      end

    end

    result
  end

  def convert_values_to_text(value, options = {})

    values = value.listify

    values = values.collect { |txt| txt.to_s.abbreviate(options[:abbreviate]) } if options[:abbreviate]

    values = values.collect(&:html_safe) if options[:html_safe]
    values = if options[:display_only_first]
      values.first.to_s.listify
    elsif options[:join]
      values.join(options[:join]).to_s.listify.reject { |item| item.to_s.empty? }
    else
      values
    end

    value_txt = if options[:style] == :text
      values.join("\r\n  ")
    else
      pre_values = values.collect { |v| content_tag(:div, v, :class => 'entry') }


      if options[:expand] && values.length > 3
        pre_values = [
          pre_values[0],
          pre_values[1],
          content_tag(:div, link_to("#{values.length - 2} more &#x25BC;".html_safe, "#"), :class => 'entry expander'),
          content_tag(:div, pre_values[2..-1].join('').html_safe, :class => 'expander_more')
        ]

      end

      pre_values.join('')
    end

    value_txt = value_txt.html_safe if options[:html_safe]

    value_txt
  end

  # Test whether we need previous or next document links
  def prev_next_needed(prev_doc, next_doc, prev_bookmark=nil, next_bookmark=nil)
    if (params[:controller] == 'bookmarks' || (prev_bookmark.present? || next_bookmark.present?) || (prev_doc.present? || next_doc.present?))
      return true
    end
  end

  # Test whether we need back to catalog link
  def back_to_catalog_needed
    return !session[:search].blank?
  end


  # set URL & counter for previous/next link_to depending on current controller
  def bookmark_or_not(document)
    unless document.blank?
      if params[:controller] == 'bookmarks'
        context = {
          :url => bookmark_path(document)
        }
      else
        context = {
          :url => facet_catalog_path(document),
          :data_counter => session[:search][:counter].to_i
        }
      end
    end
  end

  # Overrides original method from blacklight_helper_behavior.rb
  def link_to_document(doc, opts={:label=>nil, :counter => nil, :results_view => true})
    opts[:label] ||= blacklight_config.index.show_link.to_sym
    label = _cornell_render_document_index_label doc, opts
    if params[:controller] == 'bookmarks'
      docID = doc.id
      link_to label, '/bookmarks/' + docID
    else
      link_to label, doc, { :'data-counter' => opts[:counter] }.merge(opts.reject { |k,v| [:label, :counter, :results_view].include? k  })
    end
  end

  # link_back_to_catalog()
  # Overrides original method from blacklight_helper_behavior.rb
  # Build the URL to return to the search results, keeping the user's facet, query and paging choices intact by using session.
  def link_back_to_catalog(opts={:label=>nil})
    query_params = session[:search] ? session[:search].dup : {}
    Rails.logger.debug("es287_debug !!!!!!#{__FILE__}:#{__LINE__} search =  #{session[:search].inspect}")
    Rails.logger.debug("es287_debug !!!!!!#{__FILE__}:#{__LINE__} query_params =  #{query_params.inspect}")
    query_params.delete :counter
    query_params.delete :total
    if params[:controller] == 'search_history'
      link_url = url_for(action: 'index', controller: 'search', only_path: false, protocol: 'https')
      #link_url = url_for(query_params)
    else
      Rails.logger.debug("es287_debug !!!!!!#{__FILE__}:#{__LINE__} qp =  #{query_params.inspect}")
      link_url = url_for(query_params)
    end

    if link_url =~ /bookmarks/ || params[:controller] == 'bookmarks'
      opts[:label] ||= t('blacklight.back_to_bookmarks')
      link_url = bookmarks_path
    end

    opts[:label] ||= t('blacklight.back_to_search')

    link = {}
    link[:url] = link_url
    link[:label] = opts[:label]
    
    return link
  end

  # Next 3 is_x methods used for show_tools view to switch btw catalog & bookmarks
  def is_citable document
    if document.respond_to?(:export_as_mla_citation_txt) || document.respond_to?(:export_as_apa_citation_txt)
      return true
    end
  end

  def is_emailable document
    if document.respond_to?(:to_email_text)
      return true
    end
  end

  def is_exportable document
    if document.export_formats.keys.include?(:refworks_marc_txt) || document.export_formats.keys.include?(:endnote)
      return true
    end
  end

  # Overrides original method from blacklight_helper_behavior.rb
  # -- needed to add .html_safe to avoid html encoding in <title> element
  # Used in the show view for setting the main html document title
#  def document_show_html_title document=nil
#    document ||= @document
    # Test to ensure that display_title is not missing
    # -- some records in Voyager are missing the title (#DISCOVERYACCESS-552)
#    blacklight_config.show.html_title = @document['fulltitle_display']
#    if @document[blacklight_config.show.html_title].present?
#      render_field_value(document[blacklight_config.show.html_title].html_safe)
#    else
#      render_field_value("No Title".html_safe)
#    end
#  end

  # Overrides original method from facets_helper_behavior.rb
  # Renders a count value for facet limits with comma delimeter
  # Removed override, blacklight 5 provides commas

  #def render_facet_count(num)
   # content_tag("span", number_with_delimiter(t('blacklight.search.facets.count', :number => num)), :class => "count")
    #content_tag("span", format_num(t('blacklight.search.facets.count', :number => num)), :class => "count")
  #end

  # Overrides original method from blacklight_helper_behavior.rb
  # -- Updated to handle arrays (multiple fields specified in config)
  # Used for creating a link to the document show action
  def document_show_link_field document=nil
    blacklight_config.index.title_field.is_a?(Array) ? blacklight_config.index.title_field : blacklight_config.index.title_field.to_sym
  end

  # Overrides original method from blacklight_helper_behavior.rb
  # Renders label for link to document using 'title : subtitle' if subtitle exists
  # Also handle non-Roman script alternatives (vernacular) for title and subtitle
  #
# Render the document index heading
#
# @param [SolrDocument] doc
# @param [Hash] opts (deprecated)
# @option opts [Symbol] :label Render the given field from the document
# @option opts [Proc] :label Evaluate the given proc
# @option opts [String] :label Render the given string
# @param [Symbol, Proc, String] field Render the given field or evaluate the proc or render the given string
  def render_document_index_label doc, field, opts = {}
    #Deprecation.warn self, "render_document_index_label is deprecated"
    if field.kind_of? Hash
    #  Deprecation.warn self, "Calling render_document_index_label with a hash is deprecated"
      field = field[:label]
    end
    #Rails.logger.debug("es287_debug #{__FILE__}:#{__LINE__} presenter =  #{presenter(doc).inspect}")
    presenter(doc).label field, opts
  end

  # Overrides original method from blacklight_helper_behavior.rb
  # Renders label for link to document using 'title : subtitle' if subtitle exists
  # Also handle non-Roman script alternatives (vernacular) for title and subtitle
  def _cornell_render_document_index_label doc, opts
    #opts[:value]
    # label = nil
    # if opts[:label].is_a?(Array)
    #   title = doc.fetch(opts[:label][0], :sep => nil)
    #   Rails.logger.warn "mjc12test: doc: #{doc['fdisplay']}"
    #   subtitle = doc.fetch(opts[:label][1], :sep => nil)
    #   fulltitle_vern = doc.fetch(opts[:label][2], :sep => nil)
    #
    #   Rails.logger.warn "mjc12test: title: #{title}, subtitle: #{subtitle}"
    #   english = title.present? && subtitle.present? ? title + ' : ' + subtitle : title
    #
    #   # If title is missing, fall back to document id (bibid) as last resort
    #   label ||= english.present? ? english : doc.id
    #
    #   # If we have a non-Roman script alternative, prepend it
    #   if fulltitle_vern.present? && english.present?
    #     label.prepend(fulltitle_vern + ' / ')
    #   end
    # end

    # Rewriting because we can't get the above to work properly....
    label = nil
    field = "title"
    title = doc['fulltitle_display']
    vern = doc['fulltitle_vern_display']

    if title.present?
      label = title
    end

    if vern.present? && !title.nil?
      label = vern + ' / ' + label
    else
      if vern.present?
        label = vern
      end
    end

    label ||= doc['id']

    # This is a bit arcane, copied from the blacklight gem, so we're not sure we need it.
    # label ||= doc.fetch(opts[:label], :sep => nil) if opts[:label].instance_of? Symbol
    # label ||= opts[:label].call(doc, opts) if opts[:label].instance_of? Proc
    # label ||= opts[:label] if opts[:label].is_a? String
    # label ||= doc.id

    #dp = Blacklight::DocumentPresenter.new(nil, nil, nil)
    #dp.render_field_value label
    fp = Blacklight::FieldPresenter.new( self, doc, blacklight_config.show_fields[field], :value => label)
    fp.render
  end

  # Overrides original method from catalog_helper_behavior.rb
  # -- All this just to add commas (via format_num) to total result count
  # Pass in an RSolr::Response. Displays the "showing X through Y of N" message.
  #def render_pagination_info(response, options = {})
   #   pagination_info = paginate_params(response)

   # TODO: i18n the entry_name
   #   entry_name = options[:entry_name]
   #   entry_name ||= response.docs.first.class.name.underscore.sub('_', ' ') unless response.docs.empty?
    #  entry_name ||= t('blacklight.entry_name.default')

    #  case pagination_info.total_count
    #    when 0; t('blacklight.search.pagination_info.no_items_found', :entry_name => entry_name.pluralize ).html_safe
    #    when 1; t('blacklight.search.pagination_info.single_item_found', :entry_name => entry_name).html_safe
    #    else; t('blacklight.search.pagination_info.pages', :entry_name => entry_name.pluralize, :current_page => pagination_info.current_page, :num_pages => pagination_info.num_pages, :start_num => format_num(pagination_info.start), :end_num => format_num(pagination_info.end), :total_num => format_num(pagination_info.total_count), :count => pagination_info.num_pages).html_safe
     # end
  #end

  # Overrides original method from catalog_helper_behavior.rb
  # -- Allow for different default sort when browsing
  def current_sort_field
    query_params = session[:search] ? session[:search].dup : {}
    # if no search term is submitted and user hasn't specified a sort
    # assume browsing and use the browsing sort field
    if query_params[:q].blank? and query_params[:sort].blank?
      blacklight_config.sort_fields.values.select { |field| field.browse_default == true }.first
    # otherwise, resume regularly scheduled programming
    else
      blacklight_config.sort_fields[params[:sort]] || (blacklight_config.sort_fields.first ? blacklight_config.sort_fields.first.last : nil )
    end
  end

  # To vernaculate or not...that is the question
  # tlw72: modified this method for Blacklight 7. Now the values are passed in rather
  # than the field names.
  def the_vernaculator(engl, vern)
    display = engl
    vernacular = vern
    display = vernacular +  ' / ' + display unless vernacular.blank?
    return display
  end

  # Helper method to replace render_document_show_field_value with something that's
  # a little easier to call from a view. Requires a field name from the solr doc
  def field_value(field)
    field_config = blacklight_config.show_fields[field]
    Blacklight::ShowPresenter.new(@document, self).field_value field_config
  end

 def cornell_params_for_search(*args, &block)
      source_params, params_to_merge = case args.length
      when 0
        search_state.params_for_search
      when 1
        search_state.params_for_search(args.first)
      when 2
        Blacklight::SearchState.new(args.first, blacklight_config).params_for_search(args.last)
      else
        raise ArgumentError, "wrong number of arguments (#{args.length} for 0..2)"
      end
    end

    def cornell_sanitize_search_params(source_params)
      Blacklight::Parameters.sanitize(source_params)
    end
    deprecation_deprecate :sanitize_search_params

    def cornell_reset_search_params(source_params)
      Blacklight::SearchState.new(source_params, blacklight_config).send(:reset_search_params)
    end

    def cornell_add_facet_params(field, item, source_params = nil)
      if source_params

        Blacklight::SearchState.new(source_params, blacklight_config).add_facet_params(field, item)
      else
        search_state.add_facet_params(field, item)
      end
    end

    def cornell_remove_facet_params(field, item, source_params = nil)
      if source_params
        Blacklight::SearchState.new(source_params, blacklight_config).remove_facet_params(field, item)
      else
        search_state.remove_facet_params(field, item)
      end
    end

    def cornell_add_facet_params_and_redirect(field, item)
      search_state.add_facet_params_and_redirect(field, item)
    end

##########

  # Display the Solr core for everything but production instance
  def render_solr_core
    unless request.host == 'search.library.cornell.edu' or request.host == 'newcatalog.library.cornell.edu'
      core = Blacklight.connection_config[:url]
      # Remove http protocol string
      start = core.rindex(/http:\/\//) + 7
      display = '<p class="solr-core">Solr core: ' + core[start..-1] + '</p>'
      display.html_safe
    end
  end

  # Clean up isbn in prep for bookcovers via Google Books API
  def bookcover_isbn(document)
    isbn = document['isbn_display']
    unless isbn.blank?
      isbn = isbn.first
      # Find first occurence of a space (remove non integer chars)
      space = isbn.index(' ')
      unless space.blank?
        stop = space - 1
        isbn[0..stop]
      else
        isbn
      end
    end
  end

  # Parse other_id_display field for OCLC numbers
  def bookcover_oclc(document)
    #Rails.logger.info("CONGAME = #{document.inspect}")
#    Rails.logger.info("CONGAME = #{document['oclc_id_display']}")
#    oclc_id = document['oclc_id_display'][0]
    other_ids = document['other_id_display']
    oclc_id = document['oclc_id_display'][0] #other_ids.find { |e| /^\(OCoLC\)/ =~ e } unless other_ids.blank?
    unless oclc_id.blank?
      # Remove '(OCLC)' prefix
      # -- really need to ask Frances about making OCLC# its own field
      oclc_id.gsub(/^\(OCoLC\)/, '')
    end
  end

  def bookcover_oclc(document)
    if document['oclc_id_display'].nil?
      oclc_id = ''
    else
      oclc_id = document['oclc_id_display'][0]
    end
    return oclc_id
  end
  # Overrides original method from facets_helper_behavior.rb
  # -- Replace icon-remove (glyphicon) with appropriate Font Awesome classes
  # Standard display of a SELECTED facet value, no link, special span
  # with class, and 'remove' button.

  def render_facet_item(solr_field, item)
    if solr_field == 'format'
      format = item.value
      path = search_action_path(cornell_add_facet_params_and_redirect(solr_field, item))
      if (facet_icon = FORMAT_MAPPINGS[format])
        facet_icon = '<i class="fa fa-' + facet_icon + '"></i> '
      end
      if facet_in_params?( solr_field, item.value )
        content_tag(:span, :class => "selected") do
          content_tag(:span, render_facet_value(solr_field, item, :suppress_link => true))  +
          link_to(content_tag(:i, '', :class => "fa fa-times") + content_tag(:span, ' [remove]'), cornell_remove_facet_params(solr_field, item, params), :class=>"remove")
        end
      else
        content_tag(:span, :class => "facet-label") do
          (facet_icon).html_safe + link_to(facet_display_value(solr_field, item), path, :class=>"facet_select")
        end + render_facet_count(item.hits)
      end
    else
      if facet_in_params?( solr_field, item.value )
        content_tag(:span, render_facet_value(solr_field, item, :suppress_link => true), :class => "selected") +
        link_to(content_tag(:i, '', :class => "fa fa-times") + content_tag(:span, ' [remove]'), cornell_remove_facet_params(solr_field, item, params), :class=>"remove")
      else
        render_facet_value(solr_field, item)
      end
    end
  end

  def render_facet_value(facet_solr_field, item, options ={})
    path = search_action_path(cornell_add_facet_params_and_redirect(facet_solr_field, item))
    if facet_solr_field != 'format'
      content_tag(:span,:class=>'facet-label') do
        link_to_unless(options[:suppress_link], facet_display_value(facet_solr_field, item), path, :class=>"facet_select")
      end + render_facet_count(item.hits)
    else
      format = item.value
      if (facet_icon = FORMAT_MAPPINGS[format])
        facet_icon = '<i class="fa fa-' + facet_icon + '"></i> '
      end
      content_tag(:span, :class => "facet-label") do
        (facet_icon).html_safe +

        link_to_unless(options[:suppress_link], facet_display_value(facet_solr_field, item), path, :class=>"facet_select")
      end + render_facet_count(item.hits)
    end
  end
#
#  simple_ are versions of deprecated functions
#
  def simple_render_index_field_value *args
    simple_render_field_value(*args)
  end

  def simple_render_field_value(*args)
    options = args.extract_options!
    document = args.shift || options[:document]
    field = args.shift || options[:field]
    field_config = blacklight_config.index_fields[field]
    presenter(document).field_value field_config, options.except(:document, :field)
  end

  def simple_render_document_index_label(*args)
    label(*args)
  end

  # Advanced Search History and Advanced Saved Searches display
  def link_to_previous_advanced_search(params)
    link_to(parseHistoryShowString(params), parseHistoryQueryString(params))
  end

  def parseHistoryShowString(params)
    showText = ''

    sf_row = params[:search_field_row]
    q_row = params[:q_row]
    b_row = params[:boolean_row]

    i = 0
    num = sf_row.length

    while i < num do
      if i > 0
        showText = showText + " " + "#{b_row[i.to_s.to_sym]}" + " " + search_field_def_for_key(sf_row[i])[:label] + ": " + q_row[i]
      else
        showText = showText + search_field_def_for_key(sf_row[i])[:label] + ": " + q_row[i]
      end
      i += 1
    end
    ## Sends 'correct' q param to link_link_to_previous_search
    params[:q] = showText
    ## Uses overridden render_search_to_s_q(params) function below originally from app/helper/blacklight/search_history_constraints_helper_behavior.rb
    showText = link_to_previous_search(params)

    return showText
  end

  def parseHistoryQueryString(params)
    start = "catalog?only_path=true&utf8=✓&advanced_query=yes&omit_keys[]=page&params[advanced_query]=yes"
    if params[:sort].nil?
      finish = "&sort=score+desc%2C+pub_date_sort+desc%2C+title_sort+asc&search_field=advanced&commit=Search"
    else
      finish = "&" + params[:sort]
    end
    linkText = ''
    f_linkText = ''
    q_row = params[:q_row]
    op_row = params[:op_row]
    sf_row = params[:search_field_row]
    b_row = params[:boolean_row]
    if !params[:f].nil?
      f_row = params[:f]
    else
      f_row = {}
    end

    i = 0
    num = q_row.length
    while i < num do
      if i > 0
        linkText = linkText + "&boolean_row[#{i}]=" + "#{b_row[i.to_s.to_sym]}" + "&q_row[]=" + CGI.escape(q_row[i])+ "&op_row[]=" + op_row[i] + "&search_field_row[]=" + sf_row[i]
      else
        linkText = linkText + "&q_row[]=" + CGI.escape(q_row[i]) + "&op_row[]=" + op_row[i] + "&search_field_row[]=" + sf_row[i]
      end
      i += 1
    end
    f_row.each do | key, value |
       value.each do |text|
         f_linkText = f_linkText + "&f[" + key + "][]=" + text
       end
    end
    linkText = start + linkText + f_linkText + finish
    return linkText
  end

  #switch to determine if a view is part of the main catalog and should get the header
  def part_of_catalog?
    if params[:controller] =='catalog' || params[:controller]=='bookmarks' ||
      request.original_url.include?("request") || params[:controller]=='search_history' ||
      params[:controller] == 'advanced_search' || params[:controller]=='aeon' || params[:controller]=='browse' ||
      params[:controller] == 'book_bags'
      return true
    end
  end

  # deprecated function from blacklight 4 that will live on
  def sidebar_items
    @sidebar_items ||= []
  end

  def render_extra_head_content
    if !@extra_head_content.nil?
    @extra_head_content.join("\n").html_safe
    end
  end

  def render_head_content
     Deprecation.silence(Blacklight::HtmlHeadHelperBehavior) do
       render_stylesheet_includes +
       render_js_includes +
       render_extra_head_content
     end +
     content_for(:head)
   end

  def bento_online_url(url_online_access, url_item)
    if url_online_access.size > 1
      url_item
    else
      # url_online_access[0]
      # Remove trailing link label text if it exists
      link = url_online_access[0]
      link_end = link.rindex(/\|/).blank? ? link.size : link.rindex(/\|/) -1
      link[0..link_end]
    end
  end

  def is_cataloged(url)
    if url.nil?
      false
    else
      #(url.include?("/catalog/") && !url.include?( "library.cornell.edu"))
      url.starts_with?("/catalog/")
    end
  end

  def random_image
    require 'open-uri'
    require 'nokogiri'
    addr = "https://www.flickr.com/explore/interesting/7days/"
    ptag = ".Photo"
    doc = Nokogiri::HTML(open( addr ))
    photo = (doc.css( ptag )).first
    p_src = photo.css("img").first.attr("src")
    p_src
  end

  def xrandom_image
    require 'open-uri'
    require 'nokogiri'
    q = random_quote
    t = q.split()
    t = t.max_by(&:length)
    addr = "https://www.flickr.com/photos/tags/#{t}"
    ptag = ".Photo"
    doc = Nokogiri::HTML(open( addr ))
    photo = (doc.css( ptag )).first
    p_src = photo.css("img").first.attr("src")
    p_src
  end

  def random_quote
    adr = 'http://api.forismatic.com/api/1.0/'
    fmt = 'json'
    language = 'en'
    key = ''
    jquote = HTTPClient.get_content("#{adr}?method=getQuote&key=&format=json&lang=en&clientApplication=gooz")
    author = JSON.parse(jquote)["quoteAuthor"]
    quote = JSON.parse(jquote)["quoteText"] +  " -- " + author
  end


  def html_safe field
    require 'htmlentities'
    coder = HTMLEntities.new
    result =[]
    field[:value].each do |r|
      r = coder.decode(r)
      r = ERB::Util.html_escape(r)
      result << r
    end
    result = result.to_sentence.html_safe
  end

  def holdings_html_safe holdings
    require 'htmlentities'
    coder = HTMLEntities.new
    result =[]
    holdings.each do |r|
      r = coder.decode(r)
      r = ERB::Util.html_escape(r)
      result << r
    end
    result = result.to_sentence.html_safe
  end

# Render the search query constraint
  def render_search_to_s_q(params)
    return "".html_safe if params['q'].blank?
    if params[:q_row].nil?

      label = label_for_search_field(params[:search_field]) unless default_search_field && params[:search_field] == default_search_field[:key]
    else
      label = ""
    end
    render_search_to_s_element(label , render_filter_value(params['q']) )
  end
end
