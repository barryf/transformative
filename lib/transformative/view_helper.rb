require 'openssl'

module Transformative
  module ViewHelper

    CAMO_URL = "https://barryfrost-camo.herokuapp.com/"

    def h(text)
      Rack::Utils.escape_html(text)
    end

    def filter_markdown(content)
      return "" if content.nil?
      Redcarpet::Render::SmartyPants.render(
        Redcarpet::Markdown.new(
          Redcarpet::Render::HTML, autolink: true
        ).render(content)
      )
    end

    def post_type_icon(type)
      icon = case type
        when 'article'
          "file-text"
        when 'bookmark'
          "bookmark"
        when 'photo'
          "camera"
        when 'reply'
          "reply"
        when 'repost'
          "retweet"
        when 'like'
          "heart"
        when 'rsvp'
          "calendar"
        when 'checkin'
          "map-marker"
        else
          "comment"
        end
      "<span class=\"fa fa-#{icon}\"></span>"
    end

    def context_prefix(entry)
      if entry.properties.key?('in-reply-to')
        "In reply to"
      elsif entry.properties.key?('repost-of')
        "Reposted"
      elsif entry.properties.key?('like-of')
        "Liked"
      elsif entry.properties.key?('rsvp')
        "RSVP to"
      end
    end

    def syndication_text(syndication)
      host = URI.parse(syndication).host
      case host
      when 'twitter.com', 'mobile.twitter.com'
        "<span class=\"fa fa-twitter\"></span> Twitter"
      when 'instagram.com', 'www.instagram.com'
        "<span class=\"fa fa-instagram\"></span> Instagram"
      when 'facebook.com', 'www.facebook.com'
        "<span class=\"fa fa-facebook\"></span> Facebook"
      else
        host
      end
    end

    def webmention_type(post)
      if post.properties.key?('in-reply-to')
        'reply'
      elsif post.properties.key?('repost-of')
        'repost'
      elsif post.properties.key?('like-of')
        'like'
      else
        'mention'
      end
    end

    def webmention_type_p_class(type)
      case type
      when "reply","comment"
        return "p-comment" # via http://microformats.org/wiki/comment-brainstorming#microformats2_p-comment_h-entry
      when "like"
        return "p-like"
      when "repost"
        return "p-repost"
      end
    end
    def post_type_u_class(type)
      case type
      when "reply", "rsvp"
        return "u-in-reply-to"
      when "repost"
        return "u-repost-of u-repost"
      when "like"
        return "u-like-of u-like"
      end
    end
    def post_type_p_class(post)
      if post.properties.key?('in-reply-to')
        "p-in-reply-to"
      elsif post.properties.key?('repost-of')
        "p-repost-of"
      elsif post.properties.key?('like-of')
        "p-like-of"
      elsif post.properties.key?('rsvp')
        "p-rsvp"
      end
    end
    def context_tag(post)
      if post.h_type == 'h-entry'
        case post.entry_type
        when "reply", "rsvp"
          url = post.properties['in-reply-to'][0]
          return "<a class=\"u-in-reply-to\" href=\"#{url}\"></a>"
        when "repost"
          url = post.properties['repost-of'][0]
          return "<a class=\"u-repost-of\" href=\"#{url}\"></a>"
        when "like"
          url = post.properties['like-of'][0]
          return "<a class=\"u-like-of\" href=\"#{url}\"></a>"
        end
      end
    end

    def webmention_type_icon(type)
      case type
      when 'reply'
        return "<span class=\"mention-type fa fa-reply\"></span>"
      when 'repost'
        return "<span class=\"mention-type fa fa-retweet\"></span>"
      when 'like'
        return "<span class=\"mention-type fa fa-heart\"></span>"
      else
        return "<span class=\"mention-type fa fa-quote-left\"></span>"
      end
    end

    def webmention_type_text(type)
      case type
      when 'reply'
        return "replied to this"
      when 'repost'
        return "reposted this"
      when 'like'
        return "liked this"
      else
        return "mentioned this"
      end
    end

    def host_link(url)
      host = URI.parse(url).host.downcase
      case host
      when "twitter.com","mobile.twitter.com"
        host_text = "<i class=\"fa fa-twitter\"></i> Twitter"
      when "instagram.com", "www.instagram.com"
        host_text = "<i class=\"fa fa-instagram\"></i> Instagram"
      else
        host_text = host
      end
      "<a class=\"u-url\" rel=\"nofollow\" href=\"#{url}\">#{host_text}</a>"
    end

    def post_summary(content, num=200)
      summary = Sanitize.clean(content).to_s.strip[0...num]
      if summary.size == num
        summary = summary.strip + "&hellip;"
      end
      summary
    end

    def filter_all(content)
      content = link_twitter(content)
      content = link_hashtags(content)
      content
    end

    def link_urls(content)
      content.gsub /((https?:\/\/|www\.)([-\w\.]+)+(:\d+)?(\/([\w\/_\.\+\-]*(\?\S+)?)?)?)/, %Q{<a href="\\1">\\1</a>}
    end
    def link_twitter(content)
      content.gsub /\B@(\w*[a-zA-Z0-9_-]+)\w*/i, %Q{<a href="https://twitter.com/\\1">@\\1</a>\\2}
    end
    def link_hashtags(content)
      # hashtags => link internally
      content.gsub /\B#(\w*[a-zA-Z0-9]+)\w*/i, %Q{ <a href="/tag/\\1">#<span class=\"p-category\">\\1</span></a> }
    end
    def link_hashtags_twitter(content)
      # hashtags => link to twitter search
      content.gsub /\B#(\w*[a-zA-Z0-9]+)\w*/i, %Q{ <a href="https://twitter.com/search/\\1">#<span class=\"p-category\">\\1</span></a> }
    end

    def force_https_author_profile(url)
      if url.start_with?('http://pbs.twimg.com')
        url.gsub 'http://pbs.twimg.com', 'https://pbs.twimg.com'
      elsif !url.start_with?('https')
        camo_image(url)
      else
        url
      end
    end

    # from https://github.com/atmos/camo/blob/master/test/proxy_test.rb
    def hexenc(image_url)
      image_url.to_enum(:each_byte).map { |byte| "%02x" % byte }.join
    end
    def camo_image(image_url)
      hexdigest = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'),
        ENV['CAMO_KEY'], image_url)
      encoded_image_url = hexenc(image_url)
      "#{CAMO_URL}#{hexdigest}/#{encoded_image_url}"
    end

    def is_tweet?(post)
      url = post.properties['url'][0]
      url.start_with?('https://twitter.com') ||
        url.start_with?('https://mobile.twitter.com')
    end

    def host_link(url)
      host = URI.parse(url).host.downcase
      case host
      when "twitter.com","mobile.twitter.com"
        host_text = "<i class=\"fa fa-twitter\"></i> Twitter"
      when "instagram.com", "www.instagram.com"
        host_text = "<i class=\"fa fa-instagram\"></i> Instagram"
      else
        host_text = host
      end
      "<a class=\"u-url\" rel=\"nofollow\" href=\"#{url}\">#{host_text}</a>"
    end

    def valid_url?(url)
      Utils.valid_url?(url)
    end

    def nav(path, text)
      if path == request.path_info
        "<li class=\"active\">#{text}</li>"
      else
        "<li><a href=\"#{path}\">#{text}</a></li>"
      end
    end

    def page_title(post)
      if post.h_type == 'h-event'
        return post.properties['name'][0] || 'Event'
      end

      case post.properties['entry-type'][0]
      when 'article'
        post.properties['name'][0] || 'Article'
      when 'bookmark'
        post.properties['name'][0] || 'Bookmark'
      when 'repost'
        "Repost #{post.url}"
      when 'like'
        "Like #{post.url}"
      when 'rsvp'
        "RSVP #{post.url}"
      when 'checkin'
        "Checkin"
      else
        post_summary(post.content, 100)
      end
    end

    def rss_description(post)
      content = ""
      if post.properties.key?('photo')
        post.properties['photo'].each do |photo|
          content += "<p><img src=\"#{photo}\"></p>"
        end
      end
      unless post.content.nil?
        content += markdown(post.content)
      end
      content
    end

  end
end