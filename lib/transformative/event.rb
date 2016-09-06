module Transformative
  module PostTypes
    class Event
      include Post

      PROPERTIES = %i( name summary start end duration description url category
      location ).freeze
      PROPERTIES.each { |p| attr_accessor p }

    end
  end
end
