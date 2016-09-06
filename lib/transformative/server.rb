module Transformative
  class Server < Sinatra::Application
    helpers Sinatra::LinkHeader

    configure do
      root = "#{File.dirname(__FILE__)}/../../"
      set :views, "#{root}views"
      set :config_path, "#{root}config/"
      set :server, :puma
    end

    before do
      @root_url = ENV['ROOT_URL'] || ""
      link "#{@root_url}/micropub", rel: "micropub"
    end

    get '/' do
      erb :index
    end

    post '/micropub' do
      begin
        # start by assuming this is a non-create action
        if params.has_key?('mp-action') && !params['mp-action'].empty?
          raise Micropub::InvalidRequestError.new unless valid_action?
          raise Micropub::InvalidRequestError.new unless valid_url?
          status_code = Micropub.action(params)
        else
          # if it's not an update/delete/undelete then hopefully it's a create
          post = Micropub::Create.create(params)
          status_code = 201
        end
        headers 'Location' => post.permalink if status_code == 201
        status status_code
      rescue ResponseError => error
        halt_error(error)
      end
    end

    get '/micropub' do
      if params.has_key?('q')
        headers 'Content-Type' => 'application/json'
        case params[:q]
        when 'source'
          render_source
        when 'config'
          render_config
        when 'syndicate-to'
          render_syndication_targets
        else
          # TODO query method not supported
        end
      else
        'Micropub endpoint'
      end
    end

    private

    def require_auth
      return unless settings.production?
      token = request.env['HTTP_AUTHORIZATION'] || params['access_token']
      token.gsub!('Bearer ','')
      raise Indieauth::NoTokenError.new if token.nil? || token.empty?
      raise Indieauth::ForbiddenError.new unless Indieauth.verify_token?(token)
    end

    def valid_action?
      %w( update delete undelete ).include?(params['mp-action'])
    end

    def valid_url?
      params.has_key?('url') && !params[:url].empty? && Post.exists_by_url?(params[:url])
    end

    def halt_unless_auth
      begin
        Indieauth.require_auth
      rescue ResponseError => error
        halt_error(error)
      end
    end

    def halt_error(error)
      json = {
        'error' => error.type,
        'error_description' => error.message
      }.to_json
      halt(error.status_code, {'Content-Type' => 'application/json'}, json)
    end

    def syndication_targets
      @syndication_targets ||=
        JSON.parse(File.read("#{settings.config_path}syndication_targets.json"))
    end

    def render_syndication_targets
      { "syndicate-to" => syndication_targets }.to_json
    end

    def render_config
      {
        # "media-endpoint" => media_endpoint, # TODO media endpoint
        "syndicate-to" => syndication_targets
      }.to_json
    end

    def render_source
      raise Micropub::InvalidRequestError.new unless valid_url?
      properties = Micropub.source(params)
      body = { "properties" => properties }
      body['type'] = "h-entry" unless params.has_key?('properties')
      body.to_json
    end

  end
end
