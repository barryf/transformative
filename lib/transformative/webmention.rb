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

      send_notification(cite, author, target)
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
      case response.code.to_i
      when 410
        # the post has been deleted so remove any existing webmentions
        remove_webmention_if_exists(source)
      when 200
        # that's fine - continue...
      else
        raise WebmentionError.new("invalid_source",
          "The specified source URI could not be retrieved.")
      end

      doc = Nokogiri::HTML(response.body)
      unless doc.css("a[href=\"#{target}\"]").any? ||
          doc.css("img[src=\"#{target}\"]").any? ||
          doc.css("video[src=\"#{target}\"]").any? ||
          doc.css("audio[src=\"#{target}\"]").any?
        # there is no match so remove any existing webmentions
        remove_webmention_if_exists(source)
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
      published = properties.key?('published') ?
        Time.parse(properties['published'][0]) :
        Time.now
      hash = {
        'url' => [properties['url'][0]],
        'name' => [properties['name'][0].strip],
        'published' => [published.utc.iso8601],
        'author' => [author_url],
        webmention_property(source_body, target) => [target]
      }
      if properties.key?('content')
        hash['content'] = [{ html: properties['content'][0].strip }]
      end
      if properties.key?('photo') && properties['photo'].any?
        hash['photo'] = properties['photo']
      end
      cite = Cite.new(hash)
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

    def remove_webmention_if_exists(url)
      return unless cite = Cache.get_by_properties_url(url)
      %w( in-reply-to repost-of like-of ).each do |property|
        if cite.properties.key?(property)
          cite.properties.delete(property)
        end
      end
      Store.save(cite)
    end

    def send_notification(cite, author, target)
      author_name = author.properties['name'][0]
      author_url = author.properties['url'][0]
      type = cite.webmention_type
      Notification.send(
        "New #{type}",
        "New #{type} of #{target} from #{author_name} - #{author_url}",
        target)
    end

  end

  class WebmentionError < TransformativeError
    def initialize(type, message)
      super(type, message, 400)
    end
  end

end
