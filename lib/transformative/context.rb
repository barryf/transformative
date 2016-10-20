module Transformative
  module Context
    module_function

    def fetch(url)
      parsed = if url.match(/^https?:\/\/twitter\.com/) ||
          url.match(/^https?:\/\/mobile\.twitter\.com/)
        parse_twitter(url)
      elsif url.match(/instagram\.com/)
        parse_instagram(url)
      else
        parse_mf2(url)
      end
      return if parsed.nil?
      # create author h-card
      unless parsed[1].nil?
        author_url = "/cards/#{Utils.slugify_url(parsed[1][:url])}"
        author = Post.new(author_url, ['h-cite'], parsed[1])
        Store.save(author)
      end
      # create h-cite
      cite_url = "/cites/#{Utils.slugify_url(url)}"
      cite = Post.new(cite_url, ['h-cite'], parsed[0])
      Store.save(cite)
    end

    def parse_mf2
      response = HTTParty.get(url)
      return unless response.status.to_i == 200
      collection = Microformats2.parse(response.body)
      object = if collection.respond_to?(:entry)
        collection.entry
      elsif collection.respond_to?(:event)
        collection.event
      end
      return if object.nil?
      cite = {
        url: [object.url.to_s],
        name: [object.name.to_s],
        published: [Time.parse(object.published.to_s).utc.iso8601.to_s],
        content: [object.content.to_s],
        author: [object.author.to_s]
      }
      author = Authorship.fetch(object.author.to_s)
      [cite, author]
    end

    def parse_twitter(url)
      tweet_id = url.split('/').last
      tweet = twitter_client.status(tweet_id)
      cite = {
        url: [url],
        content: [tweet.text.dup],
        author: ["https://twitter.com/#{tweet.user.screen_name}"],
        published: [Time.parse(tweet.created_at.to_s).utc]
      }
      # does the tweet have photo(s)?
      cite[:photo] = tweet.media.map { |m| m.media_url.to_s }
      # replace t.co links with expanded versions
      tweet.urls.each do |u|
        cite[:content][0].sub!(u.url.to_s, u.expanded_url.to_s)
      end
      author = {
        url: ["https://twitter.com/#{tweet.user.screen_name}"],
        name: [tweet.user.name],
        photo: ["#{tweet.user.profile_image_url.scheme}://" +
          tweet.user.profile_image_url.host +
          tweet.user.profile_image_url.path]
      }
      # TODO: copy the photo somewhere else and reference it
      [cite, author]
    end

    def parse_instagram(url)
      url = tidy_instagram_url(url)
      json = HTTParty.get(
        "http://api.instagram.com/oembed?url=#{CGI::escape(url)}").body
      body = JSON.parse(json)
      cite = {
        url: [url],
        author: [body['author_url']],
        photo: [body['thumbnail_url']],
        content: [body['title']]
      }
      author = {
        url: [body['author_url']],
        name: [body['author_name']]
      }
      [cite, author]
    end

    # strip cruft from URL, e.g. #liked-by-xxxx or modal=true from instagram
    def tidy_instagram_url(url)
      uri = URI.parse(url)
      uri.fragment = nil
      uri.query = nil
      uri.to_s
    end

    private

    def twitter_client
      @twitter_client ||= Twitter::REST::Client.new do |config|
        config.consumer_key        = ENV['TWITTER_CONSUMER_KEY']
        config.consumer_secret     = ENV['TWITTER_CONSUMER_SECRET']
        config.access_token        = ENV['TWITTER_ACCESS_TOKEN']
        config.access_token_secret = ENV['TWITTER_ACCESS_TOKEN_SECRET']
      end
    end

  end
end