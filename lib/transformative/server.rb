module Transformative
  class Server < Sinatra::Application

    configure do
      root_path = "#{File.dirname(__FILE__)}/../../"
      set :config_path, "#{root_path}config/"
      set :site_url, ENV['SITE_URL']
      set :media_url, ENV['MEDIA_URL']
      set :media_endpoint, ENV['MEDIA_ENDPOINT']
      set :server, :puma
      disable :show_exceptions
    end

    get '/' do
      'Transformative'
    end

    post '/micropub' do
      puts "MICROPUB PARAMS #{params}"
      # start by assuming this is a non-create action
      if params.key?('action')
        verify_action
        require_auth
        verify_url
        post = Micropub.action(params)
        syndicate(post)
        status 204
      elsif params.key?('file')
        require_auth
        # assume this a file (photo) upload
        filename = Media.store(params[:file])
        headers 'Location' => URI.join(settings.media_url, filename)
        status 201
      else
        require_auth
        # assume this is a create
        verify_create
        post = Micropub.create(params)
        syndicate(post)
        headers 'Location' => post.absolute_url
        status 202
      end
    end

    get '/micropub' do
      require_auth
      if params.key?('q')
        content_type :json
        case params[:q]
        when 'source'
          verify_url
          render_source
        when 'config'
          render_config
        when 'syndicate-to'
          render_syndication_targets
        else
          # Silently fail if query method is not supported
        end
      else
        'Micropub endpoint'
      end
    end

    get '/webmention' do
      "Webmention endpoint"
    end

    post '/webmention' do
      Webmention.receive(params[:source], params[:target])
      headers 'Location' => params[:target]
      status 202
    end

    private

    def require_auth
      return unless settings.production?
      token = request.env['HTTP_AUTHORIZATION'] || params['access_token'] || ""
      token.sub!(/^Bearer /,'')
      if token.empty?
        raise Auth::NoTokenError.new
      end
      scope = params.key('action') ? params['action'] : 'create'
      Auth.verify_token_and_scope(token, scope)
    end

    def verify_create
      if params.key?('h') && Post.valid_types.include?("h-#{params[:h]}")
        return
      elsif params.key?('type') && Post.valid_types.include?(params[:type][0])
        return
      else
        raise Micropub::InvalidRequestError.new(
          "You must specify a Microformats 'h-' type to create a new post. " +
          "Valid post types are: #{Post.valid_types.join(' ')}."
        )
      end
    end

    def verify_action
      valid_actions = %w( create update delete undelete )
      unless valid_actions.include?(params[:action])
        raise Micropub::InvalidRequestError.new(
          "The specified action ('#{params[:action]}') is not supported. " +
          "Valid actions are: #{valid_actions.join(' ')}."
        )
      end
    end

    def verify_url
      unless params.key?('url') && !params[:url].empty? &&
          Store.exists_url?(params[:url])
        raise Micropub::InvalidRequestError.new(
          "The specified URL ('#{params[:url]}') could not be found."
        )
      end
    end

    def syndication_targets
      @syndication_targets ||=
        JSON.parse(File.read("#{settings.config_path}syndication_targets.json"))
    end

    def render_syndication_targets
      content_type :json
      { "syndicate-to" => syndication_targets }.to_json
    end

    def render_config
      content_type :json
      {
        "media-endpoint" => settings.media_endpoint,
        "syndicate-to" => syndication_targets
      }.to_json
    end

    def render_source
      content_type :json
      relative_url = Utils.relative_url(params[:url])
      not_found unless post = Store.get("#{relative_url}.json")
      data = if params.key?('properties')
        properties = {}
        params[:properties].each do |property|
          if post.properties.key?(property)
            properties[property] = post.properties[property]
          end
        end
        { 'type' => [post.type], 'properties' => properties }
      else
        post.data
      end
      puts "render_source=#{data}"
      data.to_json
    end

    def syndicate(post)
      if params.key?('mp-syndicate-to') && !params['mp-syndicate-to'].empty?
        post.syndicate(params['mp-syndicate-to'])
      end
    end

    error TransformativeError do
      e = env['sinatra.error']
      json = {
        error: e.type,
        error_description: e.message
      }.to_json
      halt(e.status, { 'Content-Type' => 'application/json' }, json)
    end

  end
end
