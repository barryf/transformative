module Transformative
  module Syndication
    module_function

    SILOPUB_MICROPUB_ENDPOINT = "https://silo.pub/micropub"

    def send(post, service)
      if service.start_with?('https://twitter.com/')
        account = service.split('/').last
        send_twitter(post, account)
      end
    end

    def send_twitter(post, account)
      # we can only send entries to twitter so ignore anything else
      # TODO syndicate other objects
      return unless post.h_type == 'h-entry'

      body = { 'h' => 'entry', 'url' => post.absolute_url }

      # prefer the (hand-crafted) summary to the main content
      body['content'] = if post.properties.key?('summary')
        post.properties['summary'][0]
      elsif post.properties.key?('content')
        if post.properties['content'][0].is_a?(Hash) &&
            post.properties['content'][0].key?('html')
          post.properties['content'][0]['html']
        else
          post.properties['content'][0]
        end
      end

      if post.properties.key?('in-reply-to')
        body['in-reply-to'] = post.properties['in-reply-to']
      end

      if post.properties.key?('repost-of')
        body['repost-of'] = post.properties['repost-of']
      end

      if post.properties.key?('like-of')
        body['like-of'] = post.properties['like-of']
      end

      if post.properties.key?('name')
        body['name'] = post.properties['name'][0]
      end

      # TODO limit to 4? may not be necessary
      if post.properties.key?('photo')
        body['photo'] = post.properties['photo']
      end

      response = micropub_request(body, ENV['SILOPUB_TWITTER_TOKEN'])
      unless response.code.to_i == 200
        raise SyndicationError.new("Twitter syndication failed (#{response.body}).")
      end

      # find the twitter id from its api's json response
      hash = JSON.parse(response.body)
      "https://twitter.com/#{account}/status/#{hash['id']}"
    end

    def micropub_request(body, token)
      HTTParty.post(
        SILOPUB_MICROPUB_ENDPOINT,
        body: body,
        headers: { 'Authorization' => "Bearer #{token}" }
      )
    end

  end

  class SyndicationError < TransformativeError
    def initialize(message)
      super("syndication", message)
    end
  end

end