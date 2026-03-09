# frozen_string_literal: true

module BlacklightUnapi
  module ControllerExtension
    extend ActiveSupport::Concern

    included do
      helper BlacklightUnapiHelper
    end

    def unapi
      @export_formats = blacklight_config.unapi
      requested_format = params[:format]
      format_key = requested_format&.to_sym

      if params[:id]
        @response, @document = search_service.fetch(params[:id])
        @export_formats = @document.export_formats
      end

      if requested_format && @document
        export_config = @export_formats[format_key] || @export_formats[requested_format]
        if export_config && @document.exports_as?(format_key || requested_format)
          send_data @document.export_as(format_key || requested_format), type: export_config[:content_type], disposition: 'inline'
        else
          head :not_acceptable
        end
      else
        render 'catalog/formats', formats: [:xml]
      end
    end
  end
end
