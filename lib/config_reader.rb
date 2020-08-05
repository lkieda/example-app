# frozen_string_literal: true

class ConfigReader
  class << self
    def redis_config
      @redis_config ||= load_yaml('redis.yml').fetch(Karafka::App.env)
    end

    private

    def load_yaml(file_name)
      YAML.load(
        ERB.new(
          File.read(
            File.join(Karafka::App.root, 'config', file_name)
          )
        ).result
      )
    end
  end
end
