# frozen_string_literal: true

require 'json'
require 'faraday'
require 'uri'

RSolr::Client.class_eval do
    def connection
        @connection ||= begin
          conn_opts = { request: {} }
          conn_opts[:url] = uri.to_s
          conn_opts[:proxy] = proxy if proxy
          conn_opts[:request][:open_timeout] = options[:open_timeout] if options[:open_timeout]

          if options[:read_timeout] || options[:timeout]
            # read_timeout was being passed to faraday as timeout since Rsolr 2.0,
            # it's now deprecated, just use `timeout` directly.
            conn_opts[:request][:timeout] = options[:timeout] || options[:read_timeout]
          end

          conn_opts[:request][:params_encoder] = Faraday::FlatParamsEncoder
          user = ENV['IR_SOLR_USER']
          password = ENV['IR_SOLR_PAW']
          Faraday.new(conn_opts) do |conn|
            if user && password
              case Faraday::VERSION
              when /^0/
                conn.basic_auth user, password
              when /^1/
                conn.request :basic_auth, user, password
              else
                conn.request :authorization, :basic, user, password
              end
            end

            conn.response :raise_error
            conn.request :retry, max: options[:retry_after_limit], interval: 0.05,
                                 interval_randomness: 0.5, backoff_factor: 2,
                                 exceptions: ['Faraday::Error', 'Timeout::Error'] if options[:retry_503]
            conn.adapter options[:adapter] || Faraday.default_adapter || :net_http
          end
        end
    end
end