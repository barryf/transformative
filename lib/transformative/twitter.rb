module Transformative
  module Twitter
    module_function

    TWITTER_STATUS_REGEX =
      /^https?:\/\/twitter\.com\/(?:#!\/)?(\w+)\/status(es)?\/(\d+)$/

    def update(post)
      status = get_status(post)
      return if status.empty?

      options = {}
      if reply_tweet_id = get_reply(post)
        options[:in_reply_to_status_id] = reply_tweet_id
      end
      if media = get_media(post)
        media_ids = media.map { |file| client.upload(file) }
        options[:media_ids] = media_ids.join(',')
      end

      tweet = client.update(status, options)
      "https://twitter.com/#{tweet.user.screen_name}/status/#{tweet.id}"
    end

    def get_status(post)
      # prioritise summary, name (+ url) then content
      # TODO: ellipsize
      if post.properties.key?('summary')
        post.properties['summary'][0]
      elsif post.properties.key?('name')
        "#{post.properties['name'][0]}: #{post.absolute_url}"
      elsif post.properties.key?('content')
        if post.properties['content'][0].is_a?(Hash) &&
            post.properties['content'][0].key?('html')
          Sanitize.fragment(post.properties['content'][0]['html']).strip
        else
          post.properties['content'][0]
        end
      else
        ""
      end
    end

    def get_reply(post)
      # use first twitter url from in-reply-to list
      if post.properties.key?('in-reply-to') &&
          post.properties['in-reply-to'].is_a?(Array)
        post.properties['in-reply-to'].each do |url|
          if tweet_id = tweet_id_from_url(url)
            return tweet_id
          end
        end
      end
    end

    def get_media(post)
      if post.properties.key?('photo') &&
          post.properties['photo'].is_a?(Array)
        post.properties['photo'].map do |photo|
          if photo.is_a?(Hash)
            open(photo['value'])
          else
            open(photo)
          end
        end
      end
    end

    def retweet(urls)
      return unless tweet_id = find_first_tweet_id_from_urls(urls)
      tweet = client.retweet(tweet_id)
      "https://twitter.com/#{tweet[0].user.screen_name}/status/#{tweet[0].id}"
    end

    def favorite(urls)
      return unless tweet_id = find_first_tweet_id_from_urls(urls)
      tweet = client.favorite(tweet_id)
      "https://twitter.com/#{tweet[0].user.screen_name}/status/#{tweet[0].id}"
    end

    def tweet_id_from_url(url)
      return unless tweet_parts = url.match(TWITTER_STATUS_REGEX)
      tweet_parts[3]
    end

    def find_first_tweet_id_from_urls(urls)
      urls.each do |url|
        if tweet_id = tweet_id_from_url(url)
          return tweet_id
        end
      end
    end

    def client
      Utils.twitter_client
    end

  end
end