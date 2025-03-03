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

    def search_implementation(args)

        session = EBSCO::EDS::Session.new({
            :user => ENV['EDS_USER'],
            :pass => ENV['EDS_PASS'],
            :guest => false,
            :profile => ENV['EDS_PROFILE']
        })

        results = BentoSearch::Results.new
        xml, response, exception = nil, nil, nil

        q = args[:query]
        if q.nil?
            results.total_items = 0
            return results
        end
        required_hit_count = args[:per_page].present? ? [args[:per_page], 1].max : 1
        per_page = 3

        sq = {
            query: q,
            page: 0,
            results_per_page: per_page,
            limiters: ['FT1:Y'] # Available in Library Collection
        }

        response = session.search(sq)
        total_hits = response.stat_total_hits
        total_tested_hits = [response.stat_total_hits.to_i, 100].min

        results.total_items = total_hits.to_i

        catch :enough_hits do
            found = 0
            page = 0
            max_page = (total_tested_hits / per_page).ceil
            for page in 0..max_page

                sq = {
                    query: q,
                    page: page,
                    results_per_page: per_page,
                    limiters: ['FT1:Y'] # Available in Library Collection
                 }

                response = session.search(sq, add_actions: true )

                response.records.each do |rec|
                    links = rec.eds_fulltext_links()
                    next unless links.present?

                    # inaccessible items creap in unless we require a 'Full Text' link
                    found_get_it = false
                    links.each do | link |
                        if link[:label].downcase.include? "full text"
                            found_get_it = true
                            break
                        end
                    end
                    next unless found_get_it

                    # duplicates creep in unless
                    found_already = false
                    results.each do | check |
                        if check.unique_id == rec.id
                            found_already = true
                            break
                        end
                    end
                    next if found_already

                    found += 1
                    throw :enough_hits if found > required_hit_count

                    item = BentoSearch::ResultItem.new
                    item.link_is_fulltext = true

                    item.title = rec.eds_title().present? ? rec.eds_title() : I18n.translate("bento_search.eds.record_not_available")
                    item.title = prepare_ebsco_eds_payload(item.title, true)

                    item.abstract = rec.eds_abstract()
                    item.abstract = prepare_ebsco_eds_payload(item.abstract, true)

                    item.unique_id = rec.id
                    authors = rec.eds_authors()
                    authors.each do | author |
                        item.authors << BentoSearch::Author.new(:display => author)
                    end
                    item.link = rec.eds_plink()

                    item.format_str = rec.eds_publication_type()
                    item.doi = rec.eds_document_doi()
                    if rec.eds_page_start().present?
                        item.start_page = rec.eds_page_start().to_s
                        if rec.eds_page_count().present?
                            item.end_page = (rec.eds_page_start().to_i + rec.eds_page_count().to_i - 1).to_s
                        end
                    end
                    date = rec.eds_publication_date
                    if date.present?
                        ymd = date.split('-').map(&:to_i)
                        item.publication_date = Date.new(ymd[0], ymd[1], ymd[2])
                    end
                    results << item
                end
            end
        end # enough hits already
        return results
    end

    # DISCOVERYACCESS-6854 - sometimes hilight text comes with
    # unescaped characers even if configuration.highlighting == false
    # If EDS has put highlighting tags
    # in a field, we need to HTML escape the literal values,
    # while still using the highlighting tokens to put
    # HTML tags around highlighted terms.
    #
    # Second param, if to assume EDS literals are safe HTML, as they
    # seem to be.
    def prepare_ebsco_eds_payload(str, html_safe = false)

        str = HTMLEntities.new.decode str

        if str.present?
            if configuration.highlighting
                str.gsub!(/\<highlight\>/,"<b class='bento_search_highlight'>")
                str.gsub!(/\<\/hilight\>/,"</b>")
            else
                str = str.html_safe if html_safe
            end
        end
    end

end