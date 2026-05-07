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

  def is_catalog_pane?(key)
    ['ebsco_eds', 'libguides', 'digitalCollections', 'institutionalRepositories'].exclude?(key)
  end

  def bento_all_results_link(key)
    # our app chooses to use 'q' as the query param; the ajax loading controller
    # uses 'query'.This ordinarily is fine, but since we want this layout to work
    # for both, we have to look for both, oh well.
    query = params[:q] || params[:query]

    case key
    when "libguides"
      "https://guides.library.cornell.edu/libguides/home"
    when "ebsco_eds"
      if query.present?
        "https://discovery.ebsco.com/c/u2yil2/results?#{URI.encode_www_form(q: query)}"
      else
        "https://discovery.ebsco.com/c/u2yil2/results"
      end
    when "digitalCollections"
      "https://digital.library.cornell.edu/catalog?utf8=%E2%9C%93&#{URI.encode_www_form(q: query)}&search_field=all_fields"
    when "institutionalRepositories"
      institutional_repositories_index_path(q: query)
    when "catalog"
      search_catalog_path(q: query, search_field: "all_fields")
    else
      format = bento_blacklight_format(key)
      search_catalog_path(q: query, search_field: "all_fields", f: {format: [format]})
    end
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
