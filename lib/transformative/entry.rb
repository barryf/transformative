module Transformative
  class Entry < Post

    SIMPLE_PROPERTIES = %w( name summary content published updated location
    in_reply_to like_of repost_of rsvp photo )
    ARRAY_PROPERTIES = %w( category syndication )
    PROPERTIES = SIMPLE_PROPERTIES + ARRAY_PROPERTIES
    PROPERTIES.each { |p| attr_accessor p }

    def valid_properties
      PROPERTIES
    end

    def published
      @published.utc.iso8601 unless @published.nil?
    end

    def updated
      @updated.utc.iso8601 unless @updated.nil?
    end

    def category
      @category || []
    end

    def syndication
      @syndication || []
    end

    def create(params)
      SIMPLE_PROPERTIES.each do |property|
        self.send("#{property}=", create_simple_value(property, params))
      end

      ARRAY_PROPERTIES.each do |property|
        self.send("#{property}=", create_array_value(property, params))
      end
    end

  end
end
