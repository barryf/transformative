module Transformative
  module Micropub
    module Create
      module_function
      
      def create(params)
        if params.has_key?('h') && params[:h] == 'entry'
          # form-encoded create
          create_from_form(params)
        elsif params.has_key?('type') && params['type'].first == 'h-entry'
          # json format create
          create_from_json(params)
        else
          raise InvalidRequestError.new
        end
      end

      def create_from_form(params)
        puts "create_from_form"
        post = Post.new
      
        # optional content
        if params.has_key?('content') && !params[:content].empty?
          post.content = params[:content]
        end

        # set published time in utc
        if params.has_key?('published') && !params[:published].empty?
          post.published = Time.parse(params[:published].to_s).utc
        end
      
        post
      end

      def create_from_json(params)
        puts "create_from_json"
        post = Post.new
        
        post
      end
    
    end
  end
end