module Transformative
  class Cite < Post

    def initialize(properties, url=nil)
      super(properties, url)
    end

    def h_type
      'h-cite'
    end

    def generate_url
      generate_url_slug('/cite/')
    end

    def webmention_type
      if @properties.key?('in-reply-to')
        'Reply'
      elsif @properties.key?('repost-of')
        'Repost'
      elsif @properties.key?('like-of')
        'Like'
      else
        'Mention'
      end
    end

  end
end