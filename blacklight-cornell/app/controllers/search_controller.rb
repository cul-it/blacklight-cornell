require "cgi"

class SearchController < ApplicationController
  include LoggingHelper

  before_action :heading

  def heading
    @heading = "Search"
  end

  def index
    Rails.logger.debug("#{__FILE__}:#{__LINE__} #{@query}")

    #  @catalog_host = get_catalog_host(request.host)
    Appsignal.increment_counter("search_index", 1)

    unless params["q"].nil?
      @query = params["q"]
      @query.slice! "doi:"

      Rails.logger.debug("#{__FILE__}:#{__LINE__} #{@query}")
      searcher = BentoSearch::ConcurrentSearcher.new(:solr, :ebsco_eds, :bestbet, :digitalCollections, :libguides, :institutionalRepositories)
      searcher.search(@query, :per_page => 3)
      @results = searcher.results.dup

      # In order to treat multiple formats separately but only run one Solr query to retrieve
      # them all, we have to store the query result in the custom_data object ...
      if !@results["solr"][0].nil? && @results["solr"][0].custom_data
        facet_results = @results["solr"][0].custom_data
      else
        facet_results = {}
      end

      # ... which then needs some extra massaging to get the data into the proper form
      faceted_results, @scores = facet_solr_results facet_results

      # Merge the newly generated, format-specific results with any other results (e.g., from
      # Summon or web search), then remove the original single-query result.
      @results.merge!(faceted_results).except! "solr"

      unless @results["bestbet"].nil? or @results["bestbet"][0].nil?
        @best_bets = [{ "title" => @results["bestbet"][0].title, "link" => @results["bestbet"][0].link }]
      end

      display_type = params["fixedPanes"].nil? ? "dynamic" : "fixed"
      @fixed_panes = display_type == "fixed" ? true : false
      @top_4_results, @secondary_results, @more_results = sort_panes @results.except!("bestbet"), display_type, @scores
    end
    if session[:search].nil?
      session[:search] = {}
    end
    session[:search][:q] = @query
    session[:search][:search_field] = "all_fields"
    session[:search][:controller] = "search"
    session[:search][:action] = "index"

    render "single_search/index"
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
  def sort_panes(results, display_type, max_scores)
    top1 = top4 = secondary = []

    # Sort formats alphabetically for more results
    more = results.sort_by { |key, result| helpers.bento_title(key) }

    # Remove articles and digital collections from top 4 logic
    @digitalCollections = results.delete("digitalCollections")
    @institutionalRepositories = results.delete("institutionalRepositories")
    @libguides = results.delete("libguides")
    # Top 2 are books and articles, regardless of display_type
    top1 << ["ebsco_eds", results.delete("ebsco_eds")]
    top4 = top1

    if display_type == "fixed"
      # Pre-populate top4 with our chosen formats and remove them from the results
      top4 << ["Journal/Periodical", results.delete("Journal/Periodical")]
      top4 << ["Database", results.delete("Database")]
    end

    # Sort the remaining format results by total number of hits
    #results = results.sort_by { |key, result| result.total_items.to_i }

    # Sort the remaining format results by max relevancy score
    results = results.sort_by { |key, result| max_scores[key] }
    results = results.reverse

    if display_type == "dynamic"
      # Take top2 plus the next 2 formats with the highest result counts
      results.to(2).each do |result|
        top4 << result
      end
      secondary = results.from(3)
    else
      # We already took the top four before sorting
      secondary = results
    end

    return top4, secondary, more, @websites
  end

  def toggle_display(display_type)
    sort_panes @results, display_type
  end

  # Return a URL for the 'view all' links. format only matters for Blacklight format facets
  def all_items_url(engine_id, query, format)
    if engine_id == "digitalCollections"
      query = query.gsub("&", "%26")
      "https://digital.library.cornell.edu/catalog?utf8=%E2%9C%93&q=#{query}&search_field=all_fields"
    elsif engine_id == "institutionalRepositories"
      query = query.gsub("&", "%26")
      "institutional_repositories/index?q=#{query}"
    elsif engine_id == "libguides"
      query = query.gsub("&", "%26")
      "http://guides.library.cornell.edu/srch.php?q=#{query}"
    elsif engine_id == "ebsco_eds"
      query = query.gsub("&", "%26")
      query = "https://discovery.ebsco.com/c/u2yil2/results?q=#{query}"
    else
      # Need to pass pluses through as urlencoded characters in order to preserve
      # the Solr query format.
      path = "/"
      if format == "all"
        escaped = { q: query }.to_param
      else
        escaped = { "f[format][]" => format, q: query, search_field: "all_fields" }.to_param
      end
      escaped_search_url = path + "?" + escaped
    end
  end

  # In order to trick bento_search into thinking that our results from our single Solr query are
  # a group of results for different item formats, we have to take an extra step here to parse out
  # the one result from the Solr query into the different formats and create a BentoSearch:: Results
  # object for each one.
  #
  # Also sort the results by max relevancy
  def facet_solr_results(unfaceted_results)
    groups = unfaceted_results
    max_relevancy_scores = {}
    output = {}

    groups.each do |g|
      # Each group is a format, e.g., Book
      bento_set = BentoSearch::Results.new
      bento_set.total_items = g["doclist"]["numFound"]
      docs = g["doclist"]["docs"]
      # Iterate through each book search result and create a ResultItem for it.
      docs.each do |d|
        item = BentoSearch::ResultItem.new
        if d["fulltitle_vern_display"].present?
          item.title = d["fulltitle_vern_display"] + " / " + d["fulltitle_display"]
        else
          item.title = d["fulltitle_display"]
        end
        [d["author_display"]].each do |a|
          next if a.nil?
          # author_display comes in as a combined name and date with a pipe-delimited display name.
          # bento_search does some slightly odd things to author strings in order to display them,
          # so the raw string coming out of *our* display value turns into nonsense by default
          # Telling to create a new Author with an explicit 'display' value seems to work.
          item.authors << BentoSearch::Author.new({ :display => a })
        end
        if d["pub_info_display"]
          item.publisher = d["pub_info_display"][0]
        end
        if d["pub_date_display"]
          item.year = d["pub_date_display"][0].to_s
          item.year.tr!("[]", "")
        end
        #item.link = "http://" + @catalog_host + "/catalog/#{d['id']}"
        item.unique_id = "#{d["id"]}"
        item.link = "/catalog/#{d["id"]}"
        item.custom_data = {
          "url_online_access" => helpers.access_url_single(d),
          "availability_json" => d["availability_json"],
        }

        item.format = d["format"]
        bento_set << item

        # The first search result should have the maximum relevancy score. Save this for later
        max_relevancy_scores[g["groupValue"]] ||= d["score"]
      end

      output[g["groupValue"]] = bento_set
    end

    return output, max_relevancy_scores
  end
end
