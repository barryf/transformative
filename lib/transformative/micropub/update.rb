module Transformative
  module Micropub
    module Update
      module_function

      def replace(post, properties)
        properties.each do |property|
          post.replace_property(property[0], property[1])
        end
        post
      end
    
      def add(post, properties)
        properties.each do |property|
          post.add_property(property[0], property[1])
        end
        post
      end
    
      def remove(post, properties)
        properties.each do |property|
          post.remove_property(property[0], property[1])
        end
        post
      end
      
    end
  end
end