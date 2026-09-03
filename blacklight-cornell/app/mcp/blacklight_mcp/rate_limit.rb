# frozen_string_literal: true

module BlacklightMcp
  # How often one caller may hit /mcp.
  #
  # The endpoint is public and needs no login, so without this anyone who finds
  # the URL can run searches against Solr as fast as they can send them.
  #
  # Tune it with two environment variables. Set MCP_RATE_LIMIT=0 to turn it off.
  #
  #   MCP_RATE_LIMIT=120         requests allowed per caller
  #   MCP_RATE_LIMIT_PERIOD=60   seconds those requests are counted over
  #
  # The default is far more than a person talking to an assistant will ever use
  # -- connecting costs about ten requests, and a search is one -- while still
  # capping a runaway client at two requests a second.
  module RateLimit
    DEFAULT_REQUESTS = 120
    DEFAULT_PERIOD = 60

    # Sessions use database 2 on the same server (config/initializers/
    # session_store.rb); this uses its own so the two can't collide.
    REDIS_DATABASE = 3

    module_function

    def requests
      Integer(ENV.fetch('MCP_RATE_LIMIT', DEFAULT_REQUESTS))
    rescue ArgumentError, TypeError
      DEFAULT_REQUESTS
    end

    def period
      Integer(ENV.fetch('MCP_RATE_LIMIT_PERIOD', DEFAULT_PERIOD)).seconds
    rescue ArgumentError, TypeError
      DEFAULT_PERIOD.seconds
    end

    def enabled?
      requests.positive?
    end

    # Deliberately not Rails.cache. This app leaves cache_store unset in every
    # deployed environment, so Rails.cache is per process: on ECS each task would
    # count separately and the real limit would be however many tasks are running.
    # In the test environment it is :null_store, where a limit can never trigger
    # at all.
    #
    # Shared Redis keeps one count for every task. Without Redis it falls back to
    # a per-process count, which still stops a single runaway client but is not a
    # shared limit -- see #shared?.
    def store
      @store ||= redis_host.present? ? redis_store : ActiveSupport::Cache::MemoryStore.new
    end

    # True when every task is counting against the same total.
    def shared?
      redis_host.present?
    end

    def redis_host
      ENV['REDIS_SESSION_HOST']
    end

    def redis_store
      ActiveSupport::Cache::RedisCacheStore.new(
        url: "redis://#{redis_host}:#{ENV.fetch('REDIS_SESSION_PORT', 6379)}/#{REDIS_DATABASE}",
        namespace: "#{Rails.env}:mcp-rate-limit",
        # If Redis is unreachable, increment returns nil and Rails skips the
        # limit. Letting searches through beats refusing them all because the
        # counter is down.
        error_handler: lambda { |method:, returning:, exception:|
          Rails.logger.warn("[MCP] rate limit store unavailable (#{method}): #{exception.class}")
        }
      )
    end
  end
end
