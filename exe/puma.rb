# frozen_string_literal: true

workers Integer(ENV.fetch("WEB_CONCURRENCY", 1))
threads_count = Integer(ENV.fetch("RAILS_MAX_THREADS", 2))
threads threads_count, threads_count
preload_app!