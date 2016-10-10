module Microformats
  class Card < Base

    PROPERTIES = %w( name photo url email )
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

  end
end
