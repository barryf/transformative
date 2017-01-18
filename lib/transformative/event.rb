module Transformative
  class Event < Post

    def initialize(properties, url=nil)
      super(properties, url)
    end

    def h_type
      'h-event'
    end

    def filename
      "/#{url}.json"
    end

    def generate_url
      generate_url_published
    end

  end
end