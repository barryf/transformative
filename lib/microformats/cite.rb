module Microformats
  class Cite < Base

    PROPERTIES = %w( name published author url accessed content )
    PROPERTIES.each { |p| attr_accessor p }

    def self.valid_properties
      PROPERTIES
    end

    def self.simple_properties
      PROPERTIES
    end

    def self.array_properties
      []
    end

    def published
      @published.utc.iso8601 unless @published.nil?
    end

    def accessed
      @accessed.utc.iso8601 unless @accessed.nil?
    end

  end
end
