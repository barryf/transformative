module Transformative
  module Webmention
    module_function

    def send(url)
      ::Webmention::Client.new(url).send_mentions
    end

    def receive(source, target)
      verify_source(source)

      verify_target(target)

      check_site_matches_target(target)

      check_target_is_valid_post(target)

      source_body = get_source_and_check_it_links_to_target(source, target)

      author_name = get_author_and_store_cite_and_card(source, source_body)

      send_notification(author_name, source_body, target)
    end

    def verify_source(source)
      unless valid_url?(source)
        raise WebmentionError.new("invalid_source",
          "The specified source URI is not a valid URI.")
      end
    end

    def verify_target(target)
      unless valid_url?(target)
        raise WebmentionError.new("invalid_target",
          "The specified target URI is not a valid URI.")
      end
    end

    def check_site_matches_target(target)
      unless URI.parse(ENV['ROOT_URL']).host == URI.parse(target).host
        raise WebmentionError.new("target_not_supported",
          "The specified target URI does not exist on this server.")
      end
    end

    def check_target_is_valid_post(target)
      target_path = URI.parse(target).path
      # TODO: look this up in database
      unless true
        raise WebmentionError.new("target_not_supported",
          "The specified target URI is not a Webmention-enabled resource.")
      end
    end

    def get_source_and_check_it_links_to_target(source, target)
      response = HTTParty.get(source)
      unless Nokogiri::HTML(response.body).css("a[href=\"#{target}\"]").any?
        raise WebmentionError.new("no_link_found",
          "The source URI does not contain a link to the target URI.")
      end
      response.body
    end

    def get_author_and_store_cite_and_card(source, source_body)
      entry = Microformats2.parse(source_body).entry
      author_url = absolutize(entry.author.to_s, source)
      create_cite({
        url: source,
        name: entry.name.to_s,
        content: entry.content.to_s,
        author: author_url
      })
      author_body = HTTParty.get(author_url).body
      author = Microformats2.parse(author_body).card
      create_card({
        name: author.name.to_s,
        photo: absolutize(author.photo.to_s, source),
        url: absolutize(author.url.to_s, source)
      })
      author.name.to_s
    end

    # TODO: create_cite, create_card. refactor ^^^?

    def send_notification(name, content, url)
      Notify.send("Webmention from #{name}", content, url)
    end

    def valid_url?(url)
      begin
        uri = URI.parse(url)
        uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
      rescue URI::InvalidURIError
      end
    end

    def absolutize(url, base_url)
      if url.start_with?("http")
        url
      else
        URI.join(base_url, url)
      end
    end

  end

  class WebmentionError < RequestError
    def initialize(type, message)
      super(type, message)
    end
  end

end
