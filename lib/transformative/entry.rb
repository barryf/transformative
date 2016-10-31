module Transformative
  class Entry < Post

    def initialize(properties, url=nil)
      super(properties, url)
    end

    def h_type
      'h-entry'
    end

    def filename
      "/#{@url}.json"
    end

    def generate_url
      generate_url_published
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

    def cite_belongs_to_post?(cite)
      property = case @properties['entry-type'][0]
        when 'reply'
          'in-reply-to'
        when 'repost'
          'repost-of'
        when 'like'
          'like-of'
        else
          return
        end
      @properties[property].include?(cite.properties['url'][0])
    end

    def self.new_from_form(params)
      # wrap each non-array value in an array
      props = Hash[ params.map { |k, v| [k, Array(v)] } ]

      if params.key?('photo')
        props['photo'] = Media.upload_files(params['photo'])
      end
      if params.key?('video')
        props['video'] = Media.upload_files(params['video'])
      end
      if params.key?('audio')
        props['audio'] = Media.upload_files(params['audio'])
      end

      self.new(props)
    end

  end
end