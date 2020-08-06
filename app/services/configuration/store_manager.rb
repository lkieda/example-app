# frozen_string_literal: true

module Configuration
  class StoreManager
    def initialize(connection: RedisConnection.configuration_store, logger: Karafka.logger)
      @logger = logger
      @connection = connection
    end

    def configuration_by_start_time
      start_times = connection.keys

      return {} unless start_times.present?

      configurations = connection.mget(start_times).map { |config| JSON.parse(config) }

      Hash[start_times.zip(configurations)]
    end

    def remove_all_configuration
      connection.flushdb
    end

    def set_configuration(configuration, propagation_buffer: 0.seconds, time_now: Time.now.utc)
      start_time = (time_now + propagation_buffer).strftime(Configuration::Constants::TIME_FORMAT)

      logger.info("Config scheduled to take effect at: #{start_time}")

      connection.set(start_time, configuration.to_json)
    end

    private

    attr_accessor :logger, :connection
  end
end
