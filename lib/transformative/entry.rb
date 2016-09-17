module Transformative
  class Entry < Post

    SIMPLE_PROPERTIES = %w( name summary content published updated location
      in_reply_to like_of repost_of rsvp photo )
    ARRAY_PROPERTIES = %w( category syndicate_to syndication )
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

    def published
      @published.utc.iso8601 unless @published.nil?
    end

    def updated
      @updated.utc.iso8601 unless @updated.nil?
    end

    def category
      @category || []
    end

    def syndicate_to
      @syndicate_to || []
    end

    def syndication
      @syndication || []
    end

  end
end
