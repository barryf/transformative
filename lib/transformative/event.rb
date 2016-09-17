module Transformative
  class Event < Post

    SIMPLE_PROPERTIES = %w( name summary start end duration description url
      location ).freeze
    ARRAY_PROPERTIES = %w( category )
    PROPERTIES = SIMPLE_PROPERTIES + ARRAY_PROPERTIES
    PROPERTIES.each { |p| attr_accessor p }

    def valid_properties
      PROPERTIES
    end

    def simple_properties
      SIMPLE_PROPERTIES
    end

    def array_properties
      ARRAY_PROPERTIES
    end

    def category
      @category || []
    end

  end
end
