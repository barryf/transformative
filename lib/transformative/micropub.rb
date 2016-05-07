module Transformative
  module Micropub

    module_function
      
    def action(params)
      post = Post.find_by_url(params[:url])
      post.category = ["one","two"]
      post.content = "Old content"
      case params['mp-action']
      when 'update'
        if params.has_key?('replace') && !params[:replace].empty?
          post = Update.replace(post, params[:replace])
          # TODO return 201 if url has changed
        end
        if params.has_key?('add') && !params[:add].empty?
          post = Update.add(post, params[:add])
        end
        if params.has_key?('delete') && !params[:delete].empty?
          post = Update.remove(post, params[:delete])
        end
        puts "New post = #{post.inspect}"
        return 204
        post.save!
      when 'delete'
        Delete.delete(post)
        return 204
      when 'undelete'
        Undelete.undelete(post)
        return 204
      else
        # TODO: raise something
      end
    end

    class ForbiddenError < ResponseError
      def initialize(message="The authenticated user does not have permission to perform this request.")
        super("forbidden", message, 403)
      end
    end

    class InsufficientScopeError < ResponseError
      def initialize(message="The scope of this token does not meet the requirements for this request.")
        super("insufficient_scope", message, 401)
      end
    end

    class InvalidRequestError < ResponseError
      def initialize(message="The request is missing a required parameter, or there was a problem with a value of one of the parameters.")
        super("invalid_request", message, 400)
      end
    end

    class NotFoundError < ResponseError
      def initialize(message="The post with the requested URL was not found.")
        super("not_found", message, 400)
      end
    end

  end
end

require_relative 'micropub/create.rb'
require_relative 'micropub/delete.rb'
require_relative 'micropub/undelete.rb'
require_relative 'micropub/update.rb'
