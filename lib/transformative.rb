module Transformative

  class RequestError < StandardError
    attr_reader :type, :status_code
    def initialize(type, message, status=500)
      @type = type
      @status = status
      super(message)
    end
  end

end

require_relative 'transformative/post.rb'
require_relative 'transformative/auth.rb'
require_relative 'transformative/store.rb'
require_relative 'transformative/micropub.rb'
require_relative 'transformative/server.rb'
