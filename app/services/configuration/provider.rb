# frozen_string_literal: true

module Configuration
  class Provider
    def initialize(store_repository: Configuration::StoreRepository.new, selector: Configuration::Selector.new)
      @store_repository = store_repository
      @selector = selector
    end

    def provide
      configuration_by_time = store_repository.configuration_by_start_time

      return nil unless configuration_by_time.present?

      selector.select(configuration_by_time)
    end

    private

    attr_accessor :config, :store_repository, :selector
  end
end
