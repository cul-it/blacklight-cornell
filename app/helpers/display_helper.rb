module DisplayHelper

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
    '<br/>'
  end

  # :format arg specifies what should be returned
  # * the raw array (url_access_display in availability on item page)
  # * url only (search results)
  # * link_to's with trailing <br>'s -- the default -- (url_other_display &
  # url_toc_display in field listing on item page)
  def render_display_link args
    label = blacklight_config.display_link[args[:field]][:label]
    links = args[:value]
    links ||= args[:document].get(args[:field], :sep => nil) if args[:document] and args[:field]
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
      link_to(label, url.html_safe, {:class => 'online-access'})
    end

    if render_format == 'raw'
      return value
    else
      render_field_value value
    end
  end

  def render_clickable_document_show_field_value args
    value = args[:value]
    value ||= args[:document].get(args[:field], :sep => nil) if args[:document] and args[:field]
    args[:sep] ||= blacklight_config.multiline_display_fields[args[:field]] || field_value_separator;

    value = [value] unless value.is_a? Array
    value = value.collect { |x| x.respond_to?(:force_encoding) ? x.force_encoding("UTF-8") : x}
    return value.map { |v| render_clickable_item(args, v) }.join(args[:sep]).html_safe
  end

  def render_clickable_item args, value
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
            link_to(displayv_searchv[0], add_search_params(args[:field], '"' + displayv_searchv[1] + '"'))
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
            link_to(v, add_search_params(args[:field], '"' + hierarchical_value + '"'))
          end.join(sep_display).html_safe
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


  def add_search_params(field, value)
    new_search_params = {
    #  :utf8 => '✓',
      :q => value,
      :search_field => get_clickable_search_field(field),
      :commit => 'search',
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

  def display_link?(field)
    return blacklight_config.display_link[field] != nil
  end

  def online_url(document)
    if document['url_access_display'].present?
      if document['url_access_display'].size > 1
        catalog_path(document)
      else
        render_display_link(:document => document, :field => 'url_access_display', :format => 'url')
      end
    end
  end

  FORMAT_MAPPINGS = {
    "Book" => "book",
    "Online" =>"link",
    "Computer File" => 'save',
    "Non-musical Recording" => "headphones",
    "Musical Score" => "musical-score",
    "Musical Recording" => "music",
    "Thesis" => "thesis",
    "Microform" => "th",
    "Serial" => "copy",
    "Journal/Periodical" => "copy",
    "Journal" => "copy",
    "Conference Proceedings" => "conference",
    "Video" => "film",
    "Map or Globe" => "globe",
    "Manuscript/Archive" => "manuscript",
    "Newspaper" => "newspaper",
    "Database" => "hdd",
    "Image" => "picture",
    "Unknown" => "question-sign",
    "Kit" => "kit",
    "Research Guide" => "research-guide",
    "Course Guide" => "course-guide"
  }

  def formats_icon_mapping(format)
    if (icon_mapping = FORMAT_MAPPINGS[format])
      icon_mapping
    else
      'default'
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
    "Journal/Periodical" => "journal",
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

  FORMAT_RANKINGS = ["ac", "database", "map_globe", "manuscript_archive", "video", "music_recording", "music", "newspaper", "serial", "book", "clio", "ebooks", "article", "summon", "lweb"]

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
      formats << "clio"

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

        case category
        when :all
          q = '"' + s[1] + '"'
          out << link_to(s[0], url_for(:controller => "catalog", :action => "index", :q => q, :search_field => "all_fields", :commit => "search"))
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

  # link_back_to_catalog()
  # Overrides original method from blacklight_helper_behavior.rb
  # Build the URL to return to the search results, keeping the user's facet, query and paging choices intact by using session.
  def link_back_to_catalog()
    query_params = session[:search] ? session[:search].dup : {}
    query_params.delete :counter
    query_params.delete :total
    link_url = url_for(query_params)

    link_url
  end

  def url_to_borrowdirect(isbn)
    link_url = "http://resolver.library.cornell.edu/net/parsebd/?&url_ver=Z39.88-2004&rft_id=urn%3AISBN%3A" + isbn + "&req_id=info:rfa/oclc/institutions/3913"

    link_url
  end
end
