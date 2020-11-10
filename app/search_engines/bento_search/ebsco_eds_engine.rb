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

        q = args[:oq].present? ? args[:oq] : args[:query].present? ? args[:query] : nil
        if q.nil?
#******************
save_level = Rails.logger.level; Rails.logger.level = Logger::WARN
Rails.logger.warn "jgr25_log\n#{__method__} #{__LINE__} #{__FILE__}:"
msg = [" #{__method__} ".center(60,'Z')]
msg << "args: " + args.inspect
msg << 'Z' * 60
puts msg.to_yaml
Rails.logger.level = save_level
#*******************
            results.total_items = 0
            return results
        end
        Rails.logger.debug "jgr25log: #{__FILE__} #{__LINE__} query out: #{q}"
        required_hit_count = args[:per_page].present? ? [args[:per_page], 1].max : 1
        per_page = 3;

        sq = {
            query: q,
            page: 0,
            results_per_page: per_page,
            limiters: ['FT1:Y'] # Available in Library Collection
        }

#******************
save_level = Rails.logger.level; Rails.logger.level = Logger::DEBUG
Rails.logger.warn "jgr25_log\n#{__method__} #{__LINE__} #{__FILE__}:"
msg = [" #{__method__} ".center(60,'Z')]
        begin
            response = session.search(sq)
        rescue => e
            msg << "An error of type #{e.class} happened, message is #{e.message}"
        end
msg << 'Z' * 60
puts msg.to_yaml
Rails.logger.level = save_level
#*******************

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
                    limiters: ['FT1:Y'] # Available in Library Collection
                 }

                response = session.search(sq, add_actions: true )

                response.records.each do |rec|

                    links = rec.eds_fulltext_links()
                    next unless links.present?

                    found += 1
                    throw :enough_hits if found > required_hit_count

                    item = BentoSearch::ResultItem.new
                    item.link_is_fulltext = true
                    item.title = rec.eds_title().present? ? rec.eds_title() : I18n.translate("bento_search.eds.record_not_available")
                    item.abstract = rec.eds_abstract()
                    item.unique_id = rec.id
                    authors = rec.eds_authors()
                    authors.each do | author |
                        item.authors << BentoSearch::Author.new(:display => author)
                    end
                    item.link = rec.eds_plink()

                    links.each do | link |

                        if link[:label].include? "Get it! Cornell" # DISCOVERYACCESS-6637
                            item.other_links << BentoSearch::Link.new(
                                :url => link[:url],
                                :rel => (link[:type].downcase.include? "fulltext") ? 'alternate' : nil,
                                :label => link[:label]
                                )
                        end
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

end