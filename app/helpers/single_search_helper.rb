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

end
