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
require_relative 'transformative/post_store.rb'
require_relative 'transformative/card.rb'
require_relative 'transformative/cite.rb'
require_relative 'transformative/entry.rb'
require_relative 'transformative/event.rb'

require_relative 'transformative/actions/create.rb'
require_relative 'transformative/actions/delete.rb'
require_relative 'transformative/actions/undelete.rb'
require_relative 'transformative/actions/update.rb'

require_relative 'transformative/indieauth.rb'
require_relative 'transformative/micropub.rb'
require_relative 'transformative/server.rb'
