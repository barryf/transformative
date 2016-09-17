module Transformative
  module Auth
    module_function

    def valid_token?(token, token_endpoint=ENV['TOKEN_ENDPOINT'])
      response = HTTParty.get(
        token_endpoint,
        headers: {
          'Content-Type' => 'application/x-www-form-urlencoded',
          'Authorization' => "Bearer #{token}"
        })
      response.status == 200
    end

  end

  class NoTokenError < RequestError
    def initialize(message="Micropub endpoint did not return an access token.")
      super("no_token", message, 401)
    end
  end

  class ForbiddenError < RequestError
    def initialize(message="The authenticated user does not have permission" +
        " to perform this request.")
      super("forbidden", message, 403)
    end
  end

end