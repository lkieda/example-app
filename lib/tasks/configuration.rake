# frozen_string_literal: true

namespace :configuration do
  desc 'Saves default configuration to the store'
  task :default do
    Configuration::StoreRepository.new.set_configuration(Configuration::Constants::DEFAULT_CONFIGURATION)
  end

  desc 'Updates the store with new configuration'
  task :update do
    configuration = { include_mood: true, delay: 5 }
    Configuration::StoreRepository.new.set_configuration(configuration, propagation_buffer: 5.seconds)
  end

  desc 'Removes everything from configuration store'
  task :clear do
    RedisConnection.configuration_store.flushdb
  end
end
