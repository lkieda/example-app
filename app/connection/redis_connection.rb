# frozen_string_literal: true

class RedisConnection
  SIDEKIQ = 'sidekiq'
  CONFIGURATION_STORE = 'configuration_store'

  class << self
    def sidekiq_redis_url
      @sidekiq_redis_url ||= redis_url(SIDEKIQ)
    end

    def configuration_store
      @configuration_store ||= redis_client(CONFIGURATION_STORE)
    end

    private

    def redis_client(service)
      ::Redis.new(url: redis_url(service))
    end

    def redis_url(service)
      redis = ConfigReader.redis_config
      "redis://#{redis['host']}:#{redis['port']}/#{redis['databases'][service]}"
    end
  end
end
