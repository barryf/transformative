module Transformative
  module Context
    module_function

    def fetch_contexts(post)
      if post.properties.key?('in-reply-to')
        post.properties['in-reply-to'].each { |url| fetch(url) }
      elsif post.properties.key?('repost-of')
        post.properties['repost-of'].each { |url| fetch(url) }
      elsif post.properties.key?('like-of')
        post.properties['like-of'].each { |url| fetch(url) }
      end
    end

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
        Store.save(parsed[1])
      end
      # create h-cite
      Store.save(parsed[0])
    end

    def parse_mf2(url)
      json = Microformats.parse(url).to_json
      items = JSON.parse(json)['items']
      item = find_first_hentry_or_hevent(items)
      return if item.nil?
      # get author first
      author = Authorship.fetch(url)
      # construct entry
      properties = item['properties']
      published = properties.key?('published') ?
        Time.parse(properties['published'][0]) : Time.now
      post_url = properties.key?('url') ? properties['url'][0] : url
      hash = {
        'url' => [URI.join(url, post_url).to_s],
        'name' => [properties['name'][0].strip],
        'published' => [published.utc.iso8601],
        'content' => [properties['content'][0]['value']],
        'author' => [author.properties['url'][0]]
      }
      if properties.key?('photo')
        hash['photo'] = properties['photo']
      end
      if properties.key?('start')
        hash['start'] = properties['start']
      end
      if properties.key?('end')
        hash['end'] = properties['end']
      end
      if properties.key?('location')
        hash['location'] = properties['location']
      end
      cite = Cite.new(hash)
      [cite, author]
    end

    def parse_twitter(url)
      tweet_id = url.split('/').last
      tweet = twitter_client.status(tweet_id)
      cite_properties = {
        'url' => [url],
        'content' => [tweet.text.dup],
        'author' => ["https://twitter.com/#{tweet.user.screen_name}"],
        'published' => [Time.parse(tweet.created_at.to_s).utc]
      }
      # does the tweet have photo(s)?
      if tweet.media.any?
        cite_properties['photo'] = tweet.media.map { |m| m.media_url.to_s }
      end
      # replace t.co links with expanded versions
      tweet.urls.each do |u|
        cite_properties['content'][0].sub!(u.url.to_s, u.expanded_url.to_s)
      end
      cite = Cite.new(cite_properties)
      author_properties = {
        'url' => ["https://twitter.com/#{tweet.user.screen_name}"],
        'name' => [tweet.user.name],
        'photo' => ["#{tweet.user.profile_image_url.scheme}://" +
          tweet.user.profile_image_url.host +
          tweet.user.profile_image_url.path]
      }
      # TODO: copy the photo somewhere else and reference it
      author = Card.new(author_properties)
      [cite, author]
    end

    def parse_instagram(url)
      url = tidy_instagram_url(url)
      json = HTTParty.get(
        "http://api.instagram.com/oembed?url=#{CGI::escape(url)}").body
      body = JSON.parse(json)
      cite_properties = {
        'url' => [url],
        'author' => [body['author_url']],
        'photo' => [body['thumbnail_url']],
        'content' => [body['title']]
      }
      cite = Cite.new(cite_properties)
      author_properties = {
        'url' => [body['author_url']],
        'name' => [body['author_name']]
      }
      author = Card.new(author_properties)
      [cite, author]
    end

    # strip cruft from URL, e.g. #liked-by-xxxx or modal=true from instagram
    def tidy_instagram_url(url)
      uri = URI.parse(url)
      uri.fragment = nil
      uri.query = nil
      uri.to_s
    end

    def find_first_hentry_or_hevent(items)
      items.each do |item|
        if item['type'][0] == 'h-entry' || item['type'][0] == 'h-event'
          return item
        end
      end
    end

    def twitter_client
      Utils.twitter_client
    end

  end
end