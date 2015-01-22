# Meant to be applied on top of a controller that implements
# Blacklight::SolrHelper. 
module BlacklightUnapi::ControllerExtension
  def self.included(some_class)
    some_class.helper_method :unapi_config
    some_class.helper BlacklightUnapiHelper
    some_class.helper BlacklightUnapi::ViewHelperExtension
    some_class.before_filter do
      extra_head_content << view_context.auto_discovery_link_tag(:unapi, unapi_url, {:type => 'application/xml',  :rel => 'unapi-server', :title => 'unAPI' })
    end
  end

  def unapi
    @export_formats = unapi_default_export_formats
    @format = params[:format]

    if params[:id]
      @response, @document = get_solr_response_for_doc_id
      @export_formats = @document.export_formats
    end
	 	
    unless @format
      render 'unapi/formats.xml.builder', :layout => false and return
    end

	 	
    respond_to do |format|
      format.all do
        send_data @document.export_as(@format), :type => @document.export_formats[@format][:content_type], :disposition => 'inline' if @document.will_export_as @format
      end
    end
  end

  # Uses Blacklight.config, needs to be modified when
  # that changes to be controller-based. This is the only method
  # in this plugin that accesses Blacklight.config, single point
  # of contact. 
  def unapi_config   
    self.blacklight_config[:unapi] || {}
  end

  def unapi_default_export_formats
    unapi_config
  end

end
