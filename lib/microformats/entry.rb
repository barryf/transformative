module Microformats
  class Entry < Base

    SIMPLE_PROPERTIES = %w( name summary content published updated location
      like_of repost_of rsvp bookmark_of place_name content_html )
    ARRAY_PROPERTIES = %w( category syndication in_reply_to photo )
    PROPERTIES = SIMPLE_PROPERTIES + ARRAY_PROPERTIES

    def entry_type
      if properties.key?('rsvp') &&
          %w( yes no maybe interested ).include?(properties['rsvp'][0])
        :rsvp
      elsif properties.key?('in-reply-to') &&
          self.valid_url?(properties['in-reply-to'][0])
        :reply
      elsif properties.key?('repost-of') &&
          self.valid_url?(properties['repost-of'][0])
        :repost
      elsif properties.key?('like-of') &&
          self.valid_url?(properties['like-of'][0])
        :like
      elsif properties.key?('video') &&
          self.valid_url?(properties['video'][0])
        :video
      elsif properties.key?('photo') &&
          self.valid_url?(properties['photo'][0])
        :photo
      elsif properties.key?('bookmark-of') &&
          self.valid_url?(properties['bookmark-of'][0])
        :bookmark
      elsif properties.key?('name') && !properties['name'].empty? &&
          !content_start_with_name?
        :article
      else
        :note
      end
    end

    def content_start_with_name?
      content = properties['content']['html'] ||
        properties['content'][0] ||
        nil
      name = propertes['name'] || nil
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

    def self.entry_types
      %i( note article bookmark reply repost like rsvp photo video )
    end

    def self.entry_type?(type)
      self.entry_types.include?(type)
    end

  end
end