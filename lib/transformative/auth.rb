module Transformative
  module Auth
    module_function

    def verify_token_and_scope(token, scope)
      token_data = get_cached_token(token)
      unless token_data
        response = get_token_response(token, ENV['TOKEN_ENDPOINT'])
        unless response.code.to_i == 200
          raise ForbiddenError.new
        end
        token_data = CGI.parse(response.parsed_response)
        set_cached_token(token, token_data)
      end

      if token_data.key?('scope') && token_data['scope'].is_a?(Array)
        scopes = token_data['scope'][0].split(' ')
        return if scopes.include?(scope)
        # if we want to post and are allowed to create then go ahead
        return if scope == 'post' && scopes.include?('create')
      end
      raise InsufficientScope.new
    end

    def get_token_response(token, token_endpoint)
      HTTParty.get(
        token_endpoint,
        headers: {
          'Accept' => 'application/x-www-form-urlencoded',
          'Authorization' => "Bearer #{token}"
        })
    end

    def verify_github_signature(body, header_signature)
      signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'),
        ENV['GITHUB_SECRET'], body)
      unless Rack::Utils.secure_compare(signature, header_signature)
        raise ForbiddenError.new("GitHub webhook signatures did not match.")
      end
    end

    def set_cached_token(token, token_data)
      Redis.set(token, token_data)
      Redis.expire(token, 3600) # expire after one hour
    end

    def get_cached_token(token)
      Redis.get(token)
    end

    class NoTokenError < TransformativeError
      def initialize(message="Micropub endpoint did not return an access token.")
        super("unauthorized", message, 401)
      end
    end

    class InsufficientScope < TransformativeError
      def initialize(message="The user does not have sufficient scope to perform this action.")
        super("insufficient_scope", message, 401)
      end
    end

    class ForbiddenError < TransformativeError
      def initialize(message="The authenticated user does not have permission" +
          " to perform this request.")
        super("forbidden", message, 403)
      end
    end

  end
end