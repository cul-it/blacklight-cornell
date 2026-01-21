module Blacklight::Marc
  module Catalog
    extend ActiveSupport::Concern

    def librarian_view
      deprecator = ActiveSupport::Deprecation.new
      if Blacklight::VERSION >= '8'
        @document = search_service.fetch(params[:id])
        @response = ActiveSupport::Deprecation::DeprecatedObjectProxy.new(@document.response, "The @response instance variable is deprecated and will be removed in Blacklight-marc 8.0", deprecator)

      else
        deprecated_response, @document = search_service.fetch(params[:id])
        @response = ActiveSupport::Deprecation::DeprecatedObjectProxy.new(deprecated_response, "The @response instance variable is deprecated and will be removed in Blacklight-marc 8.0", deprecator)
      end

      respond_to do |format|
        format.html
        format.js { render :layout => false }
      end
    end
  end
end
