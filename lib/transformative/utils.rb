module Transformative
  module Utils
    module_function

    def valid_url?(url)
      begin
        uri = URI.parse(url)
        uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
      rescue URI::InvalidURIError
      end
    end

    def slugify_url(url)
      url.to_s.downcase.gsub(/[^a-z0-9\-]/,' ').strip.gsub(/\s+/,'/')
    end

    def relative_url(url)
      url.sub!(ENV['SITE_URL'], '')
      url.start_with?('/') ? url : "/#{url}"
    end

    def ping_pubsubhubbub
      HTTParty.post(ENV['PUBSUBHUBBUB_HUB'], {
        body: {
          "hub.mode": "publish",
          "hub.url": ENV['SITE_URL']
        }
      })
    end

    def twitter_client
      @twitter_client ||= ::Twitter::REST::Client.new do |config|
        config.consumer_key        = ENV['TWITTER_CONSUMER_KEY']
        config.consumer_secret     = ENV['TWITTER_CONSUMER_SECRET']
        config.access_token        = ENV['TWITTER_ACCESS_TOKEN']
        config.access_token_secret = ENV['TWITTER_ACCESS_TOKEN_SECRET']
      end
    end

  end
end