require 'uri'

module Microformats
  class Base

    def get_property(name)
      property = self.hyphens_to_underscores(name)
      return unless self.valid_property?(property)
      send(property)
    end

    def set_property(name, value)
      property = self.hyphens_to_underscores(name)
      return unless self.valid_property?(property)
      send("#{property}=", value)
    end

    def self.class_name
      self.name.split('::').last.downcase
    end

    def self.mf2_name
      "h-#{self.class_name}"
    end

    def self.valid_url?(url)
      begin
        uri = URI.parse(url)
        uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
      rescue URI::InvalidURIError
      end
    end

    def self.hyphens_to_underscores(name)
      name.gsub('-','_')
    end

    def self.valid_property?(property)
      self.valid_properties.include?(property)
    end

    def self.get_class(name)
      case name.to_sym
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

  end
end