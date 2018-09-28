require "cgi"

class SearchController < ApplicationController
  before_filter :heading
  def heading
   @heading='Search'
  end

  def index
      Rails.logger.debug("#{__FILE__}:#{__LINE__} #{@query}")

    #  @catalog_host = get_catalog_host(request.host)
     Appsignal.increment_counter('search_index', 1)

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
          titem = BentoSearch::ResultItem.new
          #searcher = BentoSearch::MultiSearcher.new(:worldcat, :solr, :summon_bento, :web, :bestbet, :summonArticles)
          searcher = BentoSearch::MultiSearcher.new(:worldcat, :solr, :summon_bento, :bestbet, :digitalCollections, :libguides, :summonArticles)
          searcher.search(@query, :oq =>original_query,:per_page => 3)
          @results = searcher.results

          # Reset query to make it show up properly for the user on the results page
          @query = original_query

          # In order to treat multiple formats separately but only run one Solr query to retrieve
          # them all, we have to store the query result in the custom_data object ...
          if  !@results['solr'][0].nil? && @results['solr'][0].custom_data
            facet_results = @results['solr'][0].custom_data
          else
            facet_results = {}
          end
          # ... which then needs some extra massaging to get the data into the proper form
          faceted_results, @scores = facet_solr_results facet_results

          if !@results['summon_bento'].nil?
            @results['summon_bento'].each do |result|
              result.link = 'http://encompass.library.cornell.edu/cgi-bin/checkIP.cgi?access=gateway_standard%26url=' + result.link unless result.link.nil?
            end
          end
          if !@results['summonArticles'].nil?
            @results['summonArticles'].each do |result|
              result.link = 'http://encompass.library.cornell.edu/cgi-bin/checkIP.cgi?access=gateway_standard%26url=' + result.link unless result.link.nil?
            end
          end

          # Merge the newly generated, format-specific results with any other results (e.g., from
          # Summon or web search), then remove the original single-query result.
          @results.merge!(faceted_results).except! 'solr'

          unless @results['bestbet'].nil? or @results['bestbet'][0].nil?
            @best_bets = [{'title' => @results['bestbet'][0].title, 'link' => @results['bestbet'][0].link}]
          end

          display_type = params['fixedPanes'].nil? ? 'dynamic' : 'fixed'
          @fixed_panes = display_type == 'fixed' ? true : false
          @top_4_results, @secondary_results, @more_results = sort_panes @results.except!('bestbet') , display_type, @scores
      end
      if session[:search].nil?
	      session[:search] = {}
      end
      session[:search][:q] = @query
      session[:search][:search_field] = 'all_fields'
      session[:search][:controller] = 'search'
      session[:search][:action] = 'index'
      # session[:search][:counter] = ?
      # session[:search][:total] = ?

      #Rails.logger.warn "mjc12test: session(ss): #{session[:search]}"
      render 'single_search/index'
  end

  def single_search
   Appsignal.increment_counter('single_search_index', 1)
    begin
      @engine = BentoSearch.get_engine(params[:engine])
    rescue BentoSearch::NoSuchEngine => e
      render :status => 404, :text => e.message
      return
    end

    if params[:q]
      args = {}
      args[:query] = params[:q]
      args[:oq] = params[:q]
      args[:page] = params[:page]
      args[:semantic_search_field] = params[:field]
      args[:per_page] = 3
      args[:sort] = params[:sort]
      args[:per_page] = params[:per_page]
      @results = @engine.search(params[:q], args)
    end

    respond_to do |format|
      format.html { render :template => "single_search/single_search" }
      format.atom { render :template => "bento_search/atom_results", :locals => {:atom_results => @results} }
    end
  end

  # Take a set of search results and order them according to how we want them to be displayed.
  # The expected input  is the output of searcher.results, with sets of results keyed by the
  # engine ID, e.g. 'books' => search results, 'summon' => search results, etc.
  #
  # display_type = fixed | dynamic. For a fixed display, the center 4 panes are always the same:
  # summon (articles), books, journals, and databases. These four are put into the top4 array, and the
  # rest are sorted in order of result count (least to greatest) and put into 'secondary'.
  # If display_type = 'dynamic', we do the sorting without removing any elements, and the top 4
  # engines by hit count are put into top4, with the rest going into secondary.
  #
  # Note that this function doesn't do anything special with website results. If they're present in
  # 'results', they're handled like anything else.
  def sort_panes results, display_type, max_scores

    #remove wcl before it tries to sort it and fails
    @wcl = results.delete('worldcat')
    #Rails.logger.debug("#{__FILE__}:#{__LINE__} results=  #{@results.inspect}")
    #Rails.logger.debug("#{__FILE__}:#{__LINE__} requesthost=  #{request.host.inspect}")
  #  @catalog_host = get_catalog_host(request.host)
  #  Rails.logger.debug("#{__FILE__}:#{__LINE__} @catalog_host=  #{@catalog_host.inspect}")
    top1 = top4 = secondary = []

    # Sort formats alphabetically for more results
    more = results.sort_by { |key, result| BentoSearch.get_engine(key).configuration.title }

    # Remove articles and digital collections from top 4 logic
    @summonArticles = results.delete('summonArticles')
    @digitalCollections = results.delete('digitalCollections')
    @libguides = results.delete('libguides')
    # Top 2 are books and articles, regardless of display_type
    top1 << ['summon_bento', results.delete('summon_bento')]
    top4 = top1

    if display_type == 'fixed'
      # Pre-populate top4 with our chosen formats and remove them from the results
      top4 << ['Journal', results.delete('Journal')]
      top4 << ['Database', results.delete('Database')]
    end

    # Sort the remaining format results by total number of hits
    #results = results.sort_by { |key, result| result.total_items.to_i }

    # Sort the remaining format results by max relevancy score
    results = results.sort_by { |key, result| max_scores[key] }
    results = results.reverse


    if display_type == 'dynamic'
      # Take top2 plus the next 2 formats with the highest result counts
      results.to(2).each do |result|
        top4 << result
      end
      secondary = results.from(3)
    else
      # We already took the top four before sorting
      secondary = results
    end

    return top4, secondary, more, @websites, @wcl
  end

  def toggle_display display_type
    sort_panes @results, display_type
  end

  # Return a URL for the 'view all' links. format only matters for Blacklight format facets
  def all_items_url engine_id, query, format


    if engine_id == 'summon_bento'
      query = query.gsub('&', '%26')
      "http://encompass.library.cornell.edu/cgi-bin/checkIP.cgi?access=gateway_standard%26url=http://cornell.summon.serialssolutions.com/search?s.fvf=ContentType,Newspaper+Article,t&s.q=#{query}"
    elsif engine_id == 'summonArticles'
      query = query.gsub('&', '%26')
      "http://encompass.library.cornell.edu/cgi-bin/checkIP.cgi?access=gateway_standard%26url=http://cornell.summon.serialssolutions.com/search?s.fvf=ContentType,Newspaper+Article&s.q=#{query}"
    elsif engine_id == 'digitalCollections'
      query = query.gsub('&', '%26')
      "https://digital.library.cornell.edu/catalog?utf8=%E2%9C%93&q=#{query}&search_field=all_fields"
    elsif engine_id =='libguides'
      query = query.gsub('&', '%26')
      "http://guides.library.cornell.edu/srch.php?q=#{query}"
    else
      # Need to pass pluses through as urlencoded characters in order to preserve
      # the Solr query format.
      #cat_url = Rails.configuration.cornell_catalog
      #cat_url = "http://" + @catalog_host
#      query = ((objectify_query query).gsub('%', '%25')).gsub('+','%2B').gsub('&', '%26')
      query = query.gsub('&', '%26')
      if format == 'all'
        #"#{cat_url}/?q=#{query}"
        "/?q=#{query}"
      else
         query = query.gsub('&','%26')
        #"#{cat_url}/?" + URI::escape("f[format][]=#{format}&")+"q=#{query}&search_field=all_fields"
        "/?" + URI::escape("f[format][]=#{format}&")+"q=#{query}&search_field=all_fields"
        #"/?" + URI::escape("f[format][]=#{format}&")+"q=#{query}"
      end
    end
  end

  # In order to trick bento_search into thinking that our results from our single Solr query are
  # a group of results for different item formats, we have to take an extra step here to parse out
  # the one result from the Solr query into the different formats and create a BentoSearch:: Results
  # object for each one.
  #
  # Also sort the results by max relevancy
  def facet_solr_results unfaceted_results

    groups = unfaceted_results
    max_relevancy_scores = {}
    output = {}


    groups.each do |g|
      # Each group is a format, e.g., Book
      bento_set = BentoSearch::Results.new
      bento_set.total_items = g['doclist']['numFound']
      docs = g['doclist']['docs']
      # Iterate through each book search result and create a ResultItem for it.
      docs.each do |d|

        item = BentoSearch::ResultItem.new
        if d['fulltitle_vern_display'].present?
          item.title = d['fulltitle_vern_display'] + ' / ' + d['fulltitle_display']
        else
          item.title = d['fulltitle_display']
        end
        [d['author_display']].each do |a|
          next if a.nil?
          # author_display comes in as a combined name and date with a pipe-delimited display name.
          # bento_search does some slightly odd things to author strings in order to display them,
          # so the raw string coming out of *our* display value turns into nonsense by default
          # Telling to create a new Author with an explicit 'display' value seems to work.
          item.authors << BentoSearch::Author.new({:display => a})
        end
        if d['pub_info_display']
          item.publisher = d['pub_info_display'][0]
        end
        if d['pub_date_display']
          item.year = d['pub_date_display'][0].to_s
          item.year.tr!('[]','')
        end
        #item.link = "http://" + @catalog_host + "/catalog/#{d['id']}"
        item.unique_id = "#{d['id']}"
        item.link = "/catalog/#{d['id']}"
          item.custom_data = {
            'url_online_access' => d['url_access_display'],
            'availability_json' => d['availability_json'],
          }
        
        item.format = d['format']
        bento_set << item

        # The first search result should have the maximum relevancy score. Save this for later
        max_relevancy_scores[g['groupValue']] ||= d['score']
      end

      output[g['groupValue']] = bento_set
    end

    return output, max_relevancy_scores

  end

  #
  # def get_catalog_host req_host
  #   ch  = Rails.configuration.cornell_catalog
  #   # for hosts like "es287-dev"
  #   if (/.*-dev/).match(req_host)
  #      ch  = req_host.gsub(/.*-dev/,"newcatalog-int");
  #   end
  #   if (/search.*/).match(req_host)
  #      ch  = req_host.gsub(/search/,"newcatalog");
  #   end
  #   Rails.logger.debug("#{__FILE__}:#{__LINE__} #{ch}")
  #   return ch
  # end

  # Modify query for improved Solr search (and to match Blacklight changes) (DISCOVERYACCESS-1103)
  def objectify_query search_query

    # Don't do anything for already-quoted queries or single-term queries
    if search_query !~ /[\"\'].*?[\"\']/ and
        search_query !~/[AND|OR|NOT]/ and
        search_query =~ /\w.+?\s\w.+?/
      # create modified query: (+x +y +z) OR "x y z"
      new_query = search_query.split.map {|w| "+#{w}"}.join(' ')
      # (have to use double quotes; single returns an incorrect result set from Solr!)
      "(#{new_query}) OR phrase:\"#{search_query}\""
    else
      search_query
    end
  end

  # Modify query for improved Solr search (and to match Blacklight changes) (DISCOVERYACCESS-1103)
  def self.transform_query search_query
    # Don't do anything for already-quoted queries or single-term queries
    if search_query !~ /[\"\'].*?[\"\']/ and
        search_query !~ /AND|OR|NOT/
        #search_query =~ /\w.+?\s\w.+?/
      # create modified query: (+x +y +z) OR "x y z"
      new_query = search_query.split.map {|w| "+#{w}"}.join(' ')
      # (have to use double quotes; single returns an incorrect result set from Solr!)
      "(#{new_query}) OR phrase:\"#{search_query}\""
    else
      if search_query.first == "'" and search_query.last == "'"
        search_query = search_query.gsub("'","")
        search_query = "(#{search_query}) OR phrase:\"#{search_query}\""
      end
      search_query
    end
  end
end
