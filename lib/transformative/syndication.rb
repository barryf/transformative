module Transformative
  module Syndication
    module_function

    def send(post, service)
      if service.start_with?('https://twitter.com/')
        send_twitter(post)
      elsif service.start_with?('https://pinboard.in/')
        send_pinboard(post)
      end
    end

    def send_pinboard(post)
      # no person-tags (or other urls)
      tags = if post.properties.key?('category')
          post.properties['category'].map { |tag|
            tag unless Utils.valid_url?(tag)
          }.compact.join(',')
        else
          ""
        end
      opts = {
        'auth_token' => ENV['PINBOARD_AUTH_TOKEN'],
        'url' => post.properties['bookmark-of'][0],
        'description' => post.properties['name'][0],
        'extended' => post.content,
        'tags' => tags,
        'dt' => post.properties.key?('published') ?
          post.properties['published'][0] : Time.now.utc.iso8601
      }
      pinboard_url = "https://api.pinboard.in/v1/posts/add"
      HTTParty.get(pinboard_url, query: opts)
      return
    end

    def send_twitter(post)
      # we can only send entries to twitter so ignore anything else
      # TODO syndicate other objects
      return unless post.h_type == 'h-entry'

      case post.entry_type
      when 'repost'
        Twitter.retweet(post.properties['repost-of'])
      when 'like'
        Twitter.favorite(post.properties['like-of'])
      else
        Twitter.update(post)
      end
    end

  end

  class SyndicationError < TransformativeError
    def initialize(message)
      super("syndication", message)
    end
  end

end