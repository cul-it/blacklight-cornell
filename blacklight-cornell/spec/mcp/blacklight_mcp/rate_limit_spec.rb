# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BlacklightMcp::RateLimit do
  # Each example sets the variables it cares about and puts them back, so the
  # request specs -- which count against the real limit -- see what they expect.
  def with_env(values)
    originals = values.keys.to_h { |key| [key, ENV.fetch(key, nil)] }
    values.each { |key, value| ENV[key] = value }
    yield
  ensure
    originals.each { |key, value| ENV[key] = value }
  end

  describe '.requests' do
    it 'reads MCP_RATE_LIMIT' do
      with_env('MCP_RATE_LIMIT' => '30') { expect(described_class.requests).to eq(30) }
    end

    # A typo in the env file must not turn the limit off or take the endpoint
    # down with it; the default is the safe answer.
    it 'falls back to the default when the value is not a number' do
      with_env('MCP_RATE_LIMIT' => 'lots') do
        expect(described_class.requests).to eq(described_class::DEFAULT_REQUESTS)
      end
    end
  end

  describe '.period' do
    it 'reads MCP_RATE_LIMIT_PERIOD as seconds' do
      with_env('MCP_RATE_LIMIT_PERIOD' => '90') { expect(described_class.period).to eq(90.seconds) }
    end

    it 'falls back to the default when the value is not a number' do
      with_env('MCP_RATE_LIMIT_PERIOD' => 'a minute') do
        expect(described_class.period).to eq(described_class::DEFAULT_PERIOD.seconds)
      end
    end
  end

  describe '.enabled?' do
    it 'is off at zero' do
      with_env('MCP_RATE_LIMIT' => '0') { expect(described_class.enabled?).to be false }
    end
  end

  describe '.build_store' do
    before { allow(Rails.logger).to receive(:info) }

    it 'counts in this process, and says so, when there is no Redis' do
      with_env('REDIS_SESSION_HOST' => nil) do
        expect(described_class.build_store).to be_a(ActiveSupport::Cache::MemoryStore)
      end

      expect(Rails.logger).to have_received(:info).with(a_string_matching(/counted in this process only/))
    end

    it 'counts in Redis, and says so, when REDIS_SESSION_HOST is set' do
      allow(ActiveSupport::Cache::RedisCacheStore).to receive(:new).and_call_original

      with_env('REDIS_SESSION_HOST' => 'redis.example', 'REDIS_SESSION_PORT' => '6380') do
        expect(described_class.build_store).to be_a(ActiveSupport::Cache::RedisCacheStore)
      end

      expect(ActiveSupport::Cache::RedisCacheStore).to have_received(:new)
        .with(hash_including(url: "redis://redis.example:6380/#{described_class::REDIS_DATABASE}",
                             namespace: 'test:mcp-rate-limit'))
      expect(Rails.logger).to have_received(:info).with(a_string_matching(/shared by every task/))
    end

    it 'says the limit is off rather than describing a store' do
      with_env('MCP_RATE_LIMIT' => '0') { described_class.build_store }

      expect(Rails.logger).to have_received(:info).with('[MCP] rate limit off (MCP_RATE_LIMIT=0)')
    end
  end

  # If Redis is down the count is nil and Rails skips the limit. Letting
  # searches through beats refusing every one of them because the counter is.
  describe 'the Redis store when Redis is unreachable' do
    it 'warns and lets the request through instead of raising' do
      allow(Rails.logger).to receive(:warn)

      with_env('REDIS_SESSION_HOST' => '127.0.0.1', 'REDIS_SESSION_PORT' => '1') do
        expect(described_class.redis_store.increment('probe', 1, expires_in: 1.minute)).to be_nil
      end

      expect(Rails.logger).to have_received(:warn)
        .with(a_string_matching(/\A\[MCP\] rate limit store unavailable \(\w+\): \w/)).at_least(:once)
    end
  end
end
