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
      url.to_s.downcase.gsub(/[^a-z0-9\-]/,' ').strip.gsub(/\s+/,'/')
    end

    def relative_url(url)
      url.sub!(ENV['SITE_URL'], '')
      url.start_with?('/') ? url : "/#{url}"
    end

  end
end