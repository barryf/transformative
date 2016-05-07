module Transformative
  module Indieauth
    module_function
    
    def verify_token?(token, token_endpoint=nil)
      # GET https://tokens.indieauth.com/token
      # Content-type: application/x-www-form-urlencoded
      # Authorization: Bearer xxxxxxxx
      token_endpoint ||= 'https://tokens.indieauth.com/token'
      response = HTTParty.get(token_endpoint,
        headers: { 
          'Content-Type' => 'application/x-www-form-urlencoded', 
          'Authorization' => "Bearer #{token}" 
      })

      # convert form data to hash
      response_hash = CGI::parse(response.parsed_response)
      logger.info "Token response: #{response_hash.inspect}"

      # is me actually authorised?
      return unless response_hash.key?('me') && !response_hash['me'].empty?
      # TODO: AUTH_URLS
      ENV['AUTH_URLS'].include?(response_hash['me'].first)
    end

  end

  class NoTokenError < ResponseError
    def initialize(message="Micropub endpoint did not return an access token.")
      super("no_token", message, 401)
    end
  end

  class ForbiddenError < ResponseError
    def initialize(message="The authenticated user does not have permission to perform this request.")
      super("forbidden", message, 403)
    end
  end

end