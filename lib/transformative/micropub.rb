module Transformative
  module Micropub
    module_function

    def create(params)
      safe_params = sanitise_params(params)
      post = if params.key?('h')
        # TODO support other types?
        Entry.new_from_form(params, safe_params)
      else
        klass = Post.class_from_type(params['type'][0])
        klass.new(safe_params['properties'])
      end

      Store.save(post)
    end

    def action(properties)
      post = Store.get_url(properties['url'])

      case properties['action'].to_sym
      when :update
        if properties.key?('replace')
          verify_array(properties, 'replace')
          post.replace(properties['replace'])
        end
        if properties.key?('add')
          verify_array(properties, 'add')
          post.add(properties['add'])
        end
        if properties.key?('delete')
          verify_array(properties, 'delete')
          post.remove(properties['delete'])
        end
      when :delete
        post.delete
      when :undelete
        post.undelete
      end

      post.set_updated
      Store.save(post)
    end

    def verify_array(properties, key)
      unless properties[key].is_a?(Array)
        raise InvalidRequestError.new("Invalid request: the '#{key}' property should be an array.")
      end
    end

    # TODO rewrite this wrapped in a Hash[]
    def sanitise_params(params)
      safe_params = {}
      params.keys.each do |param|
        unless param.start_with?('mp-') || param == 'access_token' ||
            param == 'h' || param == 'syndicate-to'
          safe_params[param] = params[param]
        end
      end
      safe_params
    end

    class ForbiddenError < TransformativeError
      def initialize(message="The authenticated user does not have permission to perform this request.")
        super("forbidden", message, 403)
      end
    end

    class InsufficientScopeError < TransformativeError
      def initialize(message="The scope of this token does not meet the requirements for this request.")
        super("insufficient_scope", message, 401)
      end
    end

    class InvalidRequestError < TransformativeError
      def initialize(message="The request is missing a required parameter, or there was a problem with a value of one of the parameters.")
        super("invalid_request", message, 400)
      end
    end

    class NotFoundError < TransformativeError
      def initialize(message="The post with the requested URL was not found.")
        super("not_found", message, 400)
      end
    end

  end
end

