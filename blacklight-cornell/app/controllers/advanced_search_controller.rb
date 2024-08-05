class AdvancedSearchController < ApplicationController
  # drop down problems?
  #
  #include Blacklight::Catalog
  #include BlacklightCornell::CornellCatalog

  include LoggingHelper

  delegate :blacklight_config, to: :default_catalog_controller

  before_action :heading
  if ENV["SAML_IDP_TARGET_URL"]
    prepend_before_action :set_return_path
  end

  def heading
    @heading = "Advanced Search"
  end

  def edit
    if !params[:q_row].nil?
      for i in 0..params[:q_row].count - 1
        if params[:q_row][i].include?("%26")
          params[:q_row][i] = params[:q_row][i].gsub!("%26", "&")
        end
        i = i + 1
      end
    end
    render "advanced_search/index", :locals => { :params => params }
  end

  def index
    Rails.logger.debug("#{__FILE__}:#{__LINE__} #{@query}")
    Appsignal.increment_counter("adv_search_index", 1)
    #  @catalog_host = get_catalog_host(request.host)

    unless params["q"].nil?
      @query = params["q"]
      @query.slice! "doi:"
      original_query = @query

      # Modify query for improved Solr search (and to match Blacklight changes) (DISCOVERYACCESS-1103)
      if @query.empty?
        # no action, pass through
        # Something about the Summon engine causes the search to choke if the query is empty.
        # All the other engines are fine with either empty or a single space character, and
        # forcing to the space allows the Summon empty query to work.
        @query = " "
        # Only do the following if the query isn't already quoted
      else
        #      @query = objectify_query @query
        @query = @query
      end
      Rails.logger.debug("#{__FILE__}:#{__LINE__} #{@query}")

      if session[:search].nil?
        session[:search] = {}
      end
      log_debug_info("#{__FILE__}:#{__LINE__}", ["@query:", @query], ["original_query:", original_query])
      session[:search][:q] = @query
      session[:search][:search_field] = "all_fields"
      session[:search][:controller] = "search"
      session[:search][:action] = "index"
      # session[:search][:counter] = ?
      # session[:search][:total] = ?

      #      Rails.logger.warn "mjc12test: session(ss): #{session[:search]}"
      render "advanced_search/index"
    end
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
end
