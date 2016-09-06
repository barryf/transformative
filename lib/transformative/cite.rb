module Transformative
  module PostTypes
    class Cite
      include Post

      PROPERTIES = %i( name published author url accessed content ).freeze
      PROPERTIES.each { |p| attr_accessor p }

    end
  end
end
