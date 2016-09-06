module Transformative
  class Event < Post

    PROPERTIES = %i( name summary start end duration description url category
      location ).freeze
    PROPERTIES.each { |p| attr_accessor p }

    def valid_properties
      PROPERTIES
    end

    def category
      @category || []
    end

  end
end
