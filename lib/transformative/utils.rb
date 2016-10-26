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
      Jekyll::Utils.slugify(url)
    end

    def relative_url(url)
      url.sub!(ENV['SITE_URL'], '')
      url.start_with?('/') ? url : "/#{url}"
    end

    def send_webmentions(url)
      ::Webmention::Client.new(url).send_mentions
    end

  end
end