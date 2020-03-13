module Transformative
  module Authorship
    module_function

    def fetch(url)
      author = Indieweb::Authorship.identify(url)
      return unless author
      properties = {
        'url' => [author['url']]
      }
      properties['name'] = [author['name']] if author['name']
      properties['photo'] = [author['photo']] if author['photo']
      Card.new(properties)
    end

  end
end