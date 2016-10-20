module Transformative
  class Post

    attr_reader :url, :type, :properties

    def initialize(url, type, properties)
      @type = type
      @properties = properties
      @url = url || generate_url
    end

    def data
      { 'type' => [@type], 'properties' => @properties }
    end

    def absolute_url
      URI.join(ENV['SITE_URL'], @url).to_s
    end

    def entry_type
      if @properties.key?('rsvp') &&
          %w( yes no maybe interested ).include?(@properties['rsvp'][0])
        'rsvp'
      elsif @properties.key?('in-reply-to') &&
          Utils.valid_url?(@properties['in-reply-to'][0])
        'reply'
      elsif @properties.key?('repost-of') &&
          Utils.valid_url?(@properties['repost-of'][0])
        'repost'
      elsif @properties.key?('like-of') &&
          Utils.valid_url?(@properties['like-of'][0])
        'like'
      elsif @properties.key?('video') &&
          Utils.valid_url?(@properties['video'][0])
        'video'
      elsif @properties.key?('photo') &&
          Utils.valid_url?(@properties['photo'][0])
        'photo'
      elsif @properties.key?('bookmark-of') &&
          Utils.valid_url?(@properties['bookmark-of'][0])
        'bookmark'
      elsif @properties.key?('name') && !@properties['name'].empty? &&
          !content_start_with_name?
        'article'
      else
        'note'
      end
    end

    def content_start_with_name?
      return unless @properties.key?('content') && @properties.key?('name')
      content = @properties['content'][0].is_a?(Hash) &&
        @properties['content'][0].key?('html') ?
        @properties['content'][0]['html'] : @properties['content'][0]
      content_tidy = content.gsub(/\s+/, " ").strip
      name_tidy = @properties['name'][0].gsub(/\s+/, " ").strip
      content_tidy.start_with?(name_tidy)
    end

    def filename
      path = "#{@url}.json"
    end

    def generate_url
      case @type
      when 'h-entry', 'h-event'
        unless @properties.key('published')
          @properties['published'] = [Time.now.utc.iso8601]
        end
        slug = @properties.key?('slug') ? @properties['slug'][0] : slugify
        url = "/#{Time.parse(@properties['published'][0]).strftime('%Y/%m')}/" +
          slug
      when 'h-cite', 'h-card'
        return unless @properties.key?('url')
        url = "/#{slugify}"
      end
      @type == 'h-entry' ? url : "/#{self.pural_type(@type)}#{url}"
    end

    def slugify
      if @properties.key?('url')
        return Utils.slugify_url(@properties['url'][0])
      end

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
      return unless ['h-entry','h-event'].include?(@type)

      # iterate over the mp-syndicate-to services
      new_syndications = services.map do |service|
        Syndication.send(self, service)
      end

      return if new_syndications.empty?
      # add to syndications list
      @properties['syndications'].merge!(new_syndications)
      Store.put_post(self)
    end

    def self.new_from_form(params)
      h_type = "h-#{params['h']}"
      params.delete('h')

      # then wrap each non-array value in an array
      props = Hash[ params.map { |k, v| [k, Array(v)] } ]

      if params.key?('photo')
        props['photo'] = Media.upload_files(props['photo'])
      end
      if params.key?('video')
        props['video'] = Media.upload_files(props['video'])
      end

      self.new(nil, h_type, props)
    end

    def self.valid_types
      %w( h-card h-cite h-entry h-event )
    end

  end
end