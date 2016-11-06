module Transformative
  class Post

    attr_reader :properties, :url

    def initialize(properties, url=nil)
      @properties = properties
      @url = url || generate_url
    end

    def data
      { 'type' => [h_type], 'properties' => @properties }
    end

    def filename
      "#{@url}.json"
    end

    def absolute_url
      URI.join(ENV['SITE_URL'], @url).to_s
    end

    def is_deleted?
      @properties.key?('deleted') &&
        Time.parse(@properties['deleted'][0]) < Time.now
    end

    def content
      if properties.key?('content')
        if properties['content'][0].is_a?(Hash) &&
            properties['content'][0].key?('html')
          properties['content'][0]['html']
        else
          properties['content'][0]
        end
      end
    end

    def generate_url_published
      unless @properties.key('published')
        @properties['published'] = [Time.now.utc.iso8601]
      end
      slug = @properties.key?('slug') ? @properties['slug'][0] : slugify
      "/#{Time.parse(@properties['published'][0]).strftime('%Y/%m')}/#{slug}"
    end

    def generate_url_slug(prefix='/')
      slugify_url = Utils.slugify_url(@properties['url'][0])
      "#{prefix}#{slugify_url}"
    end

    def slugify
      content = if @properties.key?('name')
        @properties['name'][0]
      elsif @properties.key?('summary')
        @properties['summary'][0]
      elsif @properties.key?('content')
        if @properties['content'][0].is_a?(Hash) &&
             @properties['content'][0].key?('html')
           @properties['content'][0]['html']
         else
           @properties['content'][0]
         end
      end
      return Time.now.strftime('%d-%H%M%S') if content.nil?

      content.downcase.gsub(/[^\w-]/, ' ').strip.gsub(' ', '-').
        gsub(/[-_]+/,'-').split('-')[0..5].join('-')
    end

    def replace(props)
      props.keys.each do |prop|
        @properties[prop] = props[prop]
      end
    end

    def add(props)
      props.keys.each do |prop|
        unless @properties.key?(prop)
          @properties[prop] = props[prop]
        else
          @properties[prop] += props[prop]
        end
      end
    end

    def remove(props)
      if props.is_a?(Hash)
        props.keys.each do |prop|
          @properties[prop] -= props[prop]
          if @properties[prop].empty?
            @properties.delete(prop)
          end
        end
      else
        props.each do |prop|
          @properties.delete(prop)
        end
      end
    end

    def delete
      @properties['deleted'] = [Time.now.utc.iso8601]
    end

    def undelete
      @properties.delete('deleted')
    end

    def set_updated
      @properties['updated'] = [Time.now.utc.iso8601]
    end

    def syndicate(services)
      # only syndicate if this is an entry or event
      return unless ['h-entry','h-event'].include?(h_type)

      # iterate over the mp-syndicate-to services
      new_syndications = services.map do |service|
        Syndication.send(self, service)
      end.compact

      return if new_syndications.empty?
      # add to syndication list
      @properties['syndication'] ||= []
      @properties['syndication'] += new_syndications
      Store.save(self)
    end

    def self.class_from_type(type)
      case type
      when 'h-card'
        Card
      when 'h-cite'
        Cite
      when 'h-entry'
        Entry
      when 'h-event'
        Event
      end
    end

    def self.valid_types
      %w( h-card h-cite h-entry h-event )
    end

  end
end