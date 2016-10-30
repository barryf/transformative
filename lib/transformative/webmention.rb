module Transformative
  module Webmention
    module_function

    def receive(source, target)
      return if source == target

      verify_source(source)

      verify_target(target)

      check_site_matches_target(target)

      check_target_is_valid_post(target)

      source_body = get_source_and_check_it_links_to_target(source, target)

      author = store_author(source, source_body)

      cite = store_cite(source, source_body, author.properties['url'][0],
        target)

      send_notification(author, source_body, target)
    end

    def verify_source(source)
      unless Utils.valid_url?(source)
        raise WebmentionError.new("invalid_source",
          "The specified source URI is not a valid URI.")
      end
    end

    def verify_target(target)
      unless Utils.valid_url?(target)
        raise WebmentionError.new("invalid_target",
          "The specified target URI is not a valid URI.")
      end
    end

    def check_site_matches_target(target)
      unless URI.parse(ENV['SITE_URL']).host == URI.parse(target).host
        raise WebmentionError.new("target_not_supported",
          "The specified target URI does not exist on this server.")
      end
    end

    def check_target_is_valid_post(target)
      target_path = URI.parse(target).path
      # check there is a webmention link tag/header at target
      response = HTTParty.get(target)
      unless response.code.to_i == 200
        raise WebmentionError.new("invalid_source",
        "The specified target URI could not be retrieved.")
      end
      unless Nokogiri::HTML(response.body).css("link[rel=webmention]").any? ||
          response.headers['Link'].match('rel=webmention')
        raise WebmentionError.new("target_not_supported",
          "The specified target URI is not a Webmention-enabled resource.")
      end
    end

    def get_source_and_check_it_links_to_target(source, target)
      response = HTTParty.get(source)
      unless response.code.to_i == 200
        raise WebmentionError.new("invalid_source",
        "The specified source URI could not be retrieved.")
      end
      unless Nokogiri::HTML(response.body).css("a[href=\"#{target}\"]").any?
        raise WebmentionError.new("no_link_found",
          "The source URI does not contain a link to the target URI.")
      end
      response.body
    end

    def store_author(source, source_body)
      author_post = Authorship.get_author(source, source_body)
      Store.save(author_post)
    end

    def store_cite(source, source_body, author_url, target)
      json = Microformats2.parse(source_body).to_json
      properties = JSON.parse(json)['items'][0]['properties']
      cite = Cite.new({
        'url' => [source],
        'name' => [properties['name'][0].strip],
        'published' =>
          [Time.parse(properties['published'][0]).utc.iso8601],
        'content' => [{ html: item['properties']['content'][0].strip }],
        'author' => [author_url],
        webmention_property(source_body, target) => [target]
      })
      Store.save(cite)
    end

    def webmention_property(body, url)
      doc = Nokogiri::HTML(body)
      if doc.css("a[href=\"#{url}\"].u-in-reply-to").any? ||
          doc.css("a[href=\"#{url}\"][rel=\"in-reply-to\"]").any?
        return 'in-reply-to'
      elsif doc.css("a[href=\"#{url}\"].u-like-of").any? ||
          doc.css("a[href=\"#{url}\"].u-like").any?
        return 'like-of'
      elsif doc.css("a[href=\"#{url}\"].u-repost-of").any? ||
          doc.css("a[href=\"#{url}\"].u-repost").any?
        return 'repost-of'
      end
      'mention-of'
    end

    def send_notification(author, content, url)
      name = author.properties['name'][0]
      Notification.send("Webmention from #{name}", content, url)
    end

  end

  class WebmentionError < TransformativeError
    def initialize(type, message)
      super(type, message)
    end
  end

end
