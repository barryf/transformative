module Transformative
  module Redis
    module_function

    def client
      raise "No REDIS_URL environment variable was found." unless ENV.key?('REDIS_URL')
      @client ||= ::Redis.new(url: ENV['REDIS_URL'])
    end

    def set(key, value)
      json = value.to_json
      client.set(key, json)
    end

    def get(key)
      data = client.get(key)
      return unless data
      begin
        JSON.parse(data)
      rescue JSON::ParserError
      end
    end

    def expire(key, seconds)
      client.expire(key, seconds)
    end

  end
end