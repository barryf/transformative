module Microformats
  class Event < Base

    SIMPLE_PROPERTIES = %w( name summary start end duration description url
      location )
    ARRAY_PROPERTIES = %w( category syndication )
    PROPERTIES = SIMPLE_PROPERTIES + ARRAY_PROPERTIES
    PROPERTIES.each { |p| attr_accessor p }

    def self.valid_properties
      PROPERTIES
    end

    def self.simple_properties
      SIMPLE_PROPERTIES
    end

    def self.array_properties
      ARRAY_PROPERTIES
    end

  end
end
