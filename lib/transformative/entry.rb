module Transformative
  class Entry < Post

    PROPERTIES = %i( name summary content published updated category location
      syndication in_reply_to like_of repost_of rsvp photo )
    PROPERTIES.each { |p| attr_accessor p }

    STATUSES = %i( live draft deleted )
    attr_accessor :status

    def valid_properties
      PROPERTIES.freeze
    end

    def published
      @published ||= Time.now
      @published.utc.iso8601
    end

    def updated
      @updated ||= Time.now
      @updated.utc.iso8601
    end

    def category
      @category || []
    end

    def syndication
      @syndication || []
    end

    def status
      @status || :live
    end

  end
end
