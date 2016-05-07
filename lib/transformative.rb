module Transformative

  class ResponseError < StandardError
    attr_reader :type, :status_code
    def initialize(type, message, status_code)
      @type = type
      @status_code = status_code
      super(message)
    end
  end

end

require_relative 'transformative/post.rb'
require_relative 'transformative/indieauth.rb'
require_relative 'transformative/micropub.rb'
require_relative 'transformative/server.rb'
