class AdvancedSearchController < ApplicationController
  include Blacklight::Catalog
  include LoggingHelper

  delegate :blacklight_config, to: :default_catalog_controller

  before_action :set_facets, only: [:edit, :index]
  after_action :reset_facets, only: [:edit, :index]

  rescue_from RSolr::Error::Http, :with => :handle_request_error

  if ENV["SAML_IDP_TARGET_URL"]
    prepend_before_action :set_return_path
  end

  def edit
    params[:q_row].each { |q| q.gsub!('%26', '&') } if params[:q_row].is_a?(Array)

    respond_to :html
  end

  def index
    Appsignal.increment_counter("adv_search_index", 1)

    unless params["q"].nil?
      @query = params["q"]
      @query.slice! "doi:"

      if session[:search].nil?
        session[:search] = {}
      end

      session[:search][:q] = @query
      session[:search][:search_field] = "all_fields"
      session[:search][:controller] = "search"
      session[:search][:action] = "index"
    end

    respond_to :html
  end

  def set_return_path
    op = request.original_fullpath
    refp = request.referer

    session[:cuwebauth_return_path] = if (params["id"].present? && params["id"].include?("|"))
                                        "/bookmarks"
                                      elsif (params["id"].present? && op.include?("email"))
                                        "/catalog/afemail/#{params[:id]}"
                                      elsif (params["id"].present? && op.include?("unapi"))
                                        refp
                                      else
                                        op
                                      end
    true
  end


  private

  def set_facets
    # Override facet field limits in blacklight_config to display all facet values
    @default_facet_fields = advanced_facet_fields.deep_dup
    advanced_facet_fields.each { |_k, config| config.limit = -1 }

    # Get facet values from solr
    (@response, _deprecated_document_list) = blacklight_advanced_search_form_search_service.search_results

    # Order the facets by advanced_search_order for display, overrides add_facet_field order in blacklight_config
    ordered_advanced_facet_fields = advanced_facet_fields.sort_by { |_k, config| config.advanced_search_order }.to_h
    @facets = ordered_advanced_facet_fields.each_with_object({}) do |(k, config), h|
      h[config.field] = { field_config: config, display_facet: @response.aggregations[config.field] }
    end
  end

  # Resets the default facet limit for blacklight_config facet fields
  def reset_facets
    advanced_facet_fields.each { |k, config| config.limit = @default_facet_fields[k].limit }
  end

  def advanced_facet_fields
    @advanced_facet_fields ||= blacklight_config.facet_fields.select { |_k, config| config.include_in_advanced_search }
  end
end
