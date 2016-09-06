module Transformative
  class Card < Post

    PROPERTIES = %i( name photo url email ).freeze
    PROPERTIES.each { |p| attr_accessor p }

    def valid_properties
      PROPERTIES
    end

  end
end
