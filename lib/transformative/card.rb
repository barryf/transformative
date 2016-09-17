module Transformative
  class Card < Post

    PROPERTIES = %i( name photo url email ).freeze
    PROPERTIES.each { |p| attr_accessor p }

    def valid_properties
      PROPERTIES
    end
    def simple_properties
      PROPERTIES
    end
    def array_properties
      []
    end

  end
end
