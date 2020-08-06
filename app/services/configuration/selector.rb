module Configuration
  class Selector
    def initialize(time_format: StoreManager::Constants::TIME_FORMAT)
      @time_format = time_format
    end

    def select(configuration_by_time, at_time: Time.now.utc)

      time_string = at_time.strftime(time_format)

      start_times = configuration_by_time.keys
      most_recent = start_times.sort.select{|start_time| start_time <= time_string}.last

      result = configuration_by_time[most_recent]

      result
    end

    private

    attr_accessor :time_format
  end
end
