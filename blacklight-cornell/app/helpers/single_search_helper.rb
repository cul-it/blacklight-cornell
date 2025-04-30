module SingleSearchHelper
  def extra_body_classes
    @extra_body_classes ||= [controller.controller_name, [controller.controller_name, controller.action_name].join('-')]
  end

  def render_body_class
    extra_body_classes.join " "
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
    if pane == 'Articles & Full Text' || pane == 'Library Guides' || pane == 'Digital Collections' || pane == 'Repositories'
      false
    else
       true
    end
  end

  def bento_all_results_link(key)
    case key
    when "libguides"
      link = 'http://guides.library.cornell.edu/libguides/home'
    when "ebsco_eds"
      bq = params[:q] || params[:query]
      if bq.present?
        link = "https://discovery.ebsco.com/c/u2yil2/results?q=#{bq}"
      else
        link = "https://discovery.ebsco.com/c/u2yil2"
      end
    when "digitalCollections"
      link = controller.all_items_url(key, params[:q] || params[:query], bento_blacklight_format(key))
    else
      # our app chooses to use 'q' as the query param; the ajax loading controller
      # uses 'query'.This ordinarily is fine, but since we want this layout to work
      # for both, we have to look for both, oh well.
      link = controller.all_items_url(key, params[:q] || params[:query], bento_blacklight_format(key))
      link = request.protocol + request.host_with_port + '/' + link
    end

    link_url = ss_uri_encode(link)
  end

  def bento_eds_count()
    eds_total = 0
    bq = params[:q] || params[:query]
    if bq.present?
      searcher = BentoSearch::ConcurrentSearcher.new(:ebsco_eds)
      searcher.search(bq, :per_page => 0)
      searcher.results.each_pair do |key, result|
        eds_total = result.total_items.to_s
        break
      end
    end
    return eds_total
  end

  def bento_title(key)
    BentoSearch.get_engine(key).configuration.title
  rescue BentoSearch::NoSuchEngine
    pluralize_format(key)
  end

  def bento_blacklight_format(key)
    BentoSearch.get_engine(key).configuration.blacklight_format
  rescue BentoSearch::NoSuchEngine
    key
  end

end
