# frozen_string_literal: true

module Configuration
  class Provider
    def initialize(store_manager: Configuration::StoreManager.new, selector: Configuration::Selector.new)
      @store_manager = store_manager
      @selector = selector
    end

    def provide
      configuration_by_time = store_manager.configuration_by_start_time

      return nil unless configuration_by_time.present?

      selector.select(configuration_by_time)
    end

    private

    attr_accessor :config, :store_manager, :selector
  end
end
