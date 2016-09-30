class BentoSearch::BestBetEngine

  include BentoSearch::SearchEngine

  # Next, at a minimum, you need to implement a #search_implementation method,
  # which takes a normalized hash of search instructions as input (see documentation
  # at #normalized_search_arguments), and returns BentoSearch::Results item.
  #
  # The Results object should have #total_items set with total hitcount, and contain
  # BentoSearch::ResultItem objects for each hit in the current page. See individual class
  # documentation for more info.
  def search_implementation(args)

    # 'args' should be a normalized search arguments hash including the following elements:
    # :query, :per_page, :start, :page, :search_field, :sort, :oq
    bento_results = BentoSearch::Results.new
    q = args[:oq].gsub(" ","%20")
    Rails.logger.debug "mjc12test: #{__FILE__} #{__LINE__} url parameter: #{q}"
    best_bet = [] 
    begin 
      best_bet = JSON.load(open("https://bestbets.library.cornell.edu/match/#{q}"))
    rescue Exception => e 
      best_bet = [] 
      result = BentoSearch::ResultItem.new
      Rails.logger.error "Runtime Error: #{__FILE__} #{__LINE__} Error:: #{e.inspect}"
    end
    Rails.logger.debug "mjc12test: #{__FILE__} #{__LINE__} got back: #{best_bet}"
    result = BentoSearch::ResultItem.new

    # Because all our facets are packaged in a single query, we have to treat this as a single result
    # in order to have bento_search process it correctly. We'll split up into different facets
    # once we get back to the controller!

    # If there is a best bet, it should look like this:
    # [{"id"=>1, "name"=>"Oxford English Dictionary", 
    # "url"=>"http://resolver.library.cornell.edu/misc/3862894", 
    # "created_at"=>"2014-02-10T21:22:53.000Z", "updated_at"=>"2014-02-11T21:14:28.000Z"}]
    result.title = best_bet[0]['name'] unless best_bet.empty?
    result.link = best_bet[0]['url']unless best_bet.empty?

    bento_results << result unless best_bet.empty?
    bento_results.total_items = 1 unless best_bet.empty?
    return bento_results

  end


end
