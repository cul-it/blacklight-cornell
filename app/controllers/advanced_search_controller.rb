class AdvancedSearchController < ApplicationController
# drop down problems?
#
  #include Blacklight::Catalog
  #include BlacklightCornell::CornellCatalog

  delegate :blacklight_config, to: :default_catalog_controller

  before_filter :heading
  if   ENV['SAML_IDP_TARGET_URL']
    prepend_before_filter :set_return_path
  end


  def heading
   @heading='Advanced Search'
  end

  def edit
    if !params[:q_row].nil?
    for i in 0..params[:q_row].count - 1
      if params[:q_row][i].include?('%26')
        params[:q_row][i] = params[:q_row][i].gsub!('%26', '&')
      end
      i = i + 1
    end
    end
    return params
  end

  def index
      Rails.logger.debug("#{__FILE__}:#{__LINE__} #{@query}")
      Appsignal.increment_counter('adv_search_index', 1)
    #  @catalog_host = get_catalog_host(request.host)

      unless params["q"].nil?
          @query = params['q']
          @query.slice! 'doi:'
          original_query = @query

          # Modify query for improved Solr search (and to match Blacklight changes) (DISCOVERYACCESS-1103)
          if @query.empty?
            # no action, pass through
            # Something about the Summon engine causes the search to choke if the query is empty.
            # All the other engines are fine with either empty or a single space character, and
            # forcing to the space allows the Summon empty query to work.
            @query = ' '
          # Only do the following if the query isn't already quoted
          else
      #      @query = objectify_query @query
            @query = @query
          end
          Rails.logger.debug("#{__FILE__}:#{__LINE__} #{@query}")
          #searcher = BentoSearch::MultiSearcher.new(:worldcat, :solr, :summon_bento, :web, :bestbet, :summonArticles)
#          searcher = BentoSearch::MultiSearcher.new(:worldcat, :solr, :summon_bento, :web, :bestbet, :summonArticles)
#          searcher.search(@query, :oq =>original_query,:per_page => 3)
#          @results = searcher.results

          # Reset query to make it show up properly for the user on the results page
#          @query = original_query

          # In order to treat multiple formats separately but only run one Solr query to retrieve
          # them all, we have to store the query result in the custom_data object ...
#          facet_results = @results['solr'][0].custom_data
          # ... which then needs some extra massaging to get the data into the proper form
#          faceted_results, @scores = facet_solr_results facet_results

#          if !@results['summon_bento'].nil?
#            @results['summon_bento'].each do |result|
#              result.link = 'http://encompass.library.cornell.edu/cgi-bin/checkIP.cgi?access=gateway_standard%26url=' + result.link unless result.link.nil?
#            end
#          end
#          if !@results['summonArticles'].nil?
#            @results['summonArticles'].each do |result|
#              result.link = 'http://encompass.library.cornell.edu/cgi-bin/checkIP.cgi?access=gateway_standard%26url=' + result.link unless result.link.nil?
#            end
#          end

          # Merge the newly generated, format-specific results with any other results (e.g., from
          # Summon or web search), then remove the original single-query result.
#          @results.merge!(faceted_results).except! 'solr'

#          unless @results['bestbet'].nil? or @results['bestbet'][0].nil?
#            @best_bets = [{'title' => @results['bestbet'][0].title, 'link' => @results['bestbet'][0].link}]
#          end

#          display_type = params['fixedPanes'].nil? ? 'dynamic' : 'fixed'
#          @fixed_panes = display_type == 'fixed' ? true : false
#          @top_4_results, @secondary_results, @more_results = sort_panes @results.except!('bestbet') , display_type, @scores
#      end
      if session[:search].nil?
  session[:search] = {}
      end
      session[:search][:q] = @query
      session[:search][:search_field] = 'all_fields'
      session[:search][:controller] = 'search'
      session[:search][:action] = 'index'
      # session[:search][:counter] = ?
      # session[:search][:total] = ?

#      Rails.logger.warn "mjc12test: session(ss): #{session[:search]}"
      render 'advanced_search/index'
  end
end

 def set_return_path
    Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__}  params = #{params.inspect}")
    op = request.original_fullpath
    Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__}  original = #{op.inspect}")
    refp = request.referer
    Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__}  referer path = #{refp}")
    session[:cuwebauth_return_path] =
      if (params['id'].present? && params['id'].include?('|'))
        '/bookmarks'
      elsif (params['id'].present? && op.include?('email'))
        "/catalog/afemail/#{params[:id]}"
      elsif (params['id'].present? && op.include?('unapi'))
         refp
      else
        op
      end
    Rails.logger.info("es287_debug #{__FILE__}:#{__LINE__}  return path = #{session[:cuwebauth_return_path]}")
    return true
  end


end

