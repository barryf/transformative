module Transformative
  class Cite < Post

    PROPERTIES = %i( name published author url accessed content ).freeze
    PROPERTIES.each { |p| attr_accessor p }

    def valid_properties
      PROPERTIES
    end

    def published
      @published ||= Time.now
      @published.utc.iso8601
    end

    def accessed
      @accessed ||= Time.now
      @accessed.utc.iso8601
    end

  end
end
