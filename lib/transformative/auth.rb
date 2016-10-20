module Transformative
  module Auth
    module_function

    def verify_token_and_scope(token, scope)
      response = get_token_response(token, ENV['TOKEN_ENDPOINT'])
      unless response.code.to_i == 200
        raise ForbiddenError.new
      end

      response_hash = CGI.parse(response.parsed_response)
      puts "scope=#{scope} response_hash=#{response_hash}"
      if response_hash.key?('scope') && response_hash['scope'].is_a?(Array)
        scopes = response_hash['scope'][0].split(' ')
        return if scopes.include?(scope)
        # special case? TODO: find out what to do here
        return if scope == 'create' && scopes.include?('post')
      end
      raise InsufficientScope.new
    end

    def get_token_response(token, token_endpoint)
      HTTParty.get(
        token_endpoint,
        headers: {
          'Content-Type' => 'application/x-www-form-urlencoded',
          'Authorization' => "Bearer #{token}"
        })
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