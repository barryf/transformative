module Transformative
  module Syndication
    module_function

    def send(post, service)
      if service.start_with?('https://twitter.com/')
        send_twitter(post)
      end
    end

    def send_twitter(post)
      # we can only send entries to twitter so ignore anything else
      # TODO syndicate other objects
      return unless post.class_name == 'entry'

      entry = post.object
      body = { h: 'entry', url: post.url }

      # prefer the (hand-crafted) summary to the main content
      content = entry.summary.empty? ? entry.content : entry.summary
      unless content.empty?
        body[:content] = content
      end

      # multiple in-reply-tos are allowed (only first used) so use array
      unless entry.in_reply_to.empty?
        body['in-reply-to'] = entry.in_reply_to
      end

      unless entry.repost_of.empty?
        body['repost-of'] = entry.repost_of
      end

      unless entry.like_of.empty?
        body['like-of'] = entry.like_of
      end

      unless entry.name.empty?
        body[:name] = entry.name
      end

      # multiple photos are allowed so use array
      unless entry.photo.empty?
        body[:photo] = entry.photo
      end

      response = micropub_request(body, ENV['SILOPUB_TWITTER_TOKEN'])
      unless response.code == 200
        raise SyndicationError.new("Twitter syndication failed.", response.body)
      end

      # find the twitter id from its api's json response
      hash = JSON.parse(response.body)
      twitter_id = hash['id']
      "https://twitter.com/#{ENV['GITHUB_USER']}/status/#{twitter_id}"
    end

    def micropub_request(body, token)
      HTTParty.post(
        ENV['SILOPUB_MICROPUB_ENDPOINT'],
        body: body,
        headers: { 'Authorization' => "Bearer #{token}" }
      )
    end

  end
end