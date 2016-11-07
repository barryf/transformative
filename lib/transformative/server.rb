module Transformative
  class Server < Sinatra::Application
    helpers Sinatra::LinkHeader
    helpers ViewHelper

    configure do
      root_path = "#{File.dirname(__FILE__)}/../../"
      set :config_path, "#{root_path}config/"
      set :markdown, layout_engine: :erb
      set :server, :puma
    end

    get '/' do
      @posts_rows = Cache.stream(%w( note article photo repost ),
        params[:page] || 1)
      link 'https://indieauth.com/auth', rel: 'authorization_endpoint'
      link 'https://tokens.indieauth.com/token', rel: 'token_endpoint'
      link "#{ENV['SITE_URL']}micropub", rel: 'micropub'
      link ENV['SITE_URL'], rel: 'feed'
      link ENV['PUBSUBHUBBUB_HUB'], rel: 'hub'
      link ENV['SITE_URL'], rel: 'self'
      index_page
    end

    get '/all' do
      @posts_rows = Cache.stream_all(params[:page] || 1)
      @title = "All"
      index_page
    end

    get %r{^/tags?/([A-Za-z0-9\-\+]+)/?$} do |tags|
      tags.downcase!
      @title = "Tagged  ##{tags.split('+').join(' #')}"
      @page_title = @title
      @posts_rows = Cache.stream_tagged(tags, params[:page] || 1)
      index_page
    end

    get %r{^/(note|article|bookmark|photo|repost|like|replie)s/?$} do |type|
      @title = "#{type}s".capitalize
      type = 'reply' if type == 'replie'
      @posts_rows = Cache.stream([type], params[:page] || 1)
      index_page
    end

    get %r{^/([0-9]{4})/([0-9]{2})/?$} do |y, m|
      @posts_rows = Cache.stream_all_by_month(y, m)
      @title = "#{Date::MONTHNAMES[m.to_i]} #{y}"
      @page_title = @title
      index_page
    end

    get %r{^/([0-9]{4})/([0-9]{2})/([a-z0-9-]+)/?$} do |y, m, slug|
      url = "/#{y}/#{m}/#{slug}"
      @post = Cache.get(url)
      return not_found if @post.nil?
      return deleted if @post.is_deleted?
      @title = page_title(@post)
      @webmentions = Cache.webmentions(@post)
      @contexts = Cache.contexts(@post)
      @authors = Cache.authors_from_cites(@webmentions, @contexts)
      @authors.merge!(Cache.authors_from_categories(@post))
      @post_page = true
      link "#{ENV['SITE_URL']}webmention", rel: 'webmention'
      if @post.h_type == 'h-entry'
        erb :entry
      else
        erb :event
      end
    end

    get %r{^/([0-9]{4})/([0-9]{2})/([a-z0-9-]+)\.json$} do |y, m, slug|
      url = "/#{y}/#{m}/#{slug}"
      content_type :json, charset: 'utf-8'
      Cache.get_json(url)
    end

    get %r{(index|posts|rss)(\.xml)?$} do
      posts_rows = Cache.stream(%w( note article bookmark photo ), 1)
      @posts = posts_rows.map { |row| Cache.row_to_post(row) }
      content_type :xml
      builder :rss
    end

    get '/archives/?' do
      posts = Cache.stream_all(1, 99999).map { |row| Cache.row_to_post(row) }
      year = 0
      month = 0
      months_content = ""
      @content = "<dl id=\"archives\">"
      posts.each do |post|
        published = Time.parse(post.properties['published'][0])
        if published.strftime('%Y') != year
          year = published.strftime('%Y')
          @content += "#{months_content}\n<dt>#{year}</dt>\n"
          months_content = ""
        end
        if published.strftime('%m') != month
          month = published.strftime('%m')
          mon = Date::MONTHNAMES[month.to_i][0...3]
          months_content = "<dd><a href=\"/#{year}/#{month}\">#{mon}</a></dd>\n" +
            months_content
        end
      end
      @content += "#{months_content}\n</dl>"
      @title = "Archives"
      erb :static
    end

    # legacy redirects from old sites (baker)
    get %r{^/posts/([0-9]+)/?$} do |baker_id|
      post = Cache.get_first_by_slug("baker-#{baker_id}")
      if post.nil?
        not_found
      else
        redirect post.url, 301
      end
    end
    get %r{^/([0-9]{1,3})/?$} do |baker_id|
      post = Cache.get_first_by_slug("baker-#{baker_id}")
      if post.nil?
        not_found
      else
        redirect post.url, 301
      end
    end
    get %r{^/articles/([a-z0-9-]+)/?$} do |slug|
      post = Cache.get_first_by_slug(slug)
      not_found if post.nil?
      redirect post.url, 301
    end
    get '/feed' do
      redirect '/rss', 301
    end
    get '/posts' do
      redirect '/', 301
    end
    get '/about' do
      redirect '/2015/01/about', 301
    end
    get '/colophon' do
      redirect '/2015/01/colophon', 301
    end
    get '/contact' do
      redirect '/2015/01/contact', 301
    end

    post '/webhook' do
      puts "Webhook params=#{params}"
      return not_found unless params.key?('commits')
      commits = params[:commits]

      request.body.rewind
      Auth.verify_github_signature(request.body.read,
        request.env['HTTP_X_HUB_SIGNATURE'])

      Store.webhook(commits)
      status 204
    end

    post '/micropub' do
      puts "Micropub params=#{params}"
      # start by assuming this is a non-create action
      if params.key?('action')
        verify_action
        require_auth
        verify_url
        post = Micropub.action(params)
        syndicate(post)
        status 204
      elsif params.key?('file')
        # assume this a file (photo) upload
        require_auth
        url = Media.save(params[:file])
        headers 'Location' => url
        status 201
      else
        # assume this is a create
        require_auth
        verify_create
        post = Micropub.create(params)
        syndicate(post)
        headers 'Location' => post.absolute_url
        status 202
      end
    end

    get '/micropub' do
      if params.key?('q')
        require_auth
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
      puts "Webmention params=#{params}"
      Webmention.receive(params[:source], params[:target])
      headers 'Location' => params[:target]
      status 202
    end

    not_found do
      status 404
      erb :'404'
    end

    error TransformativeError do
      e = env['sinatra.error']
      json = {
        error: e.type,
        error_description: e.message
      }.to_json
      halt(e.status, { 'Content-Type' => 'application/json' }, json)
    end

    error do
      erb :'500', layout: false
    end

    def deleted
      status 410
      erb :'410'
    end

    private

    def index_page
      return not_found if @posts_rows.nil?
      @posts = @posts_rows.map { |row| Cache.row_to_post(row) }
      @contexts = Cache.contexts(@posts)
      @authors = Cache.authors_from_cites(@contexts)
      @authors.merge!(Cache.authors_from_categories(@posts))
      @webmention_counts = Cache.webmention_counts(@posts)
      @footer = true
      erb :index
    end

    def require_auth
      return unless settings.production?
      token = request.env['HTTP_AUTHORIZATION'] || params['access_token'] || ""
      token.sub!(/^Bearer /,'')
      if token.empty?
        raise Auth::NoTokenError.new
      end
      scope = params.key('action') ? params['action'] : 'post'
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
        "media-endpoint" => "#{ENV['SITE_URL']}micropub",
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
        { 'type' => [post.h_type], 'properties' => properties }
      else
        post.data
      end
      data.to_json
    end

    def syndicate(post)
      services = if params.key?('mp-syndicate-to')
          params['mp-syndicate-to']
        elsif params.key?('syndicate-to')
          params['syndicate-to']
        end
      post.syndicate(services) unless services.nil?
    end

  end
end
