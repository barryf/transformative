module Transformative
  module Authorship
    module_function

    def fetch(url)
      author = Indieweb::Authorship.identify(url)
      return unless author
      properties = {
        'url' => [author['url']],
        'photo' => [author['photo']],
        'name' => [author['name']]
      }
      Card.new(properties)
    end

  end
end