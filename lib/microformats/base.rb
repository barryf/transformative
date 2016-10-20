require 'uri'

module Microformats
  class Base

    attr_reader :post

    def initialize(post)
      @post = post
    end

    def properties
      @post.properties
    end

    def self.valid_property?(property)
      self.valid_properties.include?(property)
    end

    def self.get_class
      case self.class.name.to_sym
      when :card
        Card
      when :cite
        Cite
      when :entry
        Entry
      when :event
        Event
      end
    end

    def self.valid_url?(url)
      begin
        uri = URI.parse(url)
        uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
      rescue URI::InvalidURIError
      end
    end

  end
end