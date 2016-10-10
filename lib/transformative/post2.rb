module Transformative
  class Post

    attr_reader :url, :type, :properties

    def initialize(url, type, properties)
      @url = url
      @type = type
      @properties = properties
    end

    def self.new_via_form(params)
      type = params['h']
      properties = params.delete('h')
      self.new(type, properties)
    end

  end
end