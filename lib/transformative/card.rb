module Transformative
  module PostTypes
    class Card
      include Post

      PROPERTIES = %i( name photo url email ).freeze
      PROPERTIES.each { |p| attr_accessor p }

    end
  end
end
