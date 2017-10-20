require 'openssl'

module Transformative
  module ViewHelper

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

    def post_type_icon(post)
      icon = case post.properties['entry-type'][0]
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
          if post.properties.key?('rsvp')
            case post.properties['rsvp'][0]
            when 'yes', true
              'calendar-check-o'
            when 'no', false
              'calendar-times-o'
            else
              'calendar-o'
            end
          else
            "calendar"
          end
        when 'checkin'
          "compass"
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
      when 'swarmapp.com', 'www.swarmapp.com'
        "<span class=\"fa fa-foursquare\"></span> Swarm"
      when 'news.indieweb.org'
        "IndieNews"
      when 'medium.com'
        "<span class=\"fa fa-medium\"></span> Medium"
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
      when "mention"
        "p-mention"
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
    def context_class(post)
      if post.properties.key?('in-reply-to')
        "u-in-reply-to"
      elsif post.properties.key?('repost-of')
        "u-repost-of"
      elsif post.properties.key?('like-of')
        "u-like-of"
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
          property = "in-reply-to"
          klass = "u-in-reply-to"
        when "repost"
          property = "repost-of"
          klass = "u-repost-of"
        when "like"
          property = "like-of"
          klass = "u-like-of"
        when "bookmark"
          property = "bookmark-of"
          klass = "u-bookmark-of"
        else
          return
        end
        tags = post.properties[property].map do |url|
          "<a class=\"#{klass}\" href=\"#{url}\"></a>"
        end
        tags.join('')
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

    def post_split(content)
      paragraph_ends = content.split(/\n\n/)
      return content unless paragraph_ends.size > 3
      paragraph_ends.first + " <a href=\"#{@post.absolute_url}\">" +
        "Read&nbsp;full&nbsp;post&hellip;</a>"
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
      return content
      # hashtags => link internally
      content.gsub /\B#(\w*[a-zA-Z0-9]+)\w*/i, %Q{ <a href="/tag/\\1">#<span class=\"p-category\">\\1</span></a> }
    end
    def link_hashtags_twitter(content)
      # hashtags => link to twitter search
      content.gsub /\B#(\w*[a-zA-Z0-9]+)\w*/i, %Q{ <a href="https://twitter.com/search/\\1">#<span class=\"p-category\">\\1</span></a> }
    end

    def force_https_author_profile(photo_url, base_url)
      url = URI.join(base_url, photo_url).to_s
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
      "#{ENV['CAMO_URL']}#{hexdigest}/#{encoded_image_url}"
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
        "Check-in"
      else
        post_summary(post.content, 100)
      end
    end

    def rss_description(post)
      content = ""
      if post.properties.key?('photo')
        post.properties['photo'].each do |photo|
          src = photo.is_a?(Hash) ? photo['value'] : photo
          content += "<p><img src=\"#{src}\"></p>"
        end
      end
      unless post.content.nil?
        content += markdown(post.content)
      end
      content
    end

    def jsonfeed(posts)
      feed = {
        "version" => "https://jsonfeed.org/version/1",
        "title" => "Barry Frost",
        "home_page_url" => ENV['SITE_URL'],
        "feed_url" => "#{ENV['SITE_URL']}feed.json",
        "author" => {
          "name" => "Barry Frost",
          "url" => "https://barryfrost.com/",
          "avatar" => "#{ENV['SITE_URL']}barryfrost.jpg"
        },
        "items" => []
      }
      posts.each do |post|
        item = {
          "id" => post.url,
          "url" => URI.join(ENV['SITE_URL'], post.url),
          "date_published" => post.properties['published'][0]
        }
        if post.properties.key?('updated')
          item["date_modified"] = post.properties['updated'][0]
        end
        if post.properties.key?('name')
          item["title"] = post.properties['name'][0]
        end
        if post.properties['entry-type'][0] == 'bookmark'
          item["title"] = "Bookmark: " + item["title"]
          item["external_url"] = post.properties['bookmark-of'][0]
        end
        if post.properties.key?('content')
          if post.properties['content'][0].is_a?(Hash)
            item["content_html"] = post.properties['content'][0]['html']
          elsif !post.properties['content'][0].empty?
            item["content_html"] = filter_markdown(post.properties['content'][0])
          end
        end
        if post.properties.key?('photo')
          photo = post.properties['photo'][0]
          item["image"] = photo.is_a?(Hash) ? photo['value'] : photo
        end
        if post.properties.key?('category')
          item["tags"] = post.properties['category']
        end
        feed["items"] << item
      end
      feed.to_json
    end

  end
end