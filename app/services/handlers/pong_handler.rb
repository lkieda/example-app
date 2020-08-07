# frozen_string_literal: true

module Handlers
  class PongHandler
    def initialize(config_provider: Configuration::Provider.new, logger: Karafka.logger)
      @config_provider = config_provider
      @logger = logger
    end

    def handle(params_batch)
      config = config_provider.provide

      raise Errors::MissingConfigurationError if config.nil?

      logger.info "PongHandler using configuration: #{config.inspect}"

      handle_using_config(params_batch, config)
    end

    private

    def handle_using_config(params_batch, config)
      counter = params_batch.last.payload['counter'] + 1

      output = { 'counter' => counter }
      output.merge!({ 'mood' => ':)' }) if config['include_mood']

      sleep config['delay'] if config['delay'].present?

      output
    end

    attr_accessor :config_provider, :logger
  end
end
