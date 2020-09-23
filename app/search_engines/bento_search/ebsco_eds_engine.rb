# encoding: utf-8

require 'nokogiri'

require 'http_client_patch/include_client'
require 'httpclient'

class BentoSearch::EbscoEdsEngine
    include BentoSearch::SearchEngine

    # Can't change http timeout in config, because we keep an http
    # client at class-wide level, and config is not class-wide.
    # Change this 'constant' if you want to change it, I guess.
    #
    # In some tests we did, 5.2s was 95th percentile slowest, but in
    # actual percentage 5.2s is still timing out way too many requests,
    # let's try 6.3, why not.
    HttpTimeout = 6.3
    extend HTTPClientPatch::IncludeClient
    include_http_client do |client|
        client.connect_timeout = client.send_timeout = client.receive_timeout = HttpTimeout
    end

    def limiter_test(session)
        q = "cancel culture"
        start = 0
        per_page = 3
        sqs = [
            {query: q, page: start, results_per_page: per_page},
            {query: q, page: start, results_per_page: per_page, limiters: ['FT1:Y']},
            {query: q, page: start, results_per_page: per_page, limiters: ['FT1:Y', 'FT:Y']},
            {query: q, page: start, results_per_page: per_page, limiters: ['FT1:Y', 'FT:Y', 'RV:Y']}
        ]
         sqs.each do |sq|
            msg = ['******************']
            response = session.search(sq)
            msg << 'sq: ' + sq.inspect
            msg << 'total_hits: ' + response.stat_total_hits.to_s
            applied_limiters = response.applied_limiters.map{|hash| hash['Id']}
            msg << 'limiters: ' + response.applied_limiters.inspect
            response.records.each do |rec|
                msg << rec.eds_title().to_s
            end
            msg << '******************'
            puts msg.to_yaml
        end
    end

    def search_implementation(args)

        session = EBSCO::EDS::Session.new({
            :debug => true,
            :log => 'eds-connection.log',
            :user => ENV['EDS_USER'],
            :pass => ENV['EDS_PASS'],
            :guest => true,
            :profile => ENV['EDS_PROFILE']
        })

        results = BentoSearch::Results.new
        xml, response, exception = nil, nil, nil

        limiter_test(session)

        # q = args[:query]
        q = args[:oq]
        Rails.logger.debug "jgr25log: #{__FILE__} #{__LINE__} query out: #{q}"
        required_hit_count = args[:per_page].present? ? [args[:per_page], 1].max : 1
        per_page = 3;

        sq = {
            'q' => q,
            'start' => 0,
            'per_page' => per_page
        }

        response = session.search(sq)
        total_hits = response.stat_total_hits

        results.total_items = total_hits.to_i

        catch :enough_hits do
            found = 0
            page = 0
            max_page = (total_hits / per_page).ceil
            for page in 0..max_page

                sq = {
                    query: q,
                    page: page,
                    results_per_page: per_page,
                    limiters: ['FT:Y', 'RV:Y']
                 }

                session.add_limiter('FT', 'Y')
                session.add_limiter('FT1', 'Y')

                response = session.search(sq, add_actions: true )

                response.records.each do |rec|
                    # access_level = rec.eds_access_level()
                    # puts "access_level: " + access_level.inspect
                    # next if access_level.to_i < 2

#******************
save_level = Rails.logger.level; Rails.logger.level = Logger::WARN
Rails.logger.warn "jgr25_log\n#{__method__} #{__LINE__} #{__FILE__}:"
msg = ["****************** #{__method__}"]
access_level = rec.eds_access_level()
msg << "access_level: " + access_level.inspect
msg << "rec isbns: " + rec.eds_isbns().inspect
msg << "Search modes: " + session.info.available_search_modes().inspect
msg << "Limiter Labels: " + session.info.available_limiter_labels().inspect
applied_limiters = response.applied_limiters.map{|hash| hash['Id']}
msg << 'applied: ' + applied_limiters.inspect
msg << "Limiters: " + response.applied_limiters().inspect
msg << "Search: " + @SearchCriteria.inspect
msg << '******************'
puts msg.to_yaml
# Rails.logger.level = save_level
#*******************
                found += 1
                    throw :enough_hits if found > required_hit_count

                    item = BentoSearch::ResultItem.new
                    item.title = rec.eds_title().present? ? rec.eds_title() : I18n.translate("bento_search.eds.record_not_available")
                    item.abstract = rec.eds_abstract()
                    item.unique_id = rec.id
                    authors = rec.eds_authors()
                    authors.each do | author |
                        item.authors << BentoSearch::Author.new(:display => author)
                    end
                    item.link = rec.eds_plink()
                    links = rec.eds_fulltext_links()
                    if links.present?
                        item.link_is_fulltext = true
                    else
                        links = rec.eds_all_links()
                    end

                    links.each do | link |
                        item.other_links << BentoSearch::Link.new(
                            :url => link[:url],
                            :rel => (link[:type].downcase.include? "fulltext") ? 'alternate' : nil,
                            :label => link[:label]
                            )
                    end

                    rec.eds_isbns().each do | isbn |
                        item.other_links << BentoSearch::Link.new(
                            :url => 'https://isbnsearch.org/isbn/' + isbn,
                            :label => 'ISBN'
                        )
                    end
                    item.format_str = rec.eds_publication_type()
                    item.doi = rec.eds_document_doi()
                    if rec.eds_page_start().present?
                        item.start_page = rec.eds_page_start().to_s
                        if rec.eds_page_count().present?
                            item.end_page = (rec.eds_page_start().to_i + rec.eds_page_count().to_i - 1).to_s
                        end
                    end
                    date = rec.eds_publication_date
                    ymd = date.split('-').map(&:to_i)
                    item.publication_date = Date.new(ymd[0], ymd[1], ymd[2])
                    results << item
                end
            end
        end # enough hits already
        Rails.logger.debug "jgr25log: #{__FILE__} #{__LINE__} results: " + results.inspect
        return results
    end

end