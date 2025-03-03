class BentoSearch::InstitutionalRepositoriesEngine

  include BentoSearch::SearchEngine
  include InstitutionalRepositoriesHelper

  # Next, at a minimum, you need to implement a #search_implementation method,
  # which takes a normalized hash of search instructions as input (see documentation
  # at #normalized_search_arguments), and returns BentoSearch::Results item.
  #
  # The Results object should have #total_items set with total hitcount, and contain
  # BentoSearch::ResultItem objects for each hit in the current page. See individual class
  # documentation for more info.
  def search_implementation(args)

    # 'args' should be a normalized search arguments hash including the following elements:
    # :query, :per_page, :start, :page, :search_field, :sort
    bento_results = BentoSearch::Results.new

    # Format is passed to the engine using the configuration set up in the bento_search initializer
    # If not specified, we can maybe default to books for now.
    format = configuration[:blacklight_format] || 'Institutional Repositories'

    qp = { q: args[:query] }.to_param
    # q = URI::encode(args[:oq].gsub(" ","+"))
    q = qp[2..-1]

    uri = get_solr_url(args)
    url = Addressable::URI.parse(uri)
    url.normalize

    start = args[:page].is_a?(Integer) ? args[:page] - 1 : 0
    per_page = args[:per_page].is_a?(Integer) ? args[:per_page] : 5

    fq = set_fq()

    solr = RSolr.connect :url => url.to_s
    solr_response = solr.get 'select', :params => {
                                        :q => q,
                                        :fq => fq,
                                        :start => start * per_page,
                                        :rows => per_page,
                                        :fl => '*',
                                        :defType => 'edismax'
                                       }

    results = solr_response['response']['docs']

    results.each do |i|
      item = BentoSearch::ResultItem.new

      item = solrResult2Bento(i, item)

      bento_results << item
    end
    bento_results.total_items = solr_response['response']['numFound']

    return bento_results
  end

  def get_solr_url(args)
    # see config/initializers/solr_connect.rb
    solr_url = ENV['IR_SOLR_URL']
    return solr_url
  end

end
