module Transformative
  module Micropub
    module_function

    def create(params)
      type = params[:h] || params[:type]
      raise InvalidRequestError.new if type.nil?
      case type
      when 'event', ['h-event']
        post = Event.new
      when 'card', ['h-card']
        post = Card.new
      when 'cite', ['h-cite']
        post = Cite.new
      else
        post = Entry.new
      end
      set!(post, params[:properties])
      post.set_timestamps
      Store.save(post)
      post
    end

    def action(params)
      post = Post.find_by_url(params[:url])
      case params['action']
      when 'update'
        if params.key?('replace') && !params[:replace].empty?
          replace!(post, params[:replace])
        end
        if params.key?('add') && !params[:add].empty?
          add!(post, params[:add])
        end
        if params.key?('delete') && !params[:delete].empty?
          remove!(post, params[:delete])
        end
        post.set_timestamps
        Store.save(post)
      when 'delete'
        post.delete
      when 'undelete'
        post.undelete
      else
        # TODO: raise something
      end
    end

    def set!(post, properties)
      properties.each do |property|
        post.set_property(property[0], property[1])
      end
    end

    def replace!(post, properties)
      properties.each do |property|
        post.replace_property(property[0], property[1])
      end
    end

    def add!(post, properties)
      properties.each do |property|
        post.add_property(property[0], property[1])
      end
    end

    def remove!(post, properties)
      properties.each do |property|
        post.remove_property(property[0], property[1])
      end
    end

    def source(params)
      post = Post.find_by_url(params[:url])
      if params.key?('properties') && params[:properties].is_a?(Array)
        { properties: post.to_mf2(params[:properties]) }
      else
        {
          type: post.mf2_object,
          properties: post.to_mf2
        }
      end
    end

    class ForbiddenError < RequestError
      def initialize(message="The authenticated user does not have permission to perform this request.")
        super("forbidden", message, 403)
      end
    end

    class InsufficientScopeError < RequestError
      def initialize(message="The scope of this token does not meet the requirements for this request.")
        super("insufficient_scope", message, 401)
      end
    end

    class InvalidRequestError < RequestError
      def initialize(message="The request is missing a required parameter, or there was a problem with a value of one of the parameters.")
        super("invalid_request", message, 400)
      end
    end

    class NotFoundError < RequestError
      def initialize(message="The post with the requested URL was not found.")
        super("not_found", message, 400)
      end
    end

  end
end

