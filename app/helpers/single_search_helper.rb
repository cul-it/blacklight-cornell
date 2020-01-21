module SingleSearchHelper
  def extra_body_classes
    @extra_body_classes ||= [controller.controller_name, [controller.controller_name, controller.action_name].join('-')]
  end

  def render_body_class
    extra_body_classes.join " "
  end

  def ss_encode (str)
     str
     #CGI::escape(str)
     #str = str.gsub('%','%25')
  end

  def downcast (str)
    str.gsub(/\//, '_').
    gsub(/::/, '/').
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    gsub(/([a-z\d])([A-Z])/,'\1_\2').
    tr(" -", "_").
    downcase
  end
  def ss_uri_encode (link_url)
    link_url = link_url.gsub('% ','%25%20') unless link_url.match('%25')
    link_url = link_url.gsub('$','%24')
    link_url = link_url.gsub(';','%3B')
    link_url = link_url.gsub(' ','%20')
    link_url = link_url.gsub('[','%5B')
    link_url = link_url.gsub(']','%5D')
    #  -# link_url = link_url.gsub('=','%3D')
    #  -# link_url = link_url.gsub('&','%26')
    link_url = link_url.gsub('"','%22')
    link_url = link_url.gsub('(','%28')
    link_url = link_url.gsub(')','%29')
  end

  def is_catalog_pane?(pane)
    if pane == 'Articles & Full Text' || pane == 'Library Guides' || pane == 'Digital Collections'
      false
    else
       true
    end
  end

  def bento_all_results_link(key)
    case key
    when "libguides"
      link = 'http://guides.library.cornell.edu/libguides/home'
    when "ebsco_ds"
      bq = ss_encode(params[:q] || params[:query])
      if bq.present?
        edsq = {direct: true, authtype: "ip,uid", profile: "eds", bQuery: bq,
          custid: "s9001366", groupid: "main" }
        edsuri = URI::HTTP.build(host: 'search.ebscohost.com', query: URI.encode_www_form(edsq))
      else
        edsuri = 'http://search.ebscohost.com/login.aspx?authtype=ip,guest&profile=eds&Groupid=main&custid=s9001366'
      end
      link = 'http://encompass.library.cornell.edu/cgi-bin/checkIP.cgi?access=gateway_standard%26url=' + edsuri.to_s
    when "summon_bento"
      link = "#"
    when "digitalCollections"
      link = controller.all_items_url(key, ss_encode(params[:q] || params[:query]), BentoSearch.get_engine(key).configuration.blacklight_format)
    else
      # our app chooses to use 'q' as the query param; the ajax loading controller
      # uses 'query'.This ordinarily is fine, but since we want this layout to work
      # for both, we have to look for both, oh well.
      link = controller.all_items_url(key, ss_encode(params[:q] || params[:query]), BentoSearch.get_engine(key).configuration.blacklight_format)
      link = request.protocol + request.host_with_port + '/' + link
    end

    link_url = ss_uri_encode(link)
  end

end
