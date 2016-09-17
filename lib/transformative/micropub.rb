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
      post.set(params[:properties])
      post.set_timestamp(:create)
      Store.save(post)
      post
    end

    def action(params)
      post = Post.find_by_url(params[:url])
      case params['action'].to_sym
      when :update
        if params.key?('replace') && !params[:replace].empty?
          post.replace(params[:replace])
        end
        if params.key?('add') && !params[:add].empty?
          post.add(params[:add])
        end
        if params.key?('delete') && !params[:delete].empty?
          post.remove(params[:delete])
        end
      when :delete
        post.delete
      when :undelete
        post.undelete
      else
        # TODO: raise something
      end
      post.set_timestamp(params['action'].to_sym)
      Store.save(post)
      post
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

