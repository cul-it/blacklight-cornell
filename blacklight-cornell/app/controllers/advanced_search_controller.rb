class AdvancedSearchController < ApplicationController
  include Blacklight::Catalog
  include LoggingHelper

  delegate :blacklight_config, to: :default_catalog_controller

  before_action :set_facets, only: [:edit, :index]
  after_action :update_facets, only: [:edit, :index]

  if ENV["SAML_IDP_TARGET_URL"]
    prepend_before_action :set_return_path
  end

  def edit
    params[:q_row].each { |q| q.gsub!('%26', '&') } if params[:q_row].is_a?(Array)

    respond_to :html
  end

  def index
    Rails.logger.debug("#{__FILE__}:#{__LINE__} #{@query}")
    Appsignal.increment_counter("adv_search_index", 1)

    unless params["q"].nil?
      @query = params["q"]
      @query.slice! "doi:"
      Rails.logger.debug("#{__FILE__}:#{__LINE__} #{@query}")

      if session[:search].nil?
        session[:search] = {}
      end
      log_debug_info("#{__FILE__}:#{__LINE__}", ["@query:", @query])
      session[:search][:q] = @query
      session[:search][:search_field] = "all_fields"
      session[:search][:controller] = "search"
      session[:search][:action] = "index"
    end

    respond_to :html
  end

  def set_return_path
    Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__}  params = #{params.inspect}")
    op = request.original_fullpath
    Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__}  original = #{op.inspect}")
    refp = request.referer
    Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__}  referer path = #{refp}")
    session[:cuwebauth_return_path] = if (params["id"].present? && params["id"].include?("|"))
        "/bookmarks"
      elsif (params["id"].present? && op.include?("email"))
        "/catalog/afemail/#{params[:id]}"
      elsif (params["id"].present? && op.include?("unapi"))
        refp
      else
        op
      end
    Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__}  return path = #{session[:cuwebauth_return_path]}")
    return true
  end

  private

  def set_facets
    @old_advanced_facet_fields = advanced_facet_fields.deep_dup
    advanced_facet_fields.each do |_k, config|
      config.limit = -1
      # Sort by most common instead of alphabetical:
      # config.sort = 'count'
    end

    (@response, _deprecated_document_list) = blacklight_advanced_search_form_search_service.search_results

    @facets = advanced_facet_fields.each_with_object({}) do |(k, config), h|
      h[k] = { field_config: config, display_facet: @response.aggregations[k] }
    end
  end

  # Extremely sad hack to reset the default facet limit for search results - need to revisit as part of DACCESS-289
  def update_facets
    advanced_facet_fields.each do |k, config|
      config.limit = @old_advanced_facet_fields[k].limit
    end
  end

  def advanced_facet_fields
    blacklight_config.facet_fields.select { |_k, config| config.include_in_advanced_search }
  end
end
