module Transformative

  class RequestError < StandardError
    attr_reader :type, :status_code
    def initialize(type, message, status_code)
      @type = type
      @status_code = status_code
      super(message)
    end
  end

end

require_relative 'transformative/post.rb'
require_relative 'transformative/auth.rb'
require_relative 'transformative/card.rb'
require_relative 'transformative/cite.rb'
require_relative 'transformative/event.rb'
require_relative 'transformative/entry.rb'
require_relative 'transformative/store.rb'
require_relative 'transformative/micropub.rb'
require_relative 'transformative/server.rb'
