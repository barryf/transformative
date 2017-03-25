module Transformative
  module Micropub
    module_function

    def create(params)
      if params.key?('h')
        safe_properties = sanitise_properties(params)
        # TODO support other types?
        post = Entry.new_from_form(safe_properties)
        services = params.key?('mp-syndicate-to') ?
          Array(params['mp-syndicate-to']) : []
      else
        check_if_syndicated(params['properties'])
        safe_properties = sanitise_properties(params['properties'])
        klass = Post.class_from_type(params['type'][0])
        post = klass.new(safe_properties)
        services = params['properties'].key?('mp-syndicate-to') ?
          params['properties']['mp-syndicate-to'] : []
      end

      post.set_slug(params)
      post.syndicate(services) if services.any?
      Store.save(post)
    end

    def action(properties)
      post = Store.get_url(properties['url'])

      case properties['action'].to_sym
      when :update
        if properties.key?('replace')
          verify_hash(properties, 'replace')
          post.replace(properties['replace'])
        end
        if properties.key?('add')
          verify_hash(properties, 'add')
          post.add(properties['add'])
        end
        if properties.key?('delete')
          verify_array_or_hash(properties, 'delete')
          post.remove(properties['delete'])
        end
      when :delete
        post.delete
      when :undelete
        post.undelete
      end

      if properties.key?('mp-syndicate-to') && properties['mp-syndicate-to'].any?
        post.syndicate(properties['mp-syndicate-to'])
      end
      post.set_updated
      Store.save(post)
    end

    def verify_hash(properties, key)
      unless properties[key].is_a?(Hash)
        raise InvalidRequestError.new(
          "Invalid request: the '#{key}' property should be a hash.")
      end
    end

    def verify_array_or_hash(properties, key)
      unless properties[key].is_a?(Array) || properties[key].is_a?(Hash)
        raise InvalidRequestError.new(
          "Invalid request: the '#{key}' property should be an array or hash.")
      end
    end

    # has this post already been syndicated, perhaps via a pesos method?
    def check_if_syndicated(properties)
      if properties.key?('syndication') &&
          Cache.find_via_syndication(properties['syndication']).any?
        raise ConflictError.new
      end
    end

    def sanitise_properties(properties)
      Hash[
        properties.map { |k, v|
          unless k.start_with?('mp-') || k == 'access_token' || k == 'h' ||
              k == 'syndicate-to'
            [k, v]
          end
        }.compact
      ]
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

    class ConflictError < TransformativeError
      def initialize(
          message="The post has already been created and syndicated.")
        super("conflict", message, 409)
      end
    end

  end
end

