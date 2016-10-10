module Microformats
  class Entry < Base

    SIMPLE_PROPERTIES = %w( name summary content published updated location
      like_of repost_of rsvp bookmark_of place_name content_html )
    ARRAY_PROPERTIES = %w( category syndication in_reply_to photo )
    PROPERTIES = SIMPLE_PROPERTIES + ARRAY_PROPERTIES
    PROPERTIES.each { |p| attr_accessor p }

    def published
      @published.utc.iso8601 unless @published.nil?
    end

    def updated
      @updated.utc.iso8601 unless @updated.nil?
    end

    def content
      if (@content.nil? || @content.empty?) && !summary.nil? && !summary.empty?
        summary
      else
        @content
      end
    end

    def type
      if rsvp && %w( yes no maybe interested ).include?(rsvp)
        :rsvp
      elsif in_reply_to && self.valid_url?(in_reply_to)
        :reply
      elsif repost_of && self.valid_url?(repost_of)
        :repost
      elsif like_of && self.valid_url?(like_of)
        :like
      elsif video && self.valid_url?(video)
        :video
      elsif photo && self.valid_url?(photo)
        :photo
      elsif bookmark_of && self.valid_url?(bookmark_of)
        :bookmark
      elsif name && !name.empty? && !content_start_with_name?
        :article
      else
        :note
      end
    end

    def type_label
      type.to_s.capitalize
    end

    def content_start_with_name?
      return if content.nil? || name.nil?
      content_tidy = content.gsub(/\s+/, " ").strip
      name_tidy = name.gsub(/\s+/, " ").strip
      content_tidy.start_with?(name_tidy)
    end

    def self.valid_properties
      PROPERTIES
    end

    def self.simple_properties
      SIMPLE_PROPERTIES
    end

    def self.array_properties
      ARRAY_PROPERTIES
    end

    def self.valid_types
      %i( note article bookmark reply repost like rsvp photo video )
    end

    def self.valid_type?(type)
      self.valid_types.include?(type)
    end

  end
end