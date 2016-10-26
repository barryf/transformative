module Transformative
  class Cite < Post

    def initialize(properties, url=nil)
      super(properties, url)
    end

    def h_type
      'h-cite'
    end

    def filename
      "/cites/#{@url}.json"
    end

    def generate_url
      generate_url_slug
    end

  end
end