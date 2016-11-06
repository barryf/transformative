module Transformative
  class Cite < Post

    def initialize(properties, url=nil)
      super(properties, url)
    end

    def h_type
      'h-cite'
    end

    def generate_url
      generate_url_slug('/cite')
    end

  end
end