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
        # results = BentoSearch::Results.new

        results = BentoSearch::Results.new
        xml, response, exception = nil, nil, nil

        session = EBSCO::EDS::Session.new({
            :user => ENV['EDS_USER'],
            :pass => ENV['EDS_PASSWORD'],
            :profile => ENV['EDS_PROFILE']
        })

        q = args[:query]

        # results = []

        # results = session.simple_search(args[:query])

#******************
save_level = Rails.logger.level; Rails.logger.level = Logger::WARN
Rails.logger.warn "jgr25_log\n#{__method__} #{__LINE__} #{__FILE__}:"
msg = ["****************** #{__method__}"]
msg << "args: " + args.inspect
msg << "q: " + q.inspect
msg << "session: " + session.inspect
msg << '******************'
puts msg.to_yaml
Rails.logger.level = save_level
#*******************

    end

end